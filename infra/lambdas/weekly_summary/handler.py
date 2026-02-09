"""Weekly summary sender — EventBridge trigger (Monday 9AM UTC).

Sends a digest notification to users who have opted in,
summarizing their active warranties and upcoming expirations.
"""

import json
import os
import logging
import time
from datetime import datetime, timedelta, timezone
from decimal import Decimal

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


def _get_digest_users():
    """Scan for users who have weeklyDigestEnabled=true in their settings."""
    user_ids = []
    params = {
        "FilterExpression": (
            Attr("SK").eq("META#SETTINGS") & Attr("weeklyDigestEnabled").eq(True)
        ),
        "ProjectionExpression": "PK",
    }
    while True:
        resp = table.scan(**params)
        for item in resp.get("Items", []):
            user_ids.append(extract_user_id(item["PK"]))
        if "LastEvaluatedKey" not in resp:
            break
        params["ExclusiveStartKey"] = resp["LastEvaluatedKey"]
    return user_ids


def _get_active_warranties(user_id):
    """Query GSI-4 for all active warranties for a user."""
    items = []
    params = {
        "IndexName": "ByWarrantyExpiry",
        "KeyConditionExpression": Key("GSI4PK").eq(f"USER#{user_id}#ACTIVE"),
    }
    while True:
        resp = table.query(**params)
        items.extend(resp.get("Items", []))
        if "LastEvaluatedKey" not in resp:
            break
        params["ExclusiveStartKey"] = resp["LastEvaluatedKey"]
    return items


def _compute_stats(warranties, now):
    """Compute summary statistics from a list of warranty items."""
    seven_days = (now + timedelta(days=7)).strftime("%Y-%m-%d")
    thirty_days = (now + timedelta(days=30)).strftime("%Y-%m-%d")
    today_str = now.strftime("%Y-%m-%d")

    expiring_this_week = 0
    expiring_this_month = 0
    total_active = len(warranties)
    total_warranty_value = Decimal("0")
    soonest_item = None
    soonest_days = None

    for item in warranties:
        expiry_str = item.get("warrantyExpiryDate", "")
        if not expiry_str:
            continue

        amount = item.get("totalAmount", Decimal("0"))
        if isinstance(amount, (int, float)):
            amount = Decimal(str(amount))
        total_warranty_value += amount

        if expiry_str <= seven_days and expiry_str >= today_str:
            expiring_this_week += 1

        if expiry_str <= thirty_days and expiry_str >= today_str:
            expiring_this_month += 1

        try:
            expiry_date = datetime.strptime(expiry_str, "%Y-%m-%d").replace(
                tzinfo=timezone.utc
            )
            days_left = (expiry_date - now).days
            if days_left >= 0 and (soonest_days is None or days_left < soonest_days):
                soonest_days = days_left
                soonest_item = {
                    "receiptId": item.get("SK", "").removeprefix("RECEIPT#"),
                    "merchantName": item.get("merchantName", "Unknown"),
                    "warrantyExpiryDate": expiry_str,
                    "daysRemaining": days_left,
                }
        except ValueError:
            continue

    return {
        "expiringThisWeek": expiring_this_week,
        "expiringThisMonth": expiring_this_month,
        "totalActive": total_active,
        "totalWarrantyValue": str(total_warranty_value),
        "soonestExpiring": soonest_item,
    }


def _send_summary(user_id, stats):
    """Publish a weekly summary notification via SNS."""
    message = {
        "userId": user_id,
        "notificationType": "WEEKLY_SUMMARY",
        "stats": stats,
    }
    sns_client.publish(
        TopicArn=SNS_TOPIC_ARN,
        Message=json.dumps(message, default=str),
        MessageAttributes={
            "userId": {"DataType": "String", "StringValue": user_id},
            "notificationType": {"DataType": "String", "StringValue": "WEEKLY_SUMMARY"},
        },
    )


def handler(event, context):
    """EventBridge scheduled handler — send weekly digest to opted-in users."""
    try:
        now = datetime.now(timezone.utc)
        now_iso = now.isoformat()
        users_processed = 0
        summaries_sent = 0

        user_ids = _get_digest_users()

        logger.info(json.dumps({
            "action": "weekly_summary_start",
            "eligibleUsers": len(user_ids),
            "timestamp": now_iso,
        }))

        for user_id in user_ids:
            users_processed += 1
            warranties = _get_active_warranties(user_id)
            stats = _compute_stats(warranties, now)
            _send_summary(user_id, stats)
            summaries_sent += 1

            logger.info(json.dumps({
                "action": "weekly_summary_sent",
                "userId": user_id,
                "totalActive": stats["totalActive"],
                "expiringThisWeek": stats["expiringThisWeek"],
            }))

        logger.info(json.dumps({
            "action": "weekly_summary_complete",
            "usersProcessed": users_processed,
            "summariesSent": summaries_sent,
            "timestamp": now_iso,
        }))

        return {
            "statusCode": 200,
            "body": json.dumps({
                "usersProcessed": users_processed,
                "summariesSent": summaries_sent,
            }),
        }

    except Exception as e:
        logger.error(json.dumps({
            "action": "weekly_summary_error",
            "error": str(e),
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }))
        raise
