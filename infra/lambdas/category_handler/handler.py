"""Category management — API Gateway GET/PUT /categories.

Manages user custom categories alongside system defaults.
Uses optimistic locking via version field for conflict resolution.
"""

import json
import os
import logging
import time

import boto3
from boto3.dynamodb.conditions import Attr

from shared.response import success, error
from shared.auth import get_user_id
from shared.dynamodb import build_pk, build_categories_sk
from shared.errors import NotFoundError, ConflictError, ValidationError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

TABLE_NAME = os.environ["TABLE_NAME"]
REGION = os.environ.get("REGION", "eu-west-1")

dynamodb = boto3.resource("dynamodb", region_name=REGION)
table = dynamodb.Table(TABLE_NAME)

DEFAULT_CATEGORIES = [
    "Electronics",
    "Groceries",
    "Clothing",
    "Home & Garden",
    "Automotive",
    "Health & Beauty",
    "Office",
    "Sports & Outdoors",
    "Toys & Kids",
    "Dining",
]

MAX_CATEGORIES = 50
MAX_CATEGORY_LENGTH = 50
MIN_CATEGORY_LENGTH = 1


def _get_categories(user_id):
    """Fetch user categories from DynamoDB."""
    resp = table.get_item(
        Key={"PK": build_pk(user_id), "SK": build_categories_sk()},
    )
    return resp.get("Item")


def _validate_categories(categories):
    """Validate the categories list."""
    if not isinstance(categories, list):
        raise ValidationError("Categories must be a list")

    if len(categories) > MAX_CATEGORIES:
        raise ValidationError(f"Maximum {MAX_CATEGORIES} categories allowed")

    seen = set()
    for cat in categories:
        if not isinstance(cat, str):
            raise ValidationError("Each category must be a string")

        if len(cat) < MIN_CATEGORY_LENGTH or len(cat) > MAX_CATEGORY_LENGTH:
            raise ValidationError(
                f"Category length must be between {MIN_CATEGORY_LENGTH} and {MAX_CATEGORY_LENGTH} characters"
            )

        lower = cat.lower()
        if lower in seen:
            raise ValidationError(f"Duplicate category: {cat}")
        seen.add(lower)


def _put_categories(user_id, categories, expected_version):
    """Write categories with optimistic locking via version check."""
    pk = build_pk(user_id)
    sk = build_categories_sk()
    new_version = (expected_version or 0) + 1

    try:
        if expected_version:
            table.put_item(
                Item={
                    "PK": pk,
                    "SK": sk,
                    "categories": categories,
                    "version": new_version,
                    "updatedAt": int(time.time()),
                },
                ConditionExpression=(
                    Attr("version").eq(expected_version)
                ),
            )
        else:
            table.put_item(
                Item={
                    "PK": pk,
                    "SK": sk,
                    "categories": categories,
                    "version": new_version,
                    "updatedAt": int(time.time()),
                },
                ConditionExpression=(
                    Attr("version").not_exists()
                ),
            )
    except dynamodb.meta.client.exceptions.ConditionalCheckFailedException:
        raise ConflictError("Category version conflict — reload and retry")

    return new_version


def _handle_get(event):
    """Handle GET /categories."""
    user_id = get_user_id(event)
    item = _get_categories(user_id)

    custom_categories = item.get("categories", []) if item else []
    version = item.get("version", 0) if item else 0

    return success({
        "defaults": DEFAULT_CATEGORIES,
        "custom": custom_categories,
        "version": version,
    })


def _handle_put(event):
    """Handle PUT /categories."""
    user_id = get_user_id(event)

    body = json.loads(event.get("body") or "{}")
    categories = body.get("categories")
    expected_version = body.get("version")

    if categories is None:
        raise ValidationError("Missing 'categories' field in request body")

    _validate_categories(categories)

    new_version = _put_categories(user_id, categories, expected_version)

    logger.info(json.dumps({
        "action": "categories_updated",
        "userId": user_id,
        "categoryCount": len(categories),
        "version": new_version,
    }))

    return success({
        "defaults": DEFAULT_CATEGORIES,
        "custom": categories,
        "version": new_version,
    })


def handler(event, context):
    """API Gateway handler — GET or PUT /categories."""
    try:
        method = event.get("httpMethod", "GET")

        if method == "GET":
            return _handle_get(event)
        elif method == "PUT":
            return _handle_put(event)
        else:
            return error(f"Unsupported method: {method}", status_code=405, code="METHOD_NOT_ALLOWED")

    except ValueError as e:
        return error(str(e), status_code=401, code="UNAUTHORIZED")
    except ValidationError as e:
        return error(e.message, status_code=400, code=e.code)
    except ConflictError as e:
        return error(e.message, status_code=409, code=e.code)
    except Exception as e:
        logger.error(json.dumps({
            "action": "category_handler_error",
            "error": str(e),
            "timestamp": time.time(),
        }))
        return error("Internal server error", status_code=500, code="INTERNAL_ERROR")
