import json
import os
import logging

import boto3
from PIL import Image

logger = logging.getLogger()
logger.setLevel(logging.INFO)

S3_BUCKET = os.environ.get("S3_BUCKET", "")
THUMBNAIL_WIDTH = int(os.environ.get("THUMBNAIL_WIDTH", "200"))
THUMBNAIL_HEIGHT = int(os.environ.get("THUMBNAIL_HEIGHT", "300"))
THUMBNAIL_QUALITY = int(os.environ.get("THUMBNAIL_QUALITY", "70"))

s3_client = boto3.client("s3")


def handler(event, context):
    """S3 event trigger — generates a thumbnail for each uploaded image."""
    for record in event.get("Records", []):
        try:
            bucket = record["s3"]["bucket"]["name"]
            key = record["s3"]["object"]["key"]

            # Skip if this is already a thumbnail
            if "/thumbnail/" in key:
                logger.info(json.dumps({"action": "skip_thumbnail", "key": key}))
                continue

            logger.info(json.dumps({
                "action": "thumbnail_generate_start",
                "bucket": bucket,
                "key": key,
            }))

            # Download original image to /tmp
            local_input = f"/tmp/{os.path.basename(key)}"
            s3_client.download_file(bucket, key, local_input)

            # Open and create thumbnail with center crop
            img = Image.open(local_input)
            thumbnail = _center_crop_resize(img, THUMBNAIL_WIDTH, THUMBNAIL_HEIGHT)

            # Save thumbnail as JPEG
            local_output = f"/tmp/thumb_{os.path.basename(key)}"
            # Ensure RGB mode for JPEG (in case of RGBA PNG)
            if thumbnail.mode in ("RGBA", "P"):
                thumbnail = thumbnail.convert("RGB")
            thumbnail.save(local_output, "JPEG", quality=THUMBNAIL_QUALITY)

            # Construct thumbnail key: replace 'original/' with 'thumbnail/'
            thumbnail_key = key.replace("/original/", "/thumbnail/", 1)
            if thumbnail_key == key:
                # Fallback: prepend thumbnail/ path segment
                parts = key.rsplit("/", 1)
                thumbnail_key = f"{parts[0]}/thumbnail/{parts[1]}" if len(parts) > 1 else f"thumbnail/{key}"

            # Ensure .jpg extension
            if not thumbnail_key.lower().endswith((".jpg", ".jpeg")):
                thumbnail_key = os.path.splitext(thumbnail_key)[0] + ".jpg"

            # Upload thumbnail to S3
            s3_client.upload_file(
                local_output,
                bucket,
                thumbnail_key,
                ExtraArgs={"ContentType": "image/jpeg"},
            )

            logger.info(json.dumps({
                "action": "thumbnail_generate_complete",
                "original_key": key,
                "thumbnail_key": thumbnail_key,
                "width": THUMBNAIL_WIDTH,
                "height": THUMBNAIL_HEIGHT,
            }))

            # Clean up /tmp
            _safe_remove(local_input)
            _safe_remove(local_output)

        except Exception:
            logger.exception(f"Failed to generate thumbnail for record: {json.dumps(record)}")


def _center_crop_resize(img, target_width, target_height):
    """Resize image with center crop to maintain aspect ratio."""
    img_width, img_height = img.size
    target_ratio = target_width / target_height
    img_ratio = img_width / img_height

    if img_ratio > target_ratio:
        # Image is wider — crop sides
        new_width = int(img_height * target_ratio)
        left = (img_width - new_width) // 2
        img = img.crop((left, 0, left + new_width, img_height))
    elif img_ratio < target_ratio:
        # Image is taller — crop top/bottom
        new_height = int(img_width / target_ratio)
        top = (img_height - new_height) // 2
        img = img.crop((0, top, img_width, top + new_height))

    return img.resize((target_width, target_height), Image.LANCZOS)


def _safe_remove(path):
    """Remove a file, ignoring errors."""
    try:
        os.remove(path)
    except OSError:
        pass
