import json
import os
import logging
import time
import base64

import boto3
from shared.response import success, error
from shared.auth import get_user_id
from shared.dynamodb import build_pk, build_receipt_sk
from shared.errors import NotFoundError, ValidationError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

TABLE_NAME = os.environ.get("TABLE_NAME", "ReceiptVault")
REGION = os.environ.get("REGION", "eu-west-1")
BEDROCK_MODEL_ID = os.environ.get("BEDROCK_MODEL_ID", "anthropic.claude-haiku-4-5-20251001")
BEDROCK_FALLBACK_MODEL_ID = os.environ.get("BEDROCK_FALLBACK_MODEL_ID", "anthropic.claude-sonnet-4-5-20250929")
S3_BUCKET = os.environ.get("S3_BUCKET", "")
CONFIDENCE_THRESHOLD = float(os.environ.get("CONFIDENCE_THRESHOLD", "0.7"))

dynamodb = boto3.resource("dynamodb", region_name=REGION)
table = dynamodb.Table(TABLE_NAME)
bedrock_client = boto3.client("bedrock-runtime", region_name=REGION)
s3_client = boto3.client("s3", region_name=REGION)

EXTRACTION_PROMPT = """Extract structured receipt data from this receipt image and/or OCR text.
Return a JSON object with exactly these fields:
{
  "merchantName": "store or merchant name",
  "purchaseDate": "YYYY-MM-DD",
  "items": [{"name": "item description", "quantity": 1, "price": 0.00}],
  "totalAmount": 0.00,
  "currency": "EUR",
  "warrantyMonths": null,
  "confidence": 0.0
}

Rules:
- confidence should be 0.0 to 1.0 reflecting your certainty in the extraction
- warrantyMonths should be null if no warranty info is found
- currency should be the ISO 4217 code
- If a field cannot be determined, use null
- Return ONLY the JSON object, no extra text
"""


