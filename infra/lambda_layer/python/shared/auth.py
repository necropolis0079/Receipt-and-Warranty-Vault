"""Auth helpers for API Gateway Lambda authorizer integration."""


def get_user_id(event):
    """Extract the Cognito user ID (sub) from an API Gateway event.

    Raises ValueError if authentication information is missing.
    """
    try:
        return event["requestContext"]["authorizer"]["claims"]["sub"]
    except (KeyError, TypeError):
        raise ValueError("Missing authentication")
