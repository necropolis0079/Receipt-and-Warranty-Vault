"""Warranty expiry checker — EventBridge scheduled trigger.

Scans all users, checks for warranties approaching expiry,
and sends SNS notifications at configured reminder windows.
"""

import json
import os
import logging
import time
from datetime import datetime, timedelta, timezone

import boto3
from boto3.dynamodb.conditions import Key, Attr

from shared.response import success, error
from shared.dynamodb import build_pk, build_settings_sk, extract_user_id
from shared.errors import NotFoundError, ValidationError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

TABLE_NAME = os.environ["TABLE_NAME"]
REGION = os.environ.get("REGION", "eu-west-1")
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]

dynamodb = boto3.resource("dynamodb", region_name=REGION)
table = dynamodb.Table(TABLE_NAME)
sns_client = boto3.client("sns", region_name=REGION)

DEFAULT_REMINDER_WINDOWS = [30, 7, 1, 0]


def _get_distinct_user_ids():
    """Scan the table for all distinct USER# partition keys."""
    user_ids = set()
    params = {
        "ProjectionExpression": "PK",
        "FilterExpression": Attr("PK").begins_with("USER#"),
    }
    while True:
        resp = table.scan(**params)
        for item in resp.get("Items", []):
            user_ids.add(extract_user_id(item["PK"]))
        if "LastEvaluatedKey" not in resp:
            break
        params["ExclusiveStartKey"] = resp["LastEvaluatedKey"]
    return user_ids


def _get_user_settings(user_id):
    """Fetch user settings, return reminder windows config."""
    resp = table.get_item(
        Key={"PK": build_pk(user_id), "SK": build_settings_sk()},
    )
    item = resp.get("Item", {})
    windows = item.get("reminderWindows", DEFAULT_REMINDER_WINDOWS)
    return [int(w) for w in windows]


def _query_active_warranties(user_id, max_expiry_date):
    """Query GSI-4 for active warranties expiring before max_expiry_date."""
    items = []
    params = {
        "IndexName": "ByWarrantyExpiry",
        "KeyConditionExpression": (
            Key("GSI4PK").eq(f"USER#{user_id}#ACTIVE")
            & Key("warrantyExpiryDate").lte(max_expiry_date)
        ),
    }
    while True:
        resp = table.query(**params)
        items.extend(resp.get("Items", []))
        if "LastEvaluatedKey" not in resp:
            break
        params["ExclusiveStartKey"] = resp["LastEvaluatedKey"]
    return items


def _send_notification(user_id, receipt_id, merchant_name, expiry_date, days_remaining):
    """Publish an SNS notification for an expiring warranty."""
    message = {
        "userId": user_id,
        "receiptId": receipt_id,
        "merchantName": merchant_name,
        "warrantyExpiryDate": expiry_date,
        "daysRemaining": days_remaining,
    }
    sns_client.publish(
        TopicArn=SNS_TOPIC_ARN,
        Message=json.dumps(message),
        MessageAttributes={
            "userId": {"DataType": "String", "StringValue": user_id},
            "notificationType": {"DataType": "String", "StringValue": "WARRANTY_EXPIRY"},
        },
    )


def _update_last_notified(pk, sk, timestamp):
    """Mark the receipt as notified at this expiry threshold."""
    table.update_item(
        Key={"PK": pk, "SK": sk},
        UpdateExpression="SET lastNotifiedExpiry = :ts",
        ExpressionAttributeValues={":ts": timestamp},
    )


def handler(event, context):
    """EventBridge scheduled handler — check all warranties for expiry."""
    try:
        now = datetime.now(timezone.utc)
        now_iso = now.isoformat()
        notifications_sent = 0
        users_scanned = 0

        user_ids = _get_distinct_user_ids()
        users_scanned = len(user_ids)

        logger.info(json.dumps({
            "action": "warranty_check_start",
            "usersFound": users_scanned,
            "timestamp": now_iso,
        }))

        for user_id in user_ids:
            reminder_windows = _get_user_settings(user_id)
            if not reminder_windows:
                continue

            max_window = max(reminder_windows)
            max_expiry = (now + timedelta(days=max_window)).strftime("%Y-%m-%d")

            warranties = _query_active_warranties(user_id, max_expiry)

            for item in warranties:
                expiry_str = item.get("warrantyExpiryDate", "")
                if not expiry_str:
                    continue

                try:
                    expiry_date = datetime.strptime(expiry_str, "%Y-%m-%d").replace(
                        tzinfo=timezone.utc
                    )
                except ValueError:
                    continue

                days_remaining = (expiry_date - now).days
                last_notified = item.get("lastNotifiedExpiry", "")

                for window in sorted(reminder_windows, reverse=True):
                    if days_remaining <= window:
                        threshold_key = f"{window}d"
                        if last_notified and last_notified >= now_iso[:10]:
                            break

                        receipt_id = item.get("SK", "").removeprefix("RECEIPT#")
                        merchant = item.get("merchantName", "Unknown")

                        _send_notification(
                            user_id, receipt_id, merchant, expiry_str, days_remaining
                        )
                        _update_last_notified(item["PK"], item["SK"], now_iso)
                        notifications_sent += 1
                        break

        logger.info(json.dumps({
            "action": "warranty_check_complete",
            "usersScanned": users_scanned,
            "notificationsSent": notifications_sent,
            "timestamp": now_iso,
        }))

        return {
            "statusCode": 200,
            "body": json.dumps({
                "usersScanned": users_scanned,
                "notificationsSent": notifications_sent,
            }),
        }

    except Exception as e:
        logger.error(json.dumps({
            "action": "warranty_check_error",
            "error": str(e),
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }))
        raise
