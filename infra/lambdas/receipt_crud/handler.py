import json
import os
import logging
import time
import uuid

import boto3
from boto3.dynamodb.conditions import Key
from shared.response import success, error, created, no_content
from shared.auth import get_user_id
from shared.dynamodb import (
    build_pk,
    build_receipt_sk,
    build_categories_sk,
    build_settings_sk,
    extract_receipt_id,
    extract_user_id,
)
from shared.errors import NotFoundError, ForbiddenError, ConflictError, ValidationError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

TABLE_NAME = os.environ.get("TABLE_NAME", "ReceiptVault")
REGION = os.environ.get("REGION", "eu-west-1")

dynamodb = boto3.resource("dynamodb", region_name=REGION)
table = dynamodb.Table(TABLE_NAME)


def handler(event, context):
    """Main entry point — dispatches to sub-functions based on HTTP method + resource."""
    try:
        user_id = get_user_id(event)
        http_method = event.get("httpMethod", "")
        resource = event.get("resource", "")
        path_params = event.get("pathParameters") or {}
        receipt_id = path_params.get("receiptId")

        logger.info(json.dumps({
            "action": "route_request",
            "method": http_method,
            "resource": resource,
            "user_id": user_id,
        }))

        # --- Receipt CRUD routes ---
        if resource == "/receipts" and http_method == "POST":
            return create_receipt(event, user_id)

        if resource == "/receipts" and http_method == "GET":
            return list_receipts(event, user_id)

        if resource == "/receipts/{receiptId}" and http_method == "GET":
            return get_receipt(event, user_id, receipt_id)

        if resource == "/receipts/{receiptId}" and http_method == "PUT":
            return update_receipt(event, user_id, receipt_id)

        if resource == "/receipts/{receiptId}" and http_method == "DELETE":
            return delete_receipt(event, user_id, receipt_id)

        if resource == "/receipts/{receiptId}/restore" and http_method == "POST":
            return restore_receipt(event, user_id, receipt_id)

        if resource == "/receipts/{receiptId}/status" and http_method == "PATCH":
            return update_status(event, user_id, receipt_id)

        # --- Warranty routes ---
        if resource == "/warranties/expiring" and http_method == "GET":
            return get_expiring_warranties(event, user_id)

        # --- User profile / settings routes ---
        if resource == "/user/profile" and http_method == "GET":
            return get_user_profile(event, user_id)

        if resource == "/user/profile" and http_method == "PUT":
            return update_user_profile(event, user_id)

        if resource == "/user/settings" and http_method == "GET":
            return get_user_settings(event, user_id)

        if resource == "/user/settings" and http_method == "PUT":
            return update_user_settings(event, user_id)

        return error("Route not found", status_code=404, code="NOT_FOUND")

    except ValidationError as exc:
        logger.warning(json.dumps({"error": "validation", "message": str(exc)}))
        return error(str(exc), status_code=400, code="VALIDATION_ERROR")
    except NotFoundError as exc:
        logger.warning(json.dumps({"error": "not_found", "message": str(exc)}))
        return error(str(exc), status_code=404, code="NOT_FOUND")
    except ForbiddenError as exc:
        logger.warning(json.dumps({"error": "forbidden", "message": str(exc)}))
        return error(str(exc), status_code=403, code="FORBIDDEN")
    except ConflictError as exc:
        logger.warning(json.dumps({"error": "conflict", "message": str(exc)}))
        return error(str(exc), status_code=409, code="CONFLICT")
    except Exception:
        logger.exception("Unhandled error")
        return error("Internal server error", status_code=500, code="INTERNAL_ERROR")


# ---------------------------------------------------------------------------
# Receipt CRUD
# ---------------------------------------------------------------------------

