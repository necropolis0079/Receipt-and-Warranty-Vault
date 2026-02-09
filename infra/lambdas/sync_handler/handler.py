import json
import os
import logging
import time

import boto3
from boto3.dynamodb.conditions import Key
from shared.response import success, error
from shared.auth import get_user_id
from shared.dynamodb import build_pk, build_receipt_sk
from shared.errors import ValidationError, ConflictError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

TABLE_NAME = os.environ.get("TABLE_NAME", "ReceiptVault")
REGION = os.environ.get("REGION", "eu-west-1")
MAX_BATCH_SIZE = int(os.environ.get("MAX_BATCH_SIZE", "25"))

dynamodb = boto3.resource("dynamodb", region_name=REGION)
table = dynamodb.Table(TABLE_NAME)
dynamodb_client = boto3.client("dynamodb", region_name=REGION)

# Field-level merge tiers
TIER_1_SERVER_WINS = {
    "extractedMerchantName", "extractedDate", "extractedTotal",
    "ocrRawText", "llmConfidence",
}
TIER_2_CLIENT_WINS = {
    "userNotes", "userTags", "isFavorite",
}
TIER_3_CONDITIONAL = {
    "displayName", "category", "warrantyMonths",
}


def handler(event, context):
    """Main entry point — dispatches sync operations."""
    try:
        user_id = get_user_id(event)
        http_method = event.get("httpMethod", "")
        resource = event.get("resource", "")

        logger.info(json.dumps({
            "action": "sync_route",
            "method": http_method,
            "resource": resource,
            "user_id": user_id,
        }))

        if resource == "/sync/pull" and http_method == "POST":
            return delta_pull(event, user_id)

        if resource == "/sync/push" and http_method == "POST":
            return batch_push(event, user_id)

        if resource == "/sync/full" and http_method == "POST":
            return full_reconciliation(event, user_id)

        return error("Route not found", status_code=404, code="NOT_FOUND")

    except ValidationError as exc:
        logger.warning(json.dumps({"error": "validation", "message": str(exc)}))
        return error(str(exc), status_code=400, code="VALIDATION_ERROR")
    except ConflictError as exc:
        logger.warning(json.dumps({"error": "conflict", "message": str(exc)}))
        return error(str(exc), status_code=409, code="CONFLICT")
    except Exception:
        logger.exception("Unhandled error in sync_handler")
        return error("Internal server error", status_code=500, code="INTERNAL_ERROR")


def delta_pull(event, user_id):
    """POST /sync/pull — return items updated since lastSyncTimestamp."""
    body = json.loads(event.get("body") or "{}")
    last_sync = body.get("lastSyncTimestamp")

    if not last_sync:
        raise ValidationError("lastSyncTimestamp is required")

    # Query GSI-6 (ByUpdatedAt) for items updated after lastSyncTimestamp
    response = table.query(
        IndexName="ByUpdatedAt",
        KeyConditionExpression=(
            Key("GSI6PK").eq(build_pk(user_id))
            & Key("GSI6SK").gt(last_sync)
        ),
    )

    key_items = response.get("Items", [])

    # GSI-6 is KEYS_ONLY — need to BatchGetItem for full data
    full_items = []
    if key_items:
        keys = [
            {"PK": item["PK"], "SK": item["SK"]}
            for item in key_items
        ]
        # Process in batches of 100 (DynamoDB BatchGetItem limit)
        for i in range(0, len(keys), 100):
            batch_keys = keys[i:i + 100]
            batch_response = dynamodb_client.batch_get_item(
                RequestItems={
                    TABLE_NAME: {
                        "Keys": [
                            {
                                "PK": {"S": k["PK"]},
                                "SK": {"S": k["SK"]},
                            }
                            for k in batch_keys
                        ],
                    },
                },
            )
            # Convert from low-level format
            raw_items = batch_response.get("Responses", {}).get(TABLE_NAME, [])
            for raw in raw_items:
                full_items.append(_deserialize_item(raw))

    now_iso = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())

    logger.info(json.dumps({
        "action": "delta_pull",
        "items_count": len(full_items),
        "since": last_sync,
    }))

    return success({
        "items": full_items,
        "count": len(full_items),
        "newSyncTimestamp": now_iso,
    })