def handler(event, context):
    """POST /receipts/{receiptId}/refine — LLM-powered OCR refinement."""
    try:
        user_id = get_user_id(event)
        path_params = event.get("pathParameters") or {}
        receipt_id = path_params.get("receiptId")

        if not receipt_id:
            raise ValidationError("receiptId is required")

        logger.info(json.dumps({
            "action": "ocr_refine_start",
            "receipt_id": receipt_id,
            "user_id": user_id,
        }))

        # 1. Validate receipt exists and belongs to user
        receipt = _get_receipt_or_raise(user_id, receipt_id)

        # 2. Build message content for Claude
        body = json.loads(event.get("body") or "{}")
        ocr_text = body.get("ocrText", "")
        image_key = body.get("imageKey", "")

        message_content = []

        # If imageKey provided, download and encode
        if image_key:
            image_data = _download_image(image_key)
            if image_data:
                message_content.append({
                    "type": "image",
                    "source": {
                        "type": "base64",
                        "media_type": _get_media_type(image_key),
                        "data": base64.b64encode(image_data).decode("utf-8"),
                    },
                })

        # Add text prompt
        prompt_text = EXTRACTION_PROMPT
        if ocr_text:
            prompt_text += f"\n\nOCR text from on-device extraction:\n{ocr_text}"

        message_content.append({"type": "text", "text": prompt_text})

        # 3. Call Bedrock with primary model
        extracted = _invoke_bedrock(BEDROCK_MODEL_ID, message_content)

        # 4. If confidence below threshold, retry with fallback model
        if extracted and extracted.get("confidence", 0) < CONFIDENCE_THRESHOLD:
            logger.info(json.dumps({
                "action": "ocr_refine_fallback",
                "primary_confidence": extracted.get("confidence"),
                "threshold": CONFIDENCE_THRESHOLD,
            }))
            fallback_result = _invoke_bedrock(BEDROCK_FALLBACK_MODEL_ID, message_content)
            if fallback_result and fallback_result.get("confidence", 0) > extracted.get("confidence", 0):
                extracted = fallback_result

        if not extracted:
            return error("Could not extract receipt data", status_code=422, code="EXTRACTION_FAILED")

        # 5. Update receipt in DynamoDB with extracted fields
        now_iso = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())

        update_expr_parts = [
            "#updatedAt = :now",
            "#sv = #sv + :one",
            "#llmConfidence = :confidence",
        ]
        expr_names = {
            "#updatedAt": "updatedAt",
            "#sv": "serverVersion",
            "#llmConfidence": "llmConfidence",
        }
        expr_values = {
            ":now": now_iso,
            ":one": 1,
            ":confidence": str(extracted.get("confidence", 0)),
        }

        field_mapping = {
            "merchantName": "extractedMerchantName",
            "purchaseDate": "extractedDate",
            "totalAmount": "extractedTotal",
            "items": "extractedItems",
            "currency": "extractedCurrency",
            "warrantyMonths": "extractedWarrantyMonths",
        }

        for source_field, db_field in field_mapping.items():
            value = extracted.get(source_field)
            if value is not None:
                safe_name = f"#f_{db_field}"
                safe_value = f":v_{db_field}"
                update_expr_parts.append(f"{safe_name} = {safe_value}")
                expr_names[safe_name] = db_field
                expr_values[safe_value] = value if not isinstance(value, float) else str(value)

        table.update_item(
            Key={"PK": build_pk(user_id), "SK": build_receipt_sk(receipt_id)},
            UpdateExpression="SET " + ", ".join(update_expr_parts),
            ExpressionAttributeNames=expr_names,
            ExpressionAttributeValues=expr_values,
        )

        logger.info(json.dumps({
            "action": "ocr_refine_complete",
            "receipt_id": receipt_id,
            "confidence": extracted.get("confidence"),
            "model_used": BEDROCK_MODEL_ID,
        }))

        return success({
            "receiptId": receipt_id,
            "extracted": extracted,
            "confidence": extracted.get("confidence"),
        })

    except ValidationError as exc:
        logger.warning(json.dumps({"error": "validation", "message": str(exc)}))
        return error(str(exc), status_code=400, code="VALIDATION_ERROR")
    except NotFoundError as exc:
        logger.warning(json.dumps({"error": "not_found", "message": str(exc)}))
        return error(str(exc), status_code=404, code="NOT_FOUND")
    except Exception:
        logger.exception("Unhandled error in ocr_refine")
        return error("Internal server error", status_code=500, code="INTERNAL_ERROR")


def _invoke_bedrock(model_id, message_content):
    """Invoke Bedrock Claude model and parse the JSON response."""
    try:
        request_body = json.dumps({
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 1024,
            "messages": [
                {"role": "user", "content": message_content},
            ],
        })

        response = bedrock_client.invoke_model(
            modelId=model_id,
            contentType="application/json",
            accept="application/json",
            body=request_body,
        )

        response_body = json.loads(response["body"].read())
        assistant_text = response_body["content"][0]["text"]

        # Parse the JSON from the response (strip markdown fences if present)
        json_text = assistant_text.strip()
        if json_text.startswith("```"):
            lines = json_text.split("\n")
            json_text = "\n".join(lines[1:-1])

        return json.loads(json_text)

    except Exception:
        logger.exception(f"Bedrock invocation failed for model {model_id}")
        return None


def _download_image(image_key):
    """Download image from S3 and return bytes."""
    try:
        response = s3_client.get_object(Bucket=S3_BUCKET, Key=image_key)
        return response["Body"].read()
    except Exception:
        logger.exception(f"Failed to download image: {image_key}")
        return None


def _get_media_type(image_key):
    """Determine media type from file extension."""
    lower = image_key.lower()
    if lower.endswith(".png"):
        return "image/png"
    if lower.endswith(".webp"):
        return "image/webp"
    return "image/jpeg"


def _get_receipt_or_raise(user_id, receipt_id):
    """Fetch a receipt or raise NotFoundError."""
    response = table.get_item(
        Key={"PK": build_pk(user_id), "SK": build_receipt_sk(receipt_id)},
    )
    item = response.get("Item")
    if not item:
        raise NotFoundError(f"Receipt {receipt_id} not found")
    return item
