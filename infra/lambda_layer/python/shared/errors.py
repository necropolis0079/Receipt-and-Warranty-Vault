"""Custom exceptions for Receipt Vault Lambda functions."""


class NotFoundError(Exception):
    """Raised when a requested resource does not exist."""

    def __init__(self, message="Resource not found"):
        self.message = message
        super().__init__(self.message)

    @property
    def code(self):
        return "NOT_FOUND"


class ForbiddenError(Exception):
    """Raised when access to a resource is denied."""

    def __init__(self, message="Access denied"):
        self.message = message
        super().__init__(self.message)

    @property
    def code(self):
        return "FORBIDDEN"


class ConflictError(Exception):
    """Raised when a version conflict is detected."""

    def __init__(self, message="Version conflict"):
        self.message = message
        super().__init__(self.message)

    @property
    def code(self):
        return "CONFLICT"


class ValidationError(Exception):
    """Raised when input validation fails."""

    def __init__(self, message="Validation failed"):
        self.message = message
        super().__init__(self.message)

    @property
    def code(self):
        return "VALIDATION_ERROR"