def create_receipt(event, user_id):
    """POST /receipts — create a new receipt."""
    body = json.loads(event.get("body") or "{}")
    receipt_id = str(uuid.uuid4())
    now_iso = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())

    item = {
        "PK": build_pk(user_id),
        "SK": build_receipt_sk(receipt_id),
        "receiptId": receipt_id,
        "userId": user_id,
        "status": "active",
        "createdAt": now_iso,
        "updatedAt": now_iso,
        "serverVersion": 1,
        # Caller-supplied fields
        "displayName": body.get("displayName", ""),
        "merchantName": body.get("merchantName", ""),
        "purchaseDate": body.get("purchaseDate", now_iso[:10]),
        "totalAmount": body.get("totalAmount"),
        "currency": body.get("currency", "EUR"),
        "category": body.get("category", "Uncategorized"),
        "warrantyMonths": body.get("warrantyMonths"),
        "notes": body.get("notes", ""),
        "tags": body.get("tags", []),
        "imageKeys": body.get("imageKeys", []),
        "userEditedFields": body.get("userEditedFields", []),
    }

    # Compute warrantyExpiryDate if warrantyMonths is set
    if item.get("warrantyMonths") and item.get("purchaseDate"):
        # TODO: compute actual expiry from purchaseDate + warrantyMonths
        pass

    # GSI-4: ByWarrantyExpiry (sparse — only if warranty exists)
    if item.get("warrantyExpiryDate"):
        item["GSI4PK"] = f"{build_pk(user_id)}#ACTIVE"

    # GSI attributes
    item["GSI1PK"] = build_pk(user_id)
    item["GSI1SK"] = item["purchaseDate"]
    item["GSI2PK"] = build_pk(user_id)
    item["GSI2SK"] = f"CAT#{item['category']}"
    if item.get("merchantName"):
        item["GSI3PK"] = build_pk(user_id)
        item["GSI3SK"] = f"STORE#{item['merchantName']}"
    item["GSI5PK"] = build_pk(user_id)
    item["GSI5SK"] = f"STATUS#active#{item['purchaseDate']}"
    item["GSI6PK"] = build_pk(user_id)
    item["GSI6SK"] = now_iso

    # Remove None values — DynamoDB does not accept them
    item = {k: v for k, v in item.items() if v is not None}

    table.put_item(
        Item=item,
        ConditionExpression="attribute_not_exists(PK)",
    )

    logger.info(json.dumps({"action": "create_receipt", "receipt_id": receipt_id}))
    return created({"receiptId": receipt_id, "receipt": item})


def list_receipts(event, user_id):
    """GET /receipts — paginated list of user receipts."""
    qs = event.get("queryStringParameters") or {}
    limit = int(qs.get("limit", "25"))
    last_key_raw = qs.get("lastEvaluatedKey")

    query_kwargs = {
        "KeyConditionExpression": Key("PK").eq(build_pk(user_id))
            & Key("SK").begins_with("RECEIPT#"),
        "Limit": limit,
        "ScanIndexForward": False,
    }

    if last_key_raw:
        query_kwargs["ExclusiveStartKey"] = json.loads(last_key_raw)

    response = table.query(**query_kwargs)
    items = response.get("Items", [])
    result = {
        "receipts": items,
        "count": len(items),
    }
    if "LastEvaluatedKey" in response:
        result["lastEvaluatedKey"] = response["LastEvaluatedKey"]

    return success(result)


def get_receipt(event, user_id, receipt_id):
    """GET /receipts/{receiptId}"""
    item = _get_receipt_or_raise(user_id, receipt_id)
    return success(item)


def update_receipt(event, user_id, receipt_id):
    """PUT /receipts/{receiptId} — optimistic concurrency via serverVersion."""
    body = json.loads(event.get("body") or "{}")
    expected_version = body.get("serverVersion")
    if expected_version is None:
        raise ValidationError("serverVersion is required for updates")

    now_iso = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())

    # Build update expression dynamically from allowed fields
    allowed_fields = [
        "displayName", "merchantName", "purchaseDate", "totalAmount",
        "currency", "category", "warrantyMonths", "notes", "tags",
        "imageKeys", "userEditedFields", "warrantyExpiryDate",
    ]
    expr_parts = ["#updatedAt = :updatedAt", "#sv = #sv + :one"]
    expr_names = {
        "#updatedAt": "updatedAt",
        "#sv": "serverVersion",
    }
    expr_values = {
        ":updatedAt": now_iso,
        ":one": 1,
        ":expectedVersion": int(expected_version),
    }

    for field in allowed_fields:
        if field in body:
            safe = f"#f_{field}"
            expr_parts.append(f"{safe} = :v_{field}")
            expr_names[safe] = field
            expr_values[f":v_{field}"] = body[field]

    # Update GSI projections as needed
    if "purchaseDate" in body:
        expr_parts.append("#gsi1sk = :gsi1sk")
        expr_names["#gsi1sk"] = "GSI1SK"
        expr_values[":gsi1sk"] = body["purchaseDate"]
    if "category" in body:
        expr_parts.append("#gsi2sk = :gsi2sk")
        expr_names["#gsi2sk"] = "GSI2SK"
        expr_values[":gsi2sk"] = f"CAT#{body['category']}"

    update_expr = "SET " + ", ".join(expr_parts)

    try:
        result = table.update_item(
            Key={"PK": build_pk(user_id), "SK": build_receipt_sk(receipt_id)},
            UpdateExpression=update_expr,
            ExpressionAttributeNames=expr_names,
            ExpressionAttributeValues=expr_values,
            ConditionExpression="#sv = :expectedVersion",
            ReturnValues="ALL_NEW",
        )
    except dynamodb.meta.client.exceptions.ConditionalCheckFailedException:
        raise ConflictError("Version conflict — receipt was modified by another client")

    logger.info(json.dumps({"action": "update_receipt", "receipt_id": receipt_id}))
    return success(result["Attributes"])


