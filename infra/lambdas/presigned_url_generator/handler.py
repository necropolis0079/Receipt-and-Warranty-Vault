import json
import os
import logging

import boto3
from botocore.config import Config
from shared.response import success, error
from shared.auth import get_user_id
from shared.dynamodb import build_pk, build_receipt_sk
from shared.errors import NotFoundError, ValidationError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

S3_BUCKET = os.environ.get("S3_BUCKET", "")
REGION = os.environ.get("REGION", "eu-west-1")
KMS_KEY_ID = os.environ.get("KMS_KEY_ID", "")
URL_EXPIRY_SECONDS = int(os.environ.get("URL_EXPIRY_SECONDS", "600"))  # 10 minutes
MAX_FILE_SIZE = int(os.environ.get("MAX_FILE_SIZE", "10485760"))  # 10 MB

dynamodb = boto3.resource("dynamodb", region_name=REGION)
table = dynamodb.Table(os.environ.get("TABLE_NAME", "ReceiptVault"))

# S3 client with signature version for KMS
s3_client = boto3.client(
    "s3",
    region_name=REGION,
    config=Config(signature_version="s3v4"),
)

ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png"}


def handler(event, context):
    """Main entry point — dispatches presigned URL operations."""
    try:
        user_id = get_user_id(event)
        http_method = event.get("httpMethod", "")
        resource = event.get("resource", "")
        path_params = event.get("pathParameters") or {}
        receipt_id = path_params.get("receiptId")

        logger.info(json.dumps({
            "action": "presigned_url_route",
            "method": http_method,
            "resource": resource,
            "user_id": user_id,
        }))

        if not receipt_id:
            raise ValidationError("receiptId is required")

        if resource == "/receipts/{receiptId}/images/upload-url" and http_method == "POST":
            return generate_upload_url(event, user_id, receipt_id)

        if resource == "/receipts/{receiptId}/images/{imageKey}/download-url" and http_method == "GET":
            return generate_download_url(event, user_id, receipt_id)

        return error("Route not found", status_code=404, code="NOT_FOUND")

    except ValidationError as exc:
        logger.warning(json.dumps({"error": "validation", "message": str(exc)}))
        return error(str(exc), status_code=400, code="VALIDATION_ERROR")
    except NotFoundError as exc:
        logger.warning(json.dumps({"error": "not_found", "message": str(exc)}))
        return error(str(exc), status_code=404, code="NOT_FOUND")
    except Exception:
        logger.exception("Unhandled error in presigned_url_generator")
        return error("Internal server error", status_code=500, code="INTERNAL_ERROR")


def generate_upload_url(event, user_id, receipt_id):
    """POST /receipts/{receiptId}/images/upload-url — presigned PUT URL."""
    # Validate receipt belongs to user
    _get_receipt_or_raise(user_id, receipt_id)

    body = json.loads(event.get("body") or "{}")
    content_type = body.get("contentType", "")
    file_name = body.get("fileName", "")

    if not content_type:
        raise ValidationError("contentType is required")
    if not file_name:
        raise ValidationError("fileName is required")
    if content_type not in ALLOWED_CONTENT_TYPES:
        raise ValidationError(
            f"Invalid contentType. Allowed: {', '.join(sorted(ALLOWED_CONTENT_TYPES))}"
        )

    # Construct S3 key
    s3_key = f"users/{user_id}/receipts/{receipt_id}/original/{file_name}"

    # Generate presigned PUT URL
    presigned_url = s3_client.generate_presigned_url(
        "put_object",
        Params={
            "Bucket": S3_BUCKET,
            "Key": s3_key,
            "ContentType": content_type,
            "ServerSideEncryption": "aws:kms",
            "SSEKMSKeyId": KMS_KEY_ID,
        },
        ExpiresIn=URL_EXPIRY_SECONDS,
    )

    logger.info(json.dumps({
        "action": "generate_upload_url",
        "receipt_id": receipt_id,
        "s3_key": s3_key,
        "content_type": content_type,
    }))

    return success({
        "uploadUrl": presigned_url,
        "s3Key": s3_key,
        "expiresIn": URL_EXPIRY_SECONDS,
        "maxFileSize": MAX_FILE_SIZE,
    })


def generate_download_url(event, user_id, receipt_id):
    """GET /receipts/{receiptId}/images/{imageKey}/download-url — presigned GET URL."""
    # Validate receipt belongs to user
    _get_receipt_or_raise(user_id, receipt_id)

    path_params = event.get("pathParameters") or {}
    image_key = path_params.get("imageKey", "")

    if not image_key:
        raise ValidationError("imageKey is required")

    # The imageKey from the path may be URL-encoded; it represents the S3 key
    # Reconstruct full S3 key if needed
    if not image_key.startswith("users/"):
        s3_key = f"users/{user_id}/receipts/{receipt_id}/original/{image_key}"
    else:
        s3_key = image_key

    # Verify the key belongs to this user
    if not s3_key.startswith(f"users/{user_id}/"):
        raise ValidationError("Access denied to this image")

    presigned_url = s3_client.generate_presigned_url(
        "get_object",
        Params={
            "Bucket": S3_BUCKET,
            "Key": s3_key,
        },
        ExpiresIn=URL_EXPIRY_SECONDS,
    )

    logger.info(json.dumps({
        "action": "generate_download_url",
        "receipt_id": receipt_id,
        "s3_key": s3_key,
    }))

    return success({
        "downloadUrl": presigned_url,
        "expiresIn": URL_EXPIRY_SECONDS,
    })


def _get_receipt_or_raise(user_id, receipt_id):
    """Fetch a receipt or raise NotFoundError."""
    response = table.get_item(
        Key={"PK": build_pk(user_id), "SK": build_receipt_sk(receipt_id)},
    )
    item = response.get("Item")
    if not item:
        raise NotFoundError(f"Receipt {receipt_id} not found")
    return item