def batch_push(event, user_id):
    """POST /sync/push — apply client changes with field-level merge."""
    body = json.loads(event.get("body") or "{}")
    items = body.get("items", [])

    if not items:
        raise ValidationError("items array is required and must not be empty")

    if len(items) > MAX_BATCH_SIZE:
        raise ValidationError(f"Batch size exceeds maximum of {MAX_BATCH_SIZE}")

    outcomes = []

    for client_item in items:
        receipt_id = client_item.get("receiptId")
        if not receipt_id:
            outcomes.append({
                "receiptId": None,
                "outcome": "rejected",
                "reason": "Missing receiptId",
            })
            continue

        client_version = client_item.get("serverVersion", 0)

        # Fetch current server state
        server_response = table.get_item(
            Key={"PK": build_pk(user_id), "SK": build_receipt_sk(receipt_id)},
        )
        server_item = server_response.get("Item")

        if not server_item:
            # New item from client — accept as-is
            outcome = _accept_new_item(user_id, receipt_id, client_item)
            outcomes.append(outcome)
            continue

        server_version = server_item.get("serverVersion", 0)

        if client_version == server_version:
            # Versions match — apply client changes directly
            outcome = _apply_direct(user_id, receipt_id, client_item, server_version)
            outcomes.append(outcome)
        else:
            # Version mismatch — field-level merge
            outcome = _field_level_merge(
                user_id, receipt_id, client_item, server_item
            )
            outcomes.append(outcome)

    logger.info(json.dumps({
        "action": "batch_push",
        "total": len(items),
        "outcomes": {o["outcome"] for o in outcomes} if outcomes else set(),
    }, default=list))

    return success({"outcomes": outcomes})


def full_reconciliation(event, user_id):
    """POST /sync/full — return all items for user (paginated)."""
    all_items = []
    last_key = None

    while True:
        query_kwargs = {
            "KeyConditionExpression": Key("PK").eq(build_pk(user_id)),
        }
        if last_key:
            query_kwargs["ExclusiveStartKey"] = last_key

        response = table.query(**query_kwargs)
        all_items.extend(response.get("Items", []))

        last_key = response.get("LastEvaluatedKey")
        if not last_key:
            break

    now_iso = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())

    logger.info(json.dumps({
        "action": "full_reconciliation",
        "items_count": len(all_items),
    }))

    return success({
        "items": all_items,
        "count": len(all_items),
        "newSyncTimestamp": now_iso,
    })


# ---------------------------------------------------------------------------
# Merge helpers
# ---------------------------------------------------------------------------

def _accept_new_item(user_id, receipt_id, client_item):
    """Accept a new item from client that doesn't exist on server."""
    now_iso = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())

    item = dict(client_item)
    item["PK"] = build_pk(user_id)
    item["SK"] = build_receipt_sk(receipt_id)
    item["userId"] = user_id
    item["receiptId"] = receipt_id
    item["serverVersion"] = 1
    item["updatedAt"] = now_iso
    item["GSI6PK"] = build_pk(user_id)
    item["GSI6SK"] = now_iso

    # Remove None values
    item = {k: v for k, v in item.items() if v is not None}

    table.put_item(Item=item)

    return {"receiptId": receipt_id, "outcome": "accepted", "serverVersion": 1}


