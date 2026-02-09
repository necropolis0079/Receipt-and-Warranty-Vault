"""DynamoDB key helpers for the single-table ReceiptVault schema."""


def build_pk(user_id):
    """Build a partition key from a user ID."""
    return f"USER#{user_id}"


def build_receipt_sk(receipt_id):
    """Build a sort key for a receipt item."""
    return f"RECEIPT#{receipt_id}"


def build_categories_sk():
    """Return the sort key for the user categories meta item."""
    return "META#CATEGORIES"


def build_settings_sk():
    """Return the sort key for the user settings meta item."""
    return "META#SETTINGS"


def extract_receipt_id(sk):
    """Extract the receipt ID from a sort key."""
    return sk.removeprefix("RECEIPT#")


def extract_user_id(pk):
    """Extract the user ID from a partition key."""
    return pk.removeprefix("USER#")
