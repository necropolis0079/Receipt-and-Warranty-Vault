"""GDPR user account deletion — API Gateway DELETE /user/account.

Cascade delete: Cognito -> DynamoDB -> S3 -> Audit log.
No PII in logs — user ID is SHA-256 hashed for audit trail.
"""

import json
import os
import logging
import time
import hashlib
from datetime import datetime, timezone

import boto3

from shared.response import success, error, no_content
from shared.auth import get_user_id
from shared.dynamodb import build_pk
from shared.errors import NotFoundError, ForbiddenError, ValidationError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

TABLE_NAME = os.environ["TABLE_NAME"]
REGION = os.environ.get("REGION", "eu-west-1")
S3_BUCKET = os.environ["S3_BUCKET"]
USER_POOL_ID = os.environ["USER_POOL_ID"]

dynamodb = boto3.resource("dynamodb", region_name=REGION)
table = dynamodb.Table(TABLE_NAME)
dynamodb_client = boto3.client("dynamodb", region_name=REGION)
s3_client = boto3.client("s3", region_name=REGION)
cognito_client = boto3.client("cognito-idp", region_name=REGION)


def _hash_user_id(user_id):
    """SHA-256 hash a user ID for audit logging (no PII in logs)."""
    return hashlib.sha256(user_id.encode("utf-8")).hexdigest()


def _delete_cognito_user(user_id):
    """Delete the Cognito user — invalidates all tokens immediately."""
    cognito_client.admin_delete_user(
        UserPoolId=USER_POOL_ID,
        Username=user_id,
    )


def _delete_dynamodb_items(user_id):
    """Delete all DynamoDB items for a user using batch writes of 25."""
    pk = build_pk(user_id)
    deleted_count = 0

    params = {
        "KeyConditionExpression": boto3.dynamodb.conditions.Key("PK").eq(pk),
        "ProjectionExpression": "PK, SK",
    }

    items_to_delete = []
    while True:
        resp = table.query(**params)
        items_to_delete.extend(resp.get("Items", []))
        if "LastEvaluatedKey" not in resp:
            break
        params["ExclusiveStartKey"] = resp["LastEvaluatedKey"]

    # BatchWriteItem in chunks of 25
    for i in range(0, len(items_to_delete), 25):
        batch = items_to_delete[i : i + 25]
        request_items = {
            TABLE_NAME: [
                {"DeleteRequest": {"Key": {"PK": item["PK"], "SK": item["SK"]}}}
                for item in batch
            ]
        }
        resp = dynamodb_client.batch_write_item(
            RequestItems={
                TABLE_NAME: [
                    {
                        "DeleteRequest": {
                            "Key": {
                                "PK": {"S": item["PK"]},
                                "SK": {"S": item["SK"]},
                            }
                        }
                    }
                    for item in batch
                ]
            }
        )
        deleted_count += len(batch)

        # Handle unprocessed items
        unprocessed = resp.get("UnprocessedItems", {}).get(TABLE_NAME, [])
        while unprocessed:
            time.sleep(0.5)
            resp = dynamodb_client.batch_write_item(
                RequestItems={TABLE_NAME: unprocessed}
            )
            unprocessed = resp.get("UnprocessedItems", {}).get(TABLE_NAME, [])

    return deleted_count


def _delete_s3_objects(user_id):
    """Delete all S3 objects and versions under users/{userId}/."""
    prefix = f"users/{user_id}/"
    deleted_count = 0

    # Delete all object versions (versioned bucket)
    paginator = s3_client.get_paginator("list_object_versions")
    for page in paginator.paginate(Bucket=S3_BUCKET, Prefix=prefix):
        objects_to_delete = []

        for version in page.get("Versions", []):
            objects_to_delete.append({
                "Key": version["Key"],
                "VersionId": version["VersionId"],
            })

        for marker in page.get("DeleteMarkers", []):
            objects_to_delete.append({
                "Key": marker["Key"],
                "VersionId": marker["VersionId"],
            })

        # DeleteObjects in batches of 1000
        for i in range(0, len(objects_to_delete), 1000):
            batch = objects_to_delete[i : i + 1000]
            s3_client.delete_objects(
                Bucket=S3_BUCKET,
                Delete={"Objects": batch, "Quiet": True},
            )
            deleted_count += len(batch)

    return deleted_count


def handler(event, context):
    """API Gateway handler — GDPR cascade delete of user account."""
    try:
        user_id = get_user_id(event)
        hashed_id = _hash_user_id(user_id)

        # Parse and validate confirmation
        body = json.loads(event.get("body") or "{}")
        if not body.get("confirmation"):
            raise ValidationError(
                "Account deletion requires 'confirmation' field set to true"
            )

        logger.info(json.dumps({
            "action": "user_deletion_start",
            "hashedUserId": hashed_id,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }))

        # Step 1: Delete Cognito user (MOST CRITICAL — invalidates all tokens)
        _delete_cognito_user(user_id)
        logger.info(json.dumps({
            "action": "cognito_user_deleted",
            "hashedUserId": hashed_id,
        }))

        # Step 2: Delete all DynamoDB items
        dynamo_deleted = _delete_dynamodb_items(user_id)
        logger.info(json.dumps({
            "action": "dynamodb_items_deleted",
            "hashedUserId": hashed_id,
            "itemsDeleted": dynamo_deleted,
        }))

        # Step 3: Delete all S3 objects and versions
        s3_deleted = _delete_s3_objects(user_id)
        logger.info(json.dumps({
            "action": "s3_objects_deleted",
            "hashedUserId": hashed_id,
            "objectsDeleted": s3_deleted,
        }))

        # Step 4: Audit log (no PII)
        logger.info(json.dumps({
            "action": "user_deletion_complete",
            "hashedUserId": hashed_id,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "dynamoItemsDeleted": dynamo_deleted,
            "s3ObjectsDeleted": s3_deleted,
        }))

        return no_content()

    except ValueError as e:
        return error(str(e), status_code=401, code="UNAUTHORIZED")
    except ValidationError as e:
        return error(e.message, status_code=400, code=e.code)
    except cognito_client.exceptions.UserNotFoundException:
        # User already deleted from Cognito — continue cleanup
        logger.info(json.dumps({
            "action": "cognito_user_already_deleted",
            "hashedUserId": _hash_user_id(user_id) if user_id else "unknown",
        }))
        return no_content()
    except Exception as e:
        logger.error(json.dumps({
            "action": "user_deletion_error",
            "error": str(e),
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }))
        return error("Account deletion failed", status_code=500, code="INTERNAL_ERROR")
