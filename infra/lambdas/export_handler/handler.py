"""User data export — API Gateway POST /user/export.

Gathers all user receipts and images, creates a ZIP archive,
uploads to the export bucket, and returns a presigned download URL.
"""

import json
import os
import logging
import time
import zipfile
import tempfile
from datetime import datetime, timezone

import boto3
from boto3.dynamodb.conditions import Key

from shared.response import success, error
from shared.auth import get_user_id
from shared.dynamodb import build_pk, extract_receipt_id
from shared.errors import NotFoundError, ValidationError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

TABLE_NAME = os.environ["TABLE_NAME"]
REGION = os.environ.get("REGION", "eu-west-1")
S3_BUCKET = os.environ["S3_BUCKET"]
EXPORT_BUCKET = os.environ["EXPORT_BUCKET"]
EXPORT_TTL_DAYS = int(os.environ.get("EXPORT_TTL_DAYS", "7"))
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN", "")

dynamodb = boto3.resource("dynamodb", region_name=REGION)
table = dynamodb.Table(TABLE_NAME)
s3_client = boto3.client("s3", region_name=REGION)
sns_client = boto3.client("sns", region_name=REGION)

PRESIGNED_URL_EXPIRY = 86400  # 24 hours


def _query_user_receipts(user_id, date_from=None, date_to=None):
    """Query all receipts for a user, optionally filtered by date range."""
    pk = build_pk(user_id)
    items = []

    if date_from or date_to:
        # Use GSI-1 (ByUserDate) for date-range queries
        params = {
            "IndexName": "ByUserDate",
            "KeyConditionExpression": Key("GSI1PK").eq(f"USER#{user_id}"),
        }
        if date_from and date_to:
            params["KeyConditionExpression"] &= Key("GSI1SK").between(
                date_from, date_to
            )
        elif date_from:
            params["KeyConditionExpression"] &= Key("GSI1SK").gte(date_from)
        elif date_to:
            params["KeyConditionExpression"] &= Key("GSI1SK").lte(date_to)
    else:
        params = {
            "KeyConditionExpression": (
                Key("PK").eq(pk) & Key("SK").begins_with("RECEIPT#")
            ),
        }

    while True:
        resp = table.query(**params)
        items.extend(resp.get("Items", []))
        if "LastEvaluatedKey" not in resp:
            break
        params["ExclusiveStartKey"] = resp["LastEvaluatedKey"]

    return items


def _list_receipt_images(user_id, receipt_id):
    """List all original images for a receipt in S3."""
    prefix = f"users/{user_id}/receipts/{receipt_id}/original/"
    keys = []
    paginator = s3_client.get_paginator("list_objects_v2")
    for page in paginator.paginate(Bucket=S3_BUCKET, Prefix=prefix):
        for obj in page.get("Contents", []):
            keys.append(obj["Key"])
    return keys


def _download_s3_object(key):
    """Download an S3 object and return its bytes."""
    resp = s3_client.get_object(Bucket=S3_BUCKET, Key=key)
    return resp["Body"].read()


def _serialize_receipt(item):
    """Convert a DynamoDB item to JSON-serializable dict."""
    serialized = {}
    for k, v in item.items():
        if hasattr(v, "as_integer_ratio"):
            serialized[k] = str(v)
        else:
            serialized[k] = v
    return serialized


def handler(event, context):
    """API Gateway handler — export user data as a downloadable ZIP."""
    try:
        user_id = get_user_id(event)

        # Parse optional date filters
        body = json.loads(event.get("body") or "{}")
        date_from = body.get("dateFrom")
        date_to = body.get("dateTo")

        logger.info(json.dumps({
            "action": "export_start",
            "userId": user_id,
            "dateFrom": date_from,
            "dateTo": date_to,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }))

        # Query all user receipts
        receipts = _query_user_receipts(user_id, date_from, date_to)

        if not receipts:
            return success({"message": "No receipts found for export", "receiptCount": 0})

        # Create ZIP in /tmp
        timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
        zip_filename = f"export_{timestamp}.zip"
        zip_path = os.path.join(tempfile.gettempdir(), zip_filename)

        serialized_receipts = []
        with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
            for receipt in receipts:
                serialized = _serialize_receipt(receipt)
                serialized_receipts.append(serialized)
                receipt_id = extract_receipt_id(receipt.get("SK", ""))

                # Add individual receipt JSON
                receipt_json = json.dumps(serialized, indent=2, default=str)
                zf.writestr(f"receipts/{receipt_id}.json", receipt_json)

                # Download and add original images
                image_keys = _list_receipt_images(user_id, receipt_id)
                for key in image_keys:
                    image_name = key.split("/")[-1]
                    image_data = _download_s3_object(key)
                    zf.writestr(f"receipts/{receipt_id}/images/{image_name}", image_data)

            # Add combined receipts.json
            all_receipts_json = json.dumps(serialized_receipts, indent=2, default=str)
            zf.writestr("receipts.json", all_receipts_json)

        # Upload ZIP to export bucket
        export_key = f"exports/{user_id}/{timestamp}.zip"
        s3_client.upload_file(
            zip_path,
            EXPORT_BUCKET,
            export_key,
            ExtraArgs={"ContentType": "application/zip"},
        )

        # Clean up /tmp
        os.remove(zip_path)

        # Generate presigned download URL (24-hour expiry)
        download_url = s3_client.generate_presigned_url(
            "get_object",
            Params={"Bucket": EXPORT_BUCKET, "Key": export_key},
            ExpiresIn=PRESIGNED_URL_EXPIRY,
        )

        expires_at = datetime.now(timezone.utc).isoformat()

        # TODO: Send SNS notification with download URL
        # sns_client.publish(...)

        logger.info(json.dumps({
            "action": "export_complete",
            "userId": user_id,
            "receiptCount": len(receipts),
            "exportKey": export_key,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }))

        return success({
            "downloadUrl": download_url,
            "expiresAt": expires_at,
            "receiptCount": len(receipts),
        })

    except ValueError as e:
        return error(str(e), status_code=401, code="UNAUTHORIZED")
    except ValidationError as e:
        return error(e.message, status_code=400, code=e.code)
    except Exception as e:
        logger.error(json.dumps({
            "action": "export_error",
            "error": str(e),
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }))
        return error("Export failed", status_code=500, code="INTERNAL_ERROR")
