"""API Gateway proxy response builders with CORS headers."""

import json

_CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token",
    "Access-Control-Allow-Methods": "GET,POST,PUT,PATCH,DELETE,OPTIONS",
}


def success(body, status_code=200):
    """Return a JSON success response with CORS headers."""
    return {
        "statusCode": status_code,
        "headers": {**_CORS_HEADERS, "Content-Type": "application/json"},
        "body": json.dumps(body),
    }


def error(message, status_code=400, code="BAD_REQUEST"):
    """Return a JSON error response with CORS headers."""
    return {
        "statusCode": status_code,
        "headers": {**_CORS_HEADERS, "Content-Type": "application/json"},
        "body": json.dumps({"error": {"code": code, "message": message}}),
    }


def created(body):
    """Return a 201 Created JSON response with CORS headers."""
    return success(body, status_code=201)


def no_content():
    """Return a 204 No Content response with CORS headers."""
    return {
        "statusCode": 204,
        "headers": _CORS_HEADERS,
        "body": "",
    }