def _apply_direct(user_id, receipt_id, client_item, server_version):
    """Apply client changes directly when versions match."""
    now_iso = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())

    update_fields = {
        k: v for k, v in client_item.items()
        if k not in {"PK", "SK", "receiptId", "userId", "serverVersion"}
        and v is not None
    }

    if not update_fields:
        return {"receiptId": receipt_id, "outcome": "accepted", "serverVersion": server_version}

    expr_parts = ["#updatedAt = :now", "#sv = #sv + :one", "#gsi6sk = :now"]
    expr_names = {
        "#updatedAt": "updatedAt",
        "#sv": "serverVersion",
        "#gsi6sk": "GSI6SK",
    }
    expr_values = {
        ":now": now_iso,
        ":one": 1,
        ":expectedVersion": server_version,
    }

    for field, value in update_fields.items():
        safe_name = f"#f_{field}"
        safe_value = f":v_{field}"
        expr_parts.append(f"{safe_name} = {safe_value}")
        expr_names[safe_name] = field
        expr_values[safe_value] = value

    try:
        table.update_item(
            Key={"PK": build_pk(user_id), "SK": build_receipt_sk(receipt_id)},
            UpdateExpression="SET " + ", ".join(expr_parts),
            ExpressionAttributeNames=expr_names,
            ExpressionAttributeValues=expr_values,
            ConditionExpression="#sv = :expectedVersion",
        )
    except dynamodb.meta.client.exceptions.ConditionalCheckFailedException:
        return {"receiptId": receipt_id, "outcome": "conflict", "serverVersion": server_version}

    return {
        "receiptId": receipt_id,
        "outcome": "accepted",
        "serverVersion": server_version + 1,
    }


def _field_level_merge(user_id, receipt_id, client_item, server_item):
    """Merge client and server using conflict resolution tiers."""
    now_iso = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    user_edited_fields = set(client_item.get("userEditedFields", []))
    merged_fields = {}
    conflicts = []

    all_fields = set(client_item.keys()) | set(server_item.keys())
    skip_fields = {"PK", "SK", "receiptId", "userId", "serverVersion",
                   "createdAt", "updatedAt", "userEditedFields"}

    for field in all_fields:
        if field in skip_fields:
            continue

        client_val = client_item.get(field)
        server_val = server_item.get(field)

        # No conflict if values are the same
        if client_val == server_val:
            continue

        if field in TIER_1_SERVER_WINS:
            # Server (LLM) wins
            merged_fields[field] = server_val
        elif field in TIER_2_CLIENT_WINS:
            # Client (user) wins
            merged_fields[field] = client_val
        elif field in TIER_3_CONDITIONAL:
            # Client wins IF user explicitly edited the field
            if field in user_edited_fields:
                merged_fields[field] = client_val
            else:
                merged_fields[field] = server_val
        else:
            # Unknown field — default to server
            merged_fields[field] = server_val
            if client_val != server_val and client_val is not None:
                conflicts.append({
                    "field": field,
                    "clientValue": client_val,
                    "serverValue": server_val,
                    "resolution": "server_wins_default",
                })

    # Apply merged fields
    if merged_fields:
        expr_parts = ["#updatedAt = :now", "#sv = #sv + :one", "#gsi6sk = :now"]
        expr_names = {
            "#updatedAt": "updatedAt",
            "#sv": "serverVersion",
            "#gsi6sk": "GSI6SK",
        }
        expr_values = {":now": now_iso, ":one": 1}

        for field, value in merged_fields.items():
            if value is not None:
                safe_name = f"#f_{field}"
                safe_value = f":v_{field}"
                expr_parts.append(f"{safe_name} = {safe_value}")
                expr_names[safe_name] = field
                expr_values[safe_value] = value

        table.update_item(
            Key={"PK": build_pk(user_id), "SK": build_receipt_sk(receipt_id)},
            UpdateExpression="SET " + ", ".join(expr_parts),
            ExpressionAttributeNames=expr_names,
            ExpressionAttributeValues=expr_values,
        )

    new_version = server_item.get("serverVersion", 0) + 1

    outcome = "merged" if conflicts else "accepted"
    result = {
        "receiptId": receipt_id,
        "outcome": outcome,
        "serverVersion": new_version,
    }
    if conflicts:
        result["conflicts"] = conflicts

    return result


def _deserialize_item(raw):
    """Convert low-level DynamoDB item format to Python dict."""
    deserializer = boto3.dynamodb.types.TypeDeserializer()
    return {k: deserializer.deserialize(v) for k, v in raw.items()}