def delete_receipt(event, user_id, receipt_id):
    """DELETE /receipts/{receiptId} — soft delete with 30-day TTL."""
    _get_receipt_or_raise(user_id, receipt_id)

    now_iso = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    ttl_epoch = int(time.time()) + 2592000  # 30 days

    table.update_item(
        Key={"PK": build_pk(user_id), "SK": build_receipt_sk(receipt_id)},
        UpdateExpression=(
            "SET #status = :deleted, #ttl = :ttl, #updatedAt = :now, "
            "#gsi5sk = :gsi5sk, #sv = #sv + :one"
        ),
        ExpressionAttributeNames={
            "#status": "status",
            "#ttl": "ttl",
            "#updatedAt": "updatedAt",
            "#gsi5sk": "GSI5SK",
            "#sv": "serverVersion",
        },
        ExpressionAttributeValues={
            ":deleted": "deleted",
            ":ttl": ttl_epoch,
            ":now": now_iso,
            ":gsi5sk": f"STATUS#deleted#{now_iso[:10]}",
            ":one": 1,
        },
    )

    logger.info(json.dumps({"action": "soft_delete_receipt", "receipt_id": receipt_id}))
    return no_content()


def restore_receipt(event, user_id, receipt_id):
    """POST /receipts/{receiptId}/restore — undo soft delete."""
    item = _get_receipt_or_raise(user_id, receipt_id)
    if item.get("status") != "deleted":
        raise ValidationError("Receipt is not deleted")

    now_iso = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    purchase_date = item.get("purchaseDate", now_iso[:10])

    table.update_item(
        Key={"PK": build_pk(user_id), "SK": build_receipt_sk(receipt_id)},
        UpdateExpression=(
            "SET #status = :active, #updatedAt = :now, "
            "#gsi5sk = :gsi5sk, #sv = #sv + :one "
            "REMOVE #ttl"
        ),
        ExpressionAttributeNames={
            "#status": "status",
            "#ttl": "ttl",
            "#updatedAt": "updatedAt",
            "#gsi5sk": "GSI5SK",
            "#sv": "serverVersion",
        },
        ExpressionAttributeValues={
            ":active": "active",
            ":now": now_iso,
            ":gsi5sk": f"STATUS#active#{purchase_date}",
            ":one": 1,
        },
    )

    logger.info(json.dumps({"action": "restore_receipt", "receipt_id": receipt_id}))
    return success({"receiptId": receipt_id, "status": "active"})


def update_status(event, user_id, receipt_id):
    """PATCH /receipts/{receiptId}/status — e.g. mark as returned."""
    body = json.loads(event.get("body") or "{}")
    new_status = body.get("status")
    if not new_status:
        raise ValidationError("status is required")

    valid_statuses = {"active", "returned", "expired", "archived"}
    if new_status not in valid_statuses:
        raise ValidationError(f"Invalid status. Must be one of: {', '.join(valid_statuses)}")

    _get_receipt_or_raise(user_id, receipt_id)

    now_iso = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())

    table.update_item(
        Key={"PK": build_pk(user_id), "SK": build_receipt_sk(receipt_id)},
        UpdateExpression=(
            "SET #status = :status, #updatedAt = :now, "
            "#gsi5sk = :gsi5sk, #sv = #sv + :one"
        ),
        ExpressionAttributeNames={
            "#status": "status",
            "#updatedAt": "updatedAt",
            "#gsi5sk": "GSI5SK",
            "#sv": "serverVersion",
        },
        ExpressionAttributeValues={
            ":status": new_status,
            ":now": now_iso,
            ":gsi5sk": f"STATUS#{new_status}#{now_iso[:10]}",
            ":one": 1,
        },
    )

    logger.info(json.dumps({"action": "update_status", "receipt_id": receipt_id, "status": new_status}))
    return success({"receiptId": receipt_id, "status": new_status})


# ---------------------------------------------------------------------------
# Warranty queries
# ---------------------------------------------------------------------------

def get_expiring_warranties(event, user_id):
    """GET /warranties/expiring — query GSI-4 for warranties expiring within N days."""
    qs = event.get("queryStringParameters") or {}
    days_ahead = int(qs.get("days", "30"))

    now_date = time.strftime("%Y-%m-%d", time.gmtime())
    future_ts = time.time() + (days_ahead * 86400)
    future_date = time.strftime("%Y-%m-%d", time.gmtime(future_ts))

    response = table.query(
        IndexName="ByWarrantyExpiry",
        KeyConditionExpression=(
            Key("GSI4PK").eq(f"{build_pk(user_id)}#ACTIVE")
            & Key("warrantyExpiryDate").between(now_date, future_date)
        ),
    )

    items = response.get("Items", [])
    logger.info(json.dumps({
        "action": "get_expiring_warranties",
        "count": len(items),
        "days_ahead": days_ahead,
    }))
    return success({"warranties": items, "count": len(items)})


# ---------------------------------------------------------------------------
# User profile / settings
# ---------------------------------------------------------------------------

def get_user_profile(event, user_id):
    """GET /user/profile"""
    response = table.get_item(
        Key={"PK": build_pk(user_id), "SK": "META#PROFILE"},
    )
    item = response.get("Item")
    if not item:
        # Return empty profile shell
        return success({"userId": user_id, "profile": {}})
    return success(item)


def update_user_profile(event, user_id):
    """PUT /user/profile"""
    body = json.loads(event.get("body") or "{}")
    now_iso = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())

    allowed = ["displayName", "preferredCurrency", "locale", "timezone"]
    expr_parts = ["#updatedAt = :now"]
    expr_names = {"#updatedAt": "updatedAt"}
    expr_values = {":now": now_iso}

    for field in allowed:
        if field in body:
            safe = f"#f_{field}"
            expr_parts.append(f"{safe} = :v_{field}")
            expr_names[safe] = field
            expr_values[f":v_{field}"] = body[field]

    table.update_item(
        Key={"PK": build_pk(user_id), "SK": "META#PROFILE"},
        UpdateExpression="SET " + ", ".join(expr_parts),
        ExpressionAttributeNames=expr_names,
        ExpressionAttributeValues=expr_values,
    )

    logger.info(json.dumps({"action": "update_user_profile", "user_id": user_id}))
    return success({"message": "Profile updated"})


def get_user_settings(event, user_id):
    """GET /user/settings"""
    response = table.get_item(
        Key={"PK": build_pk(user_id), "SK": build_settings_sk()},
    )
    item = response.get("Item")
    if not item:
        return success({"userId": user_id, "settings": {}})
    return success(item)


def update_user_settings(event, user_id):
    """PUT /user/settings"""
    body = json.loads(event.get("body") or "{}")
    now_iso = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())

    allowed = [
        "storageMode", "notificationsEnabled", "reminderDaysBefore",
        "autoArchiveDays", "theme", "locale",
    ]
    expr_parts = ["#updatedAt = :now"]
    expr_names = {"#updatedAt": "updatedAt"}
    expr_values = {":now": now_iso}

    for field in allowed:
        if field in body:
            safe = f"#f_{field}"
            expr_parts.append(f"{safe} = :v_{field}")
            expr_names[safe] = field
            expr_values[f":v_{field}"] = body[field]

    table.update_item(
        Key={"PK": build_pk(user_id), "SK": build_settings_sk()},
        UpdateExpression="SET " + ", ".join(expr_parts),
        ExpressionAttributeNames=expr_names,
        ExpressionAttributeValues=expr_values,
    )

    logger.info(json.dumps({"action": "update_user_settings", "user_id": user_id}))
    return success({"message": "Settings updated"})


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _get_receipt_or_raise(user_id, receipt_id):
    """Fetch a receipt or raise NotFoundError."""
    response = table.get_item(
        Key={"PK": build_pk(user_id), "SK": build_receipt_sk(receipt_id)},
    )
    item = response.get("Item")
    if not item:
        raise NotFoundError(f"Receipt {receipt_id} not found")
    return item
