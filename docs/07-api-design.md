# 07 -- API Design

**Document**: REST API Design Specification
**Version**: 1.0
**Status**: Pre-Implementation (Documentation Phase)
**Last Updated**: 2026-02-08

---

## Table of Contents

1. [Overview](#overview)
2. [API Conventions](#api-conventions)
3. [Authentication and Authorization](#authentication-and-authorization)
4. [Pagination](#pagination)
5. [Error Handling](#error-handling)
6. [Rate Limiting](#rate-limiting)
7. [Receipts Endpoints](#receipts-endpoints)
8. [Image Endpoints](#image-endpoints)
9. [OCR and LLM Endpoints](#ocr-and-llm-endpoints)
10. [Sync Endpoints](#sync-endpoints)
11. [Category Endpoints](#category-endpoints)
12. [Warranty Endpoints](#warranty-endpoints)
13. [User and Account Endpoints](#user-and-account-endpoints)
14. [Webhook and Push Events](#webhook-and-push-events)
15. [Common Data Structures](#common-data-structures)

---

## Overview

The Receipt & Warranty Vault API is a RESTful HTTP API that serves as the backend interface between the Flutter mobile client and the AWS cloud infrastructure. The API is deployed behind Amazon API Gateway with a Cognito User Pool authorizer, ensuring that every request is authenticated and that the user's identity is extracted server-side from the JWT token.

The API follows an offline-first client model. The Flutter app stores all data locally in Drift (SQLite with SQLCipher encryption) and uses the API exclusively for cloud sync, image storage, LLM-powered OCR refinement, and server-side operations such as scheduled warranty checks and account management. The client never depends on the API for core functionality -- it is an enhancement layer.

All API endpoints are implemented as AWS Lambda functions (Python 3.12) invoked through API Gateway. Data persistence is handled by DynamoDB (single-table design with 6 GSIs) and Amazon S3 (for receipt images with SSE-KMS encryption).

---

## API Conventions

### Base URL

```
https://api.receiptvault.app/v1
```

The base URL points to the API Gateway custom domain. During development and testing, the auto-generated API Gateway URL will be used until the custom domain (api.receiptvault.app) is configured with an ACM certificate and Route 53 DNS record.

### Content Type

All request and response bodies use JSON.

```
Content-Type: application/json
Accept: application/json
```

Binary data (receipt images) is never sent directly through the API. Instead, the client requests a pre-signed S3 URL and uploads/downloads images directly to/from S3.

### HTTP Methods

The API uses standard HTTP methods with their conventional meanings:

| Method | Usage |
|--------|-------|
| GET | Retrieve a resource or list of resources. No request body. Parameters passed as query strings. |
| POST | Create a new resource, trigger an action, or submit data for processing. Request body required. |
| PUT | Full replacement of a resource. The entire resource representation must be sent. Request body required. |
| PATCH | Partial update of specific fields on a resource. Only changed fields are sent. Request body required. |
| DELETE | Remove a resource (soft delete in this API -- sets status to deleted, does not immediately destroy data). |

### Date Format

All dates and timestamps are represented in ISO 8601 format with UTC timezone.

- Full timestamps: `2026-02-08T14:30:00.000Z`
- Date-only values (such as purchase date): `2026-02-08`

The client is responsible for converting between UTC and the user's local timezone for display purposes. The API always stores and returns UTC.

### Monetary Values

All monetary amounts are represented as JSON numbers with exactly 2 decimal places of precision.

```json
{
  "totalAmount": 49.99,
  "currency": "EUR"
}
```

Currency codes follow the ISO 4217 standard (three uppercase letters: EUR, USD, GBP, etc.).

### Boolean Values

Standard JSON booleans (`true` / `false`). Never represented as strings or integers.

### Null Values

Fields with no value are either omitted from the response entirely or explicitly set to `null`. The client must handle both cases. Optional request body fields can be omitted or set to `null` -- both are treated identically.

### Request IDs

Every API response includes an `X-Request-Id` header containing a UUID that uniquely identifies the request. This value is logged server-side and should be included when reporting errors or debugging issues.

---

## Authentication and Authorization

### Bearer Token Authentication

Every API request must include a valid Cognito JWT access token in the `Authorization` header.

```
Authorization: Bearer eyJraWQiOiI...
```

The token is issued by the Cognito User Pool after successful authentication (email/password, Google Sign-In, or Apple Sign-In) and is managed on the client side by the Amplify Flutter Gen 2 SDK. Access tokens have a 1-hour lifetime. The Amplify SDK transparently refreshes expired access tokens using the refresh token (30-90 day lifetime) without requiring user interaction.

### User Identity Extraction

The `userId` is never passed by the client in any request body, query parameter, or URL path. It is extracted server-side from the `sub` claim of the validated JWT token by the Cognito authorizer attached to API Gateway. This ensures that a user can only access their own data and eliminates an entire class of authorization bypass vulnerabilities.

The Lambda function receives the authenticated user's identity through the API Gateway event context:

```
event.requestContext.authorizer.claims.sub
```

### Unauthorized Responses

If the token is missing, expired, or invalid, API Gateway returns a 401 response before the request ever reaches the Lambda function.

```json
{
  "message": "Unauthorized"
}
```

This is the standard API Gateway Cognito authorizer response and is not customizable.

---

## Pagination

### Cursor-Based Pagination

All list endpoints that can return large result sets use cursor-based pagination powered by DynamoDB's `LastEvaluatedKey` mechanism.

The client sends a `cursor` query parameter (or field in a POST body, depending on the endpoint). The server returns a `nextCursor` field in the response if more results are available. When `nextCursor` is `null` or absent, the client has reached the end of the result set.

### Cursor Encoding

The cursor value is the DynamoDB `LastEvaluatedKey` object serialized to JSON and then Base64-encoded. This makes the cursor opaque to the client -- the client should never attempt to parse, construct, or modify cursor values. It simply stores the `nextCursor` from one response and passes it as the `cursor` in the next request.

### Page Size

The default page size is 20 items. The client can request a different page size using the `limit` query parameter, with a maximum of 100 items per page. Requesting more than 100 returns a 400 error.

### Example

Request:

```
GET /v1/receipts?limit=20&cursor=eyJQSyI6IlVTRVIjYWJjMTIzIiwiU0siOiJSRUNFSVBUIzIwMjYtMDEtMTUifQ==
```

Response:

```json
{
  "items": [ ... ],
  "nextCursor": "eyJQSyI6IlVTRVIjYWJjMTIzIiwiU0siOiJSRUNFSVBUIzIwMjUtMTItMjAifQ==",
  "count": 20
}
```

---

## Error Handling

### Error Response Format

All error responses follow a consistent structure.

```json
{
  "error": {
    "code": "RECEIPT_NOT_FOUND",
    "message": "The receipt with ID 'abc-123' does not exist or has been deleted."
  }
}
```

| Field | Type | Description |
|-------|------|-------------|
| error.code | String | A machine-readable uppercase error code using underscores. The client uses this value for programmatic error handling. |
| error.message | String | A human-readable description of the error. Intended for logging and debugging, not for direct display to end users. |

### HTTP Status Codes

| Status Code | Meaning | When Used |
|-------------|---------|-----------|
| 200 | OK | Successful GET, PUT, PATCH, or action (e.g., restore) |
| 201 | Created | Successful POST that creates a new resource |
| 204 | No Content | Successful DELETE with no response body |
| 400 | Bad Request | Invalid request body, missing required fields, validation failure |
| 401 | Unauthorized | Missing or invalid JWT token (returned by API Gateway authorizer) |
| 403 | Forbidden | Valid token but insufficient permissions (e.g., accessing another user's resource) |
| 404 | Not Found | Resource does not exist or does not belong to the authenticated user |
| 409 | Conflict | Version conflict during update (optimistic concurrency check failed) |
| 413 | Payload Too Large | Request body exceeds maximum allowed size |
| 422 | Unprocessable Entity | Request is syntactically valid but semantically incorrect (e.g., invalid date format) |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Unexpected server error |
| 502 | Bad Gateway | Lambda function error or timeout (propagated by API Gateway) |
| 503 | Service Unavailable | Downstream service unavailable (DynamoDB, Bedrock, S3) |

### Error Codes

The following error codes are used across the API. Each endpoint section lists which codes it can return.

| Error Code | HTTP Status | Description |
|------------|-------------|-------------|
| VALIDATION_ERROR | 400 | Request body fails schema validation |
| MISSING_REQUIRED_FIELD | 400 | A required field is missing from the request body |
| INVALID_CURSOR | 400 | The pagination cursor is malformed or expired |
| INVALID_DATE_FORMAT | 422 | A date field is not in ISO 8601 format |
| INVALID_CURRENCY | 422 | Currency code is not a valid ISO 4217 code |
| RECEIPT_NOT_FOUND | 404 | Receipt does not exist or does not belong to user |
| RECEIPT_ALREADY_DELETED | 409 | Attempting to delete a receipt that is already soft-deleted |
| RECEIPT_NOT_DELETED | 409 | Attempting to restore a receipt that is not in deleted status |
| RECEIPT_EXPIRED_DELETE | 410 | Attempting to restore a receipt whose 30-day recovery window has passed |
| VERSION_CONFLICT | 409 | The version number in the update does not match the current server version |
| IMAGE_LIMIT_EXCEEDED | 400 | Receipt has reached maximum number of images (10 per receipt) |
| IMAGE_NOT_FOUND | 404 | Image key does not exist for the specified receipt |
| INVALID_CONTENT_TYPE | 400 | Requested content type for image upload is not allowed (must be image/jpeg, image/png, or image/webp) |
| FILE_TOO_LARGE | 413 | Requested upload size exceeds maximum (10 MB) |
| REFINE_IN_PROGRESS | 409 | An LLM refinement job is already in progress for this receipt |
| REFINE_FAILED | 500 | LLM refinement failed (Bedrock error or timeout) |
| SYNC_CONFLICT | 409 | One or more items in a sync push had conflicts (details in per-item results) |
| CATEGORY_LIMIT_EXCEEDED | 400 | User has reached maximum number of custom categories (50) |
| EXPORT_IN_PROGRESS | 409 | A data export is already in progress for this user |
| DELETION_CONFIRMATION_REQUIRED | 400 | Account deletion request is missing the confirmation token |
| DELETION_CONFIRMATION_INVALID | 403 | The confirmation token for account deletion is invalid or expired |
| RATE_LIMIT_EXCEEDED | 429 | User has exceeded the per-user rate limit |
| INTERNAL_ERROR | 500 | An unexpected error occurred on the server |

---

## Rate Limiting

### API Gateway Throttling

Rate limiting is enforced at the API Gateway level using usage plans.

| Setting | Value |
|---------|-------|
| Steady-state rate | 10 requests per second per user |
| Burst capacity | 100 requests |
| Scope | Per authenticated user (keyed on Cognito `sub` claim) |

When the rate limit is exceeded, the API returns a 429 status with the following response:

```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Request rate limit exceeded. Please retry after a brief delay."
  }
}
```

The response includes a `Retry-After` header with the number of seconds the client should wait before retrying.

The client (Dio HTTP client) is configured with automatic retry logic that respects the `Retry-After` header and applies exponential backoff for 429 responses.

---

## Receipts Endpoints

### 1. POST /receipts

**Create a New Receipt**

Creates a new receipt record in DynamoDB. The client calls this endpoint after the receipt has been saved locally in the Drift database. The `receiptId` is generated client-side (UUID v4) to support offline-first creation.

**Request Body**

```json
{
  "receiptId": "550e8400-e29b-41d4-a716-446655440000",
  "merchantName": "IKEA Greece",
  "purchaseDate": "2026-02-05",
  "totalAmount": 149.99,
  "currency": "EUR",
  "category": "Furniture",
  "warrantyMonths": 24,
  "warrantyExpiryDate": "2028-02-05",
  "items": [
    {
      "name": "KALLAX Shelf Unit",
      "quantity": 1,
      "price": 149.99
    }
  ],
  "notes": "For home office",
  "tags": ["office", "furniture"],
  "ocrRawText": "IKEA GREECE\nDate: 05/02/2026\nKALLAX...",
  "llmConfidence": 0.94,
  "imageKeys": ["users/abc123/receipts/550e8400/original/receipt.jpg"],
  "storageMode": "cloud",
  "status": "active",
  "isFavorite": false,
  "userEditedFields": [],
  "clientVersion": 1,
  "clientUpdatedAt": "2026-02-05T14:30:00.000Z"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| receiptId | String (UUID) | Yes | Client-generated unique identifier |
| merchantName | String | No | Merchant or store name (extracted or manually entered) |
| purchaseDate | String (ISO 8601 date) | No | Date of purchase |
| totalAmount | Number | No | Total receipt amount with 2 decimal precision |
| currency | String (ISO 4217) | No | Three-letter currency code (defaults to user's default currency) |
| category | String | No | Category name (one of defaults or user-created custom) |
| warrantyMonths | Integer | No | Warranty duration in months |
| warrantyExpiryDate | String (ISO 8601 date) | No | Calculated warranty expiry date |
| items | Array of objects | No | Line items from the receipt |
| items[].name | String | Yes (if items present) | Item description |
| items[].quantity | Integer | No | Item quantity (defaults to 1) |
| items[].price | Number | No | Item price with 2 decimal precision |
| notes | String | No | User-added notes |
| tags | Array of strings | No | User-added tags |
| ocrRawText | String | No | Raw OCR text extracted on-device |
| llmConfidence | Number (0-1) | No | Confidence score from LLM extraction |
| imageKeys | Array of strings | No | S3 object keys for uploaded images |
| storageMode | String | Yes | Either "cloud" or "device_only" |
| status | String | Yes | "active", "returned", or "archived" |
| isFavorite | Boolean | No | Whether the receipt is marked as favorite (defaults to false) |
| userEditedFields | Array of strings | No | List of field names the user has manually edited (for conflict resolution tiers) |
| clientVersion | Integer | Yes | Client-side version counter (starts at 1) |
| clientUpdatedAt | String (ISO 8601) | Yes | Timestamp of last client modification |

**Response** (201 Created)

```json
{
  "receiptId": "550e8400-e29b-41d4-a716-446655440000",
  "serverVersion": 1,
  "serverUpdatedAt": "2026-02-05T14:30:01.000Z",
  "createdAt": "2026-02-05T14:30:01.000Z"
}
```

**Error Cases**

| Error Code | Condition |
|------------|-----------|
| VALIDATION_ERROR | Request body fails schema validation |
| MISSING_REQUIRED_FIELD | receiptId, storageMode, status, clientVersion, or clientUpdatedAt is missing |
| INVALID_DATE_FORMAT | purchaseDate or warrantyExpiryDate is not valid ISO 8601 |
| INVALID_CURRENCY | currency is not a valid ISO 4217 code |
| VERSION_CONFLICT | A receipt with this receiptId already exists for this user (duplicate creation -- client should use PUT to update) |

**Notes**

- The `receiptId` is generated client-side as a UUID v4 to enable offline creation. If the client sends a `receiptId` that already exists in DynamoDB for this user, the server returns a 409 VERSION_CONFLICT. The client should interpret this as "already synced" and use PUT for updates.
- The `storageMode` field is informational -- if the user has chosen "device_only" mode, the client should not call this endpoint at all. It is included in the schema for completeness and for cases where the user switches storage mode.
- The server sets the DynamoDB `PK` as `USER#<userId>` and `SK` as `RECEIPT#<receiptId>`, along with all GSI key attributes.

---

### 2. GET /receipts

**List User's Receipts**

Returns a paginated list of the authenticated user's receipts, sorted by purchase date descending (most recent first). Only receipts with status "active", "returned", or "archived" are included. Soft-deleted receipts are excluded unless explicitly requested.

**Query Parameters**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| limit | Integer | No | 20 | Number of items per page (max 100) |
| cursor | String | No | null | Base64-encoded pagination cursor from previous response |
| category | String | No | null | Filter by category name |
| store | String | No | null | Filter by merchant/store name (exact match) |
| status | String | No | null | Filter by status: "active", "returned", "archived", or "deleted" |
| dateFrom | String (ISO 8601 date) | No | null | Filter receipts purchased on or after this date |
| dateTo | String (ISO 8601 date) | No | null | Filter receipts purchased on or before this date |
| includeDeleted | Boolean | No | false | If true, includes soft-deleted receipts in results |

**Response** (200 OK)

```json
{
  "items": [
    {
      "receiptId": "550e8400-e29b-41d4-a716-446655440000",
      "merchantName": "IKEA Greece",
      "purchaseDate": "2026-02-05",
      "totalAmount": 149.99,
      "currency": "EUR",
      "category": "Furniture",
      "warrantyMonths": 24,
      "warrantyExpiryDate": "2028-02-05",
      "items": [
        {
          "name": "KALLAX Shelf Unit",
          "quantity": 1,
          "price": 149.99
        }
      ],
      "notes": "For home office",
      "tags": ["office", "furniture"],
      "imageKeys": ["users/abc123/receipts/550e8400/original/receipt.jpg"],
      "thumbnailKeys": ["users/abc123/receipts/550e8400/thumbnail/receipt.jpg"],
      "status": "active",
      "isFavorite": false,
      "serverVersion": 1,
      "createdAt": "2026-02-05T14:30:01.000Z",
      "serverUpdatedAt": "2026-02-05T14:30:01.000Z"
    }
  ],
  "nextCursor": "eyJQSyI6IlVTRVIjYWJjMTIzIiwiU0siOiJSRUNFSVBUIzIwMjUtMTItMjAifQ==",
  "count": 20
}
```

**Error Cases**

| Error Code | Condition |
|------------|-----------|
| VALIDATION_ERROR | Invalid query parameter type or value |
| INVALID_CURSOR | The cursor parameter is malformed or has expired |
| INVALID_DATE_FORMAT | dateFrom or dateTo is not valid ISO 8601 |

**Notes**

- When no filter parameters are provided, the endpoint queries the main table using `PK = USER#<userId>` with `SK begins_with RECEIPT#`, sorted by purchase date descending via GSI-1 (ByUserDate).
- When `category` is provided, the query uses GSI-2 (ByUserCategory) with `SK begins_with CAT#<category>`.
- When `store` is provided, the query uses GSI-3 (ByUserStore) with `SK begins_with STORE#<storeName>`.
- When `status` is provided, the query uses GSI-5 (ByUserStatus) with `SK begins_with STATUS#<status>`.
- Multiple filters cannot be combined in a single GSI query. If multiple filters are provided, the Lambda function queries the most selective GSI and applies remaining filters in-memory. This is acceptable at v1 scale (hundreds to low thousands of receipts per user).
- The `items` array and `ocrRawText` are excluded from list responses to reduce payload size. The client must call GET /receipts/{receiptId} for full detail.

---

### 3. GET /receipts/{receiptId}

**Get Single Receipt Detail**

Returns the complete detail of a single receipt, including all fields, line items, OCR text, and image keys.

**Path Parameters**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| receiptId | String (UUID) | Yes | The unique identifier of the receipt |

**Response** (200 OK)

```json
{
  "receiptId": "550e8400-e29b-41d4-a716-446655440000",
  "merchantName": "IKEA Greece",
  "purchaseDate": "2026-02-05",
  "totalAmount": 149.99,
  "currency": "EUR",
  "category": "Furniture",
  "warrantyMonths": 24,
  "warrantyExpiryDate": "2028-02-05",
  "items": [
    {
      "name": "KALLAX Shelf Unit",
      "quantity": 1,
      "price": 149.99
    }
  ],
  "notes": "For home office",
  "tags": ["office", "furniture"],
  "ocrRawText": "IKEA GREECE\nDate: 05/02/2026\nKALLAX Shelf Unit  1 x 149.99\nTotal: 149.99 EUR\n2 Year Manufacturer Warranty",
  "llmConfidence": 0.94,
  "imageKeys": ["users/abc123/receipts/550e8400/original/receipt.jpg"],
  "thumbnailKeys": ["users/abc123/receipts/550e8400/thumbnail/receipt.jpg"],
  "storageMode": "cloud",
  "status": "active",
  "isFavorite": false,
  "userEditedFields": [],
  "serverVersion": 1,
  "clientVersion": 1,
  "createdAt": "2026-02-05T14:30:01.000Z",
  "serverUpdatedAt": "2026-02-05T14:30:01.000Z",
  "clientUpdatedAt": "2026-02-05T14:30:00.000Z"
}
```

**Error Cases**

| Error Code | Condition |
|------------|-----------|
| RECEIPT_NOT_FOUND | Receipt does not exist, belongs to a different user, or has been hard-deleted (past TTL expiry) |

**Notes**

- This endpoint returns all fields including `ocrRawText` and `llmConfidence`, which are omitted from the list endpoint to save bandwidth.
- Soft-deleted receipts are still accessible through this endpoint (they have `status: "deleted"` and include a `deletedAt` timestamp). Only receipts that have passed the 30-day TTL and been permanently removed by DynamoDB return RECEIPT_NOT_FOUND.
- The `serverVersion` and `clientVersion` fields are critical for the sync engine's conflict detection.

---

### 4. PUT /receipts/{receiptId}

**Update Receipt (Full Update)**

Replaces the receipt record with the provided data. Uses optimistic concurrency control via the `serverVersion` field -- the client must send the version it last received, and the server rejects the update if another write has occurred in between.

**Path Parameters**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| receiptId | String (UUID) | Yes | The unique identifier of the receipt |

**Request Body**

The request body has the same structure as POST /receipts, with the addition of the `serverVersion` field for conflict detection.

```json
{
  "merchantName": "IKEA Greece",
  "purchaseDate": "2026-02-05",
  "totalAmount": 149.99,
  "currency": "EUR",
  "category": "Home & Furniture",
  "warrantyMonths": 24,
  "warrantyExpiryDate": "2028-02-05",
  "items": [
    {
      "name": "KALLAX Shelf Unit",
      "quantity": 1,
      "price": 149.99
    }
  ],
  "notes": "For home office - white color",
  "tags": ["office", "furniture", "white"],
  "ocrRawText": "IKEA GREECE\nDate: 05/02/2026\n...",
  "llmConfidence": 0.94,
  "imageKeys": ["users/abc123/receipts/550e8400/original/receipt.jpg"],
  "storageMode": "cloud",
  "status": "active",
  "isFavorite": true,
  "userEditedFields": ["category", "notes"],
  "serverVersion": 1,
  "clientVersion": 2,
  "clientUpdatedAt": "2026-02-06T09:15:00.000Z"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| serverVersion | Integer | Yes | The version number the client last received from the server. Used for optimistic concurrency. |
| clientVersion | Integer | Yes | The client's local version counter, incremented on each local edit. |
| clientUpdatedAt | String (ISO 8601) | Yes | Timestamp of the latest client modification. |

All other fields follow the same schema as POST /receipts.

**Response** (200 OK)

```json
{
  "receiptId": "550e8400-e29b-41d4-a716-446655440000",
  "serverVersion": 2,
  "serverUpdatedAt": "2026-02-06T09:15:01.000Z"
}
```

**Error Cases**

| Error Code | Condition |
|------------|-----------|
| RECEIPT_NOT_FOUND | Receipt does not exist or belongs to a different user |
| VERSION_CONFLICT | The `serverVersion` in the request does not match the current version in DynamoDB. The response body includes the current server state so the client can resolve the conflict locally. |
| VALIDATION_ERROR | Request body fails schema validation |
| MISSING_REQUIRED_FIELD | serverVersion, clientVersion, or clientUpdatedAt is missing |

**Notes**

- On VERSION_CONFLICT (409), the response body contains the current server state of the receipt in addition to the error object, allowing the client to perform field-level merge locally:

```json
{
  "error": {
    "code": "VERSION_CONFLICT",
    "message": "Server version is 3, but client sent version 1."
  },
  "currentServerState": {
    "receiptId": "550e8400-e29b-41d4-a716-446655440000",
    "serverVersion": 3,
    "merchantName": "IKEA Greece",
    "...": "..."
  }
}
```

- The `serverVersion` is atomically incremented by the server using a DynamoDB conditional write (`attribute_exists(PK) AND serverVersion = :expectedVersion`). This guarantees that no concurrent write can silently overwrite data.
- This is a full replacement operation. The client must send the complete receipt object, not just changed fields. The server overwrites the entire item in DynamoDB.
- The `userEditedFields` array is critical for the sync engine's field-level conflict resolution. When the server (LLM refinement) and client (user edit) both modify the same receipt, the sync engine consults this array and the conflict resolution tiers to determine which value wins. See doc 10 (Offline Sync Architecture) for the full merge algorithm.

---

### 5. DELETE /receipts/{receiptId}

**Soft Delete Receipt**

Marks the receipt as deleted by setting its status to "deleted", recording the deletion timestamp, and setting a DynamoDB TTL attribute for automatic hard deletion after 30 days. The receipt and its associated S3 images remain recoverable during the 30-day window.

**Path Parameters**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| receiptId | String (UUID) | Yes | The unique identifier of the receipt |

**Response** (200 OK)

```json
{
  "receiptId": "550e8400-e29b-41d4-a716-446655440000",
  "status": "deleted",
  "deletedAt": "2026-02-08T10:00:00.000Z",
  "permanentDeletionAt": "2026-03-10T10:00:00.000Z",
  "serverVersion": 3
}
```

| Field | Type | Description |
|-------|------|-------------|
| deletedAt | String (ISO 8601) | Timestamp when the soft delete was performed |
| permanentDeletionAt | String (ISO 8601) | Timestamp when DynamoDB TTL will permanently remove the record (approximately 30 days from deletion) |

**Error Cases**

| Error Code | Condition |
|------------|-----------|
| RECEIPT_NOT_FOUND | Receipt does not exist or belongs to a different user |
| RECEIPT_ALREADY_DELETED | Receipt is already in "deleted" status |

**Notes**

- Soft delete sets the `ttl` attribute on the DynamoDB item to the current time plus 30 days (as a Unix epoch timestamp). DynamoDB's TTL mechanism will automatically remove the item after this time.
- S3 images are not deleted during soft delete. S3 versioning is enabled on the bucket, so images remain accessible through their version IDs even if a lifecycle rule eventually removes noncurrent versions. The 30-day NoncurrentVersionExpiration lifecycle rule aligns with the DynamoDB TTL window.
- The `serverVersion` is incremented on soft delete to ensure sync correctness. The client sync engine receives the deletion status during the next delta sync pull.
- The receipt's GSI entries are updated: it no longer appears in GSI-4 (ByWarrantyExpiry) because the composite PK includes `#ACTIVE`, and it is queryable via GSI-5 (ByUserStatus) with `STATUS#deleted`.

---

### 6. POST /receipts/{receiptId}/restore

**Restore Soft-Deleted Receipt**

Restores a previously soft-deleted receipt to active status, removing the TTL attribute and resetting the status to "active". This is only possible within the 30-day recovery window.

**Path Parameters**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| receiptId | String (UUID) | Yes | The unique identifier of the receipt |

**Response** (200 OK)

```json
{
  "receiptId": "550e8400-e29b-41d4-a716-446655440000",
  "status": "active",
  "restoredAt": "2026-02-09T08:00:00.000Z",
  "serverVersion": 4
}
```

**Error Cases**

| Error Code | Condition |
|------------|-----------|
| RECEIPT_NOT_FOUND | Receipt does not exist or belongs to a different user |
| RECEIPT_NOT_DELETED | Receipt is not in "deleted" status (cannot restore a non-deleted receipt) |
| RECEIPT_EXPIRED_DELETE | The 30-day recovery window has passed and the DynamoDB TTL has already removed the item, or the item is about to be removed |

**Notes**

- Restoration removes the `ttl` attribute from the DynamoDB item, clears the `deletedAt` field, and sets the status back to "active".
- If the receipt had an active warranty at the time of deletion, the warranty tracking resumes and the receipt reappears in GSI-4 (ByWarrantyExpiry) queries.
- The `serverVersion` is incremented to propagate the restoration to all synced devices.

---

### 7. PATCH /receipts/{receiptId}/status

**Update Receipt Status**

Updates the status of a receipt. This endpoint is specifically designed for the "Mark as Returned" feature, allowing users to flag a receipt as returned without sending the entire receipt object.

**Path Parameters**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| receiptId | String (UUID) | Yes | The unique identifier of the receipt |

**Request Body**

```json
{
  "status": "returned",
  "serverVersion": 2
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| status | String | Yes | New status value. Allowed values: "active", "returned", "archived" |
| serverVersion | Integer | Yes | Current server version for optimistic concurrency |

**Response** (200 OK)

```json
{
  "receiptId": "550e8400-e29b-41d4-a716-446655440000",
  "status": "returned",
  "statusChangedAt": "2026-02-10T11:00:00.000Z",
  "serverVersion": 3
}
```

**Error Cases**

| Error Code | Condition |
|------------|-----------|
| RECEIPT_NOT_FOUND | Receipt does not exist or belongs to a different user |
| VALIDATION_ERROR | Status value is not one of the allowed values |
| VERSION_CONFLICT | Server version mismatch |

**Notes**

- When a receipt is marked as "returned", it remains visible in the vault but is visually distinguished in the UI (e.g., dimmed or labeled "Returned"). It is no longer counted in active warranty statistics.
- Setting status to "returned" does not remove the receipt from GSI-4 (ByWarrantyExpiry) queries automatically -- the Lambda function explicitly updates the GSI-4 PK to exclude the `#ACTIVE` suffix, removing it from warranty tracking.
- This is a convenience endpoint for lightweight status changes. The full PUT endpoint can also be used to change status as part of a broader update.

---

## Image Endpoints

### 8. POST /receipts/{receiptId}/images/upload-url

**Generate Pre-Signed S3 Upload URL**

Generates a pre-signed S3 PUT URL that the client uses to upload a receipt image directly to S3. The API never receives the image binary -- it only generates the authorization URL. This offloads bandwidth from the API layer and enables direct, efficient S3 uploads.

**Path Parameters**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| receiptId | String (UUID) | Yes | The receipt this image belongs to |

**Request Body**

```json
{
  "filename": "receipt_front.jpg",
  "contentType": "image/jpeg",
  "contentLength": 1843200
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| filename | String | Yes | Original filename (used in S3 key construction) |
| contentType | String | Yes | MIME type of the image. Allowed: "image/jpeg", "image/png", "image/webp" |
| contentLength | Integer | Yes | Exact file size in bytes. Maximum: 10,485,760 (10 MB) |

**Response** (200 OK)

```json
{
  "uploadUrl": "https://receiptvault-images-prod-eu-west-1.s3.eu-west-1.amazonaws.com/users/abc123/receipts/550e8400/original/receipt_front.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&...",
  "imageKey": "users/abc123/receipts/550e8400/original/receipt_front.jpg",
  "expiresAt": "2026-02-08T10:10:00.000Z",
  "headers": {
    "Content-Type": "image/jpeg",
    "Content-Length": "1843200",
    "x-amz-server-side-encryption": "aws:kms",
    "x-amz-server-side-encryption-aws-kms-key-id": "arn:aws:kms:eu-west-1:123456789:key/abc-def-ghi"
  }
}
```

| Field | Type | Description |
|-------|------|-------------|
| uploadUrl | String | Pre-signed S3 PUT URL. Valid for 10 minutes. |
| imageKey | String | The S3 object key where the image will be stored. The client must store this key locally and include it in subsequent receipt updates. |
| expiresAt | String (ISO 8601) | Timestamp when the upload URL expires |
| headers | Object | HTTP headers the client must include when making the PUT request to the upload URL. These enforce content type, size, and server-side encryption. |

**Error Cases**

| Error Code | Condition |
|------------|-----------|
| RECEIPT_NOT_FOUND | Receipt does not exist or belongs to a different user |
| INVALID_CONTENT_TYPE | contentType is not one of the allowed image MIME types |
| FILE_TOO_LARGE | contentLength exceeds 10 MB |
| IMAGE_LIMIT_EXCEEDED | Receipt already has 10 images attached |

**Notes**

- The pre-signed URL is configured with conditions that enforce the exact content type and content length declared in the request. If the client uploads a file that does not match these conditions, S3 rejects the upload with a 403 error.
- The S3 object key follows the structure: `users/{userId}/receipts/{receiptId}/original/{filename}`. The userId is extracted from the JWT token, not from the client request.
- After a successful upload to S3, a Lambda trigger (thumbnail-generator) automatically creates a 200x300px JPEG thumbnail at `users/{userId}/receipts/{receiptId}/thumbnail/{filename}`.
- The client should update the receipt's `imageKeys` array to include the new `imageKey` value and sync the change via PUT /receipts/{receiptId}.
- The pre-signed URL includes SSE-KMS encryption parameters. The client must include the provided headers exactly when performing the upload, or S3 will reject the request.
- GPS EXIF data should be stripped client-side before upload (using the image/flutter_image_compress package). The server does not perform EXIF stripping.

---

### 9. GET /receipts/{receiptId}/images/{imageKey}/download-url

**Generate Pre-Signed S3 Download URL**

Generates a pre-signed S3 GET URL that the client uses to download a receipt image directly from S3.

**Path Parameters**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| receiptId | String (UUID) | Yes | The receipt this image belongs to |
| imageKey | String | Yes | The S3 object key of the image (URL-encoded) |

**Query Parameters**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| variant | String | No | "original" | Either "original" or "thumbnail". Determines which S3 prefix is used. |

**Response** (200 OK)

```json
{
  "downloadUrl": "https://receiptvault-images-prod-eu-west-1.s3.eu-west-1.amazonaws.com/users/abc123/receipts/550e8400/original/receipt_front.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&...",
  "expiresAt": "2026-02-08T10:10:00.000Z",
  "contentType": "image/jpeg",
  "contentLength": 1843200
}
```

**Error Cases**

| Error Code | Condition |
|------------|-----------|
| RECEIPT_NOT_FOUND | Receipt does not exist or belongs to a different user |
| IMAGE_NOT_FOUND | The specified image key does not exist in S3 for this receipt |

**Notes**

- The pre-signed URL has a 10-minute expiry. The client should request a new URL if the previous one has expired rather than caching URLs for extended periods.
- For thumbnail access, the client can optionally use CloudFront URLs directly (CloudFront is configured with Origin Access Control for the S3 bucket). However, original images should always be accessed through pre-signed URLs to maintain fine-grained access control.
- The server validates that the `imageKey` belongs to the specified `receiptId` and the authenticated user before generating the URL. A user cannot generate download URLs for another user's images.

---

## OCR and LLM Endpoints

### 10. POST /receipts/{receiptId}/refine

**Submit Receipt for Cloud LLM Refinement**

Submits the receipt's OCR data and (optionally) image to AWS Bedrock Claude Haiku 4.5 for intelligent extraction and refinement. This is an asynchronous operation: the endpoint returns immediately with a job status, and the refined results are delivered to the client via the sync mechanism and a push notification.

**Path Parameters**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| receiptId | String (UUID) | Yes | The receipt to refine |

**Request Body**

```json
{
  "ocrRawText": "IKEA GREECE\nKALLAX Shelf Unit\n1 x 149.99\nTotal: EUR 149.99\n05/02/2026\n2 Year Manufacturer Warranty",
  "imageKey": "users/abc123/receipts/550e8400/original/receipt_front.jpg",
  "language": "en",
  "currentData": {
    "merchantName": "IKEA GREECE",
    "purchaseDate": "2026-02-05",
    "totalAmount": 149.99,
    "currency": "EUR"
  }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| ocrRawText | String | Yes | Raw text extracted by on-device OCR (ML Kit and/or Tesseract) |
| imageKey | String | No | S3 key of the receipt image. If provided, the LLM receives both the text and the image for multimodal analysis. |
| language | String | No | Detected language hint ("en" or "el"). Helps the LLM focus its parsing. |
| currentData | Object | No | The data currently extracted by on-device OCR. The LLM uses this as a starting point and attempts to correct and enhance it. |

**Response** (202 Accepted)

```json
{
  "receiptId": "550e8400-e29b-41d4-a716-446655440000",
  "jobStatus": "submitted",
  "estimatedCompletionSeconds": 5,
  "message": "Refinement job submitted. Results will be available via sync."
}
```

**Error Cases**

| Error Code | Condition |
|------------|-----------|
| RECEIPT_NOT_FOUND | Receipt does not exist or belongs to a different user |
| MISSING_REQUIRED_FIELD | ocrRawText is missing |
| REFINE_IN_PROGRESS | A refinement job is already running for this receipt. The client should wait for the current job to complete. |
| IMAGE_NOT_FOUND | The provided imageKey does not exist in S3 |

**Notes**

- The Lambda function (ocr-refine) invokes Bedrock Claude Haiku 4.5 with a structured prompt that instructs the model to extract and normalize: merchant name, purchase date, individual line items with quantities and prices, total amount, currency, and warranty information.
- If Haiku 4.5 is unavailable or returns a low-confidence result (below a configurable threshold, default 0.70), the function automatically retries with Claude Sonnet 4.5 as a fallback. The higher-cost Sonnet model is only invoked when Haiku fails or is uncertain.
- The refinement result is written directly to the DynamoDB receipt item, updating the extracted fields and incrementing the `serverVersion`. The LLM-extracted fields follow Tier 1 conflict resolution rules (server/LLM wins), unless the user has manually edited those fields (tracked in `userEditedFields`), in which case the user's values are preserved.
- After the DynamoDB write completes, the Lambda function sends an SNS push notification (`receipt.refined`) to the user's registered device, prompting the client app to perform a delta sync pull.
- The estimated completion time is typically 2-5 seconds for Haiku 4.5. The client should not poll -- it should wait for the push notification or detect the change during the next sync cycle.
- Bedrock is configured with no data storage and no model training on user data, in compliance with GDPR requirements.

---

## Sync Endpoints

### 11. POST /sync/pull

**Delta Sync Pull**

The primary sync mechanism. The client sends the timestamp of its last successful sync, and the server returns all receipt records that have been created, updated, or deleted after that timestamp. This is the most frequently called sync endpoint and is optimized for efficiency.

**Request Body**

```json
{
  "lastSyncTimestamp": "2026-02-07T20:00:00.000Z",
  "limit": 50
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| lastSyncTimestamp | String (ISO 8601) | Yes | The timestamp from the `newSyncTimestamp` field of the previous successful sync pull. For the very first sync, the client sends the epoch ("1970-01-01T00:00:00.000Z") or omits this field. |
| limit | Integer | No | Maximum number of items to return per page (default 50, max 200). If there are more changes than the limit, the response includes a cursor for pagination. |

**Response** (200 OK)

```json
{
  "items": [
    {
      "receiptId": "550e8400-e29b-41d4-a716-446655440000",
      "merchantName": "IKEA Greece",
      "purchaseDate": "2026-02-05",
      "totalAmount": 149.99,
      "currency": "EUR",
      "category": "Furniture",
      "warrantyMonths": 24,
      "warrantyExpiryDate": "2028-02-05",
      "items": [
        {
          "name": "KALLAX Shelf Unit",
          "quantity": 1,
          "price": 149.99
        }
      ],
      "notes": "For home office - white color",
      "tags": ["office", "furniture", "white"],
      "ocrRawText": "IKEA GREECE\nDate: 05/02/2026\n...",
      "llmConfidence": 0.94,
      "imageKeys": ["users/abc123/receipts/550e8400/original/receipt_front.jpg"],
      "thumbnailKeys": ["users/abc123/receipts/550e8400/thumbnail/receipt_front.jpg"],
      "storageMode": "cloud",
      "status": "active",
      "isFavorite": true,
      "userEditedFields": ["category", "notes"],
      "serverVersion": 2,
      "clientVersion": 2,
      "createdAt": "2026-02-05T14:30:01.000Z",
      "serverUpdatedAt": "2026-02-08T09:15:01.000Z",
      "clientUpdatedAt": "2026-02-06T09:15:00.000Z"
    },
    {
      "receiptId": "661f9500-f30c-52e5-b827-557766551111",
      "status": "deleted",
      "deletedAt": "2026-02-08T10:00:00.000Z",
      "serverVersion": 3,
      "serverUpdatedAt": "2026-02-08T10:00:00.000Z"
    }
  ],
  "newSyncTimestamp": "2026-02-08T10:00:01.000Z",
  "hasMore": false,
  "nextCursor": null,
  "count": 2
}
```

| Field | Type | Description |
|-------|------|-------------|
| items | Array | All receipts (including categories metadata) that have changed since `lastSyncTimestamp`. Deleted items are included with `status: "deleted"` so the client can remove them locally. |
| newSyncTimestamp | String (ISO 8601) | The timestamp the client should store and send as `lastSyncTimestamp` in its next sync pull. This is the `serverUpdatedAt` of the most recently modified item in the response, plus 1 millisecond. |
| hasMore | Boolean | Whether there are additional changed items beyond this page |
| nextCursor | String or null | If `hasMore` is true, this cursor is used to fetch the next page of changes |
| count | Integer | Number of items in this response page |

**Error Cases**

| Error Code | Condition |
|------------|-----------|
| VALIDATION_ERROR | lastSyncTimestamp is missing or not a valid ISO 8601 timestamp |

**Notes**

- This endpoint queries GSI-6 (ByUpdatedAt) with `PK = USER#<userId>` and `SK > lastSyncTimestamp`. GSI-6 is configured with KEYS_ONLY projection, so the Lambda function performs a batch GetItem to retrieve full item data for all matching keys. This is more cost-effective than projecting all attributes into GSI-6 for infrequent delta sync queries.
- Deleted items are included in the response with their status set to "deleted" and minimal fields populated. This allows the client to remove or flag them locally.
- The `newSyncTimestamp` is calculated as the maximum `serverUpdatedAt` value across all returned items, plus 1 millisecond, to ensure no items are missed or double-counted.
- If the client has been offline for an extended period and there are many changed items, multiple paginated requests may be needed. The client should continue calling with the returned `nextCursor` until `hasMore` is false.
- The sync pull also returns category changes. If the user's `META#CATEGORIES` item has been updated since `lastSyncTimestamp`, it is included in the items array with a special marker.

---

### 12. POST /sync/push

**Batch Push**

The client sends an array of locally modified receipts to the server. The server applies each change using the field-level merge conflict resolution algorithm and returns per-item results indicating whether each change was accepted, merged, or conflicted.

**Request Body**

```json
{
  "items": [
    {
      "receiptId": "550e8400-e29b-41d4-a716-446655440000",
      "merchantName": "IKEA Greece",
      "purchaseDate": "2026-02-05",
      "totalAmount": 149.99,
      "currency": "EUR",
      "category": "Home & Furniture",
      "warrantyMonths": 24,
      "warrantyExpiryDate": "2028-02-05",
      "items": [
        {
          "name": "KALLAX Shelf Unit",
          "quantity": 1,
          "price": 149.99
        }
      ],
      "notes": "For home office - white color",
      "tags": ["office", "furniture", "white"],
      "ocrRawText": "IKEA GREECE\n...",
      "llmConfidence": 0.94,
      "imageKeys": ["users/abc123/receipts/550e8400/original/receipt_front.jpg"],
      "status": "active",
      "isFavorite": true,
      "userEditedFields": ["category", "notes"],
      "serverVersion": 1,
      "clientVersion": 3,
      "clientUpdatedAt": "2026-02-08T08:00:00.000Z"
    }
  ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| items | Array | Yes | Array of receipt objects with their full current local state. Maximum 25 items per batch. |
| items[].serverVersion | Integer | Yes | The server version the client last synced for this item. 0 if the item was created offline and never synced. |

**Response** (200 OK)

```json
{
  "results": [
    {
      "receiptId": "550e8400-e29b-41d4-a716-446655440000",
      "outcome": "merged",
      "serverVersion": 4,
      "serverUpdatedAt": "2026-02-08T10:30:00.000Z",
      "mergedFields": {
        "category": {
          "clientValue": "Home & Furniture",
          "serverValue": "Furniture",
          "resolvedValue": "Home & Furniture",
          "winner": "client",
          "reason": "Field in userEditedFields — Tier 3, client override precedence"
        },
        "llmConfidence": {
          "clientValue": 0.94,
          "serverValue": 0.97,
          "resolvedValue": 0.97,
          "winner": "server",
          "reason": "Tier 1 field — server/LLM wins"
        }
      }
    }
  ],
  "syncTimestamp": "2026-02-08T10:30:00.000Z"
}
```

| Field | Type | Description |
|-------|------|-------------|
| results | Array | Per-item result objects |
| results[].receiptId | String | The receipt identifier |
| results[].outcome | String | "accepted" (no conflict, client version applied as-is), "merged" (conflicts resolved automatically using field-level merge), or "conflict" (unresolvable conflict requiring user intervention) |
| results[].serverVersion | Integer | The new server version after applying the change |
| results[].serverUpdatedAt | String (ISO 8601) | Server timestamp of the applied change |
| results[].mergedFields | Object | Present only when outcome is "merged". Details which fields had conflicting values and how they were resolved. |
| syncTimestamp | String (ISO 8601) | Timestamp the client should use as the baseline for subsequent operations |

**Outcome Values**

| Outcome | Meaning | Client Action |
|---------|---------|---------------|
| accepted | No conflict. Server version matched client's expectation. Client data applied directly. | Update local serverVersion. No further action. |
| merged | Server version did not match, but conflicts were automatically resolved using field-level merge with ownership tiers. | Apply the merged result locally, update serverVersion. Review mergedFields if desired. |
| conflict | Automatic merge was not possible (extremely rare in practice -- e.g., both sides modified the same Tier 3 field and neither side was clearly the owner). | Present conflict to user for manual resolution, then re-push. |

**Error Cases**

| Error Code | Condition |
|------------|-----------|
| VALIDATION_ERROR | Request body fails validation (e.g., items is not an array, exceeds 25 items) |
| MISSING_REQUIRED_FIELD | An item is missing required fields (receiptId, serverVersion, clientVersion) |

**Notes**

- The batch size limit is 25 items per request. If the client has more than 25 locally modified receipts, it must split them into multiple push requests.
- The field-level merge algorithm consults the conflict resolution tiers defined in the data model:
  - Tier 1 (Server/LLM wins): `merchantName` (extracted), `purchaseDate` (extracted), `totalAmount` (extracted), `ocrRawText`, `llmConfidence` -- these fields are best determined by the LLM and should not be overridden by stale client values.
  - Tier 2 (Client/User wins): `notes`, `tags`, `isFavorite` -- these are purely user-generated and the client is always authoritative.
  - Tier 3 (Client override with tracking): `merchantName` (display), `category`, `warrantyMonths` -- if the field name appears in the item's `userEditedFields` array, the client value wins. Otherwise, the server value wins.
- Items with `serverVersion: 0` are treated as new creations. The server performs a conditional PutItem to ensure no duplicate exists.
- The server processes items sequentially within a single batch to maintain consistency. DynamoDB transactions are used for batches of 3 or fewer items; larger batches use individual conditional writes with rollback logic.

---

### 13. POST /sync/full

**Full Reconciliation**

Returns all of the user's receipt records (paginated), regardless of modification timestamp. This endpoint is used as a safety net to catch any items that may have been missed by delta sync due to clock skew, missed push notifications, or other edge cases. The client performs a full reconciliation every 7 days and on the very first sync after app installation.

**Request Body**

```json
{
  "limit": 100,
  "cursor": null
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| limit | Integer | No | Items per page (default 100, max 200) |
| cursor | String | No | Pagination cursor from previous response |

**Response** (200 OK)

```json
{
  "items": [
    {
      "receiptId": "...",
      "merchantName": "...",
      "...": "..."
    }
  ],
  "nextCursor": "eyJQSyI6Ii4uLiIsIlNLIjoiLi4uIn0=",
  "hasMore": true,
  "count": 100,
  "totalCount": 342,
  "syncTimestamp": "2026-02-08T10:30:00.000Z"
}
```

| Field | Type | Description |
|-------|------|-------------|
| items | Array | All user receipts (full detail, same schema as delta sync items) |
| nextCursor | String or null | Pagination cursor if more items exist |
| hasMore | Boolean | Whether more pages are available |
| count | Integer | Number of items in this page |
| totalCount | Integer | Total number of receipts for the user (included only in the first page) |
| syncTimestamp | String (ISO 8601) | The timestamp to use as `lastSyncTimestamp` for subsequent delta sync pulls |

**Error Cases**

| Error Code | Condition |
|------------|-----------|
| INVALID_CURSOR | Cursor is malformed |

**Notes**

- This endpoint queries the main table using `PK = USER#<userId>` with `SK begins_with RECEIPT#`. It retrieves all receipts regardless of status (including soft-deleted items).
- The `totalCount` value is obtained from a separate Count query and is included only in the first page of results. It provides the client with a progress indicator for the full reconciliation.
- Full reconciliation is expensive relative to delta sync and should be used sparingly. The client schedules it every 7 days as a safety net, not as the primary sync mechanism.
- During full reconciliation, the client compares every server item against its local database, identifying any discrepancies. Items present on the server but missing locally are downloaded. Items present locally but missing from the server (and not in "pending push" status) are flagged for resolution.
- The `syncTimestamp` in the response becomes the client's new `lastSyncTimestamp` for subsequent delta sync pulls, effectively resetting the delta sync baseline.

---

## Category Endpoints

### 14. GET /categories

**Get User's Categories**

Returns the complete list of categories available to the user, including the 10 default categories and any custom categories the user has created.

**Response** (200 OK)

```json
{
  "defaults": [
    "Electronics",
    "Clothing & Accessories",
    "Groceries",
    "Home & Furniture",
    "Health & Beauty",
    "Entertainment",
    "Automotive",
    "Dining & Food",
    "Office & Stationery",
    "Other"
  ],
  "custom": [
    "Baby & Kids",
    "Pet Supplies",
    "Home Renovation"
  ],
  "updatedAt": "2026-02-05T12:00:00.000Z",
  "serverVersion": 2
}
```

| Field | Type | Description |
|-------|------|-------------|
| defaults | Array of strings | The 10 built-in default categories. These are the same for all users and cannot be modified or deleted. |
| custom | Array of strings | User-created custom categories. These are stored in DynamoDB as the `META#CATEGORIES` item for the user. |
| updatedAt | String (ISO 8601) | Last modification timestamp of the custom categories |
| serverVersion | Integer | Version counter for conflict detection during sync |

**Error Cases**

This endpoint has no specific error cases beyond authentication failure. It always returns a result, even for new users (who will have an empty `custom` array).

**Notes**

- The default categories are hardcoded in the Lambda function and returned as part of every response. They are not stored in DynamoDB.
- Categories are stored in DynamoDB with `PK = USER#<userId>` and `SK = META#CATEGORIES`.
- Category names are case-sensitive. The client should normalize category names (e.g., title case) before display.

---

### 15. PUT /categories

**Update Custom Categories**

Replaces the user's entire custom category list. This is a full replacement, not an append operation. The client sends the complete desired list of custom categories.

**Request Body**

```json
{
  "custom": [
    "Baby & Kids",
    "Pet Supplies",
    "Home Renovation",
    "Travel"
  ],
  "serverVersion": 2
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| custom | Array of strings | Yes | Complete list of custom categories. Maximum 50 categories. Each category name must be between 1 and 50 characters. |
| serverVersion | Integer | Yes | Current server version for optimistic concurrency |

**Response** (200 OK)

```json
{
  "custom": [
    "Baby & Kids",
    "Pet Supplies",
    "Home Renovation",
    "Travel"
  ],
  "updatedAt": "2026-02-08T11:00:00.000Z",
  "serverVersion": 3
}
```

**Error Cases**

| Error Code | Condition |
|------------|-----------|
| VALIDATION_ERROR | custom is not an array of strings, or contains empty/invalid strings |
| CATEGORY_LIMIT_EXCEEDED | The custom array contains more than 50 categories |
| VERSION_CONFLICT | Server version mismatch |

**Notes**

- This is a full replacement operation. To add a category, the client must first GET the current list, append the new category, and PUT the full list back. To remove a category, the client omits it from the list.
- Removing a category from this list does not affect existing receipts assigned to that category. The receipts retain their category assignment; the category simply no longer appears as a suggestion in the UI.
- Default categories cannot be modified through this endpoint. They are always returned unchanged by GET /categories.
- The `serverVersion` field is used for optimistic concurrency. If the user updates categories on multiple devices simultaneously, the second update will fail with VERSION_CONFLICT.

---

## Warranty Endpoints

### 16. GET /warranties/expiring

**Get Expiring Warranties**

Returns receipts with warranties expiring within a specified number of days. This endpoint powers the "Expiring" tab in the app's bottom navigation.

**Query Parameters**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| days | Integer | No | 30 | Return warranties expiring within this many days from today. Minimum 1, maximum 365. |
| limit | Integer | No | 20 | Items per page (max 100) |
| cursor | String | No | null | Pagination cursor |

**Response** (200 OK)

```json
{
  "items": [
    {
      "receiptId": "550e8400-e29b-41d4-a716-446655440000",
      "merchantName": "IKEA Greece",
      "purchaseDate": "2026-02-05",
      "totalAmount": 149.99,
      "currency": "EUR",
      "category": "Furniture",
      "warrantyMonths": 24,
      "warrantyExpiryDate": "2028-02-05",
      "daysRemaining": 727,
      "items": [
        {
          "name": "KALLAX Shelf Unit",
          "quantity": 1,
          "price": 149.99
        }
      ],
      "thumbnailKeys": ["users/abc123/receipts/550e8400/thumbnail/receipt_front.jpg"],
      "status": "active"
    }
  ],
  "nextCursor": null,
  "count": 1
}
```

The response includes a computed `daysRemaining` field that is not stored in DynamoDB but calculated server-side at query time.

**Error Cases**

| Error Code | Condition |
|------------|-----------|
| VALIDATION_ERROR | days is less than 1 or greater than 365 |

**Notes**

- This endpoint queries GSI-4 (ByWarrantyExpiry) with `PK = USER#<userId>#ACTIVE` and `SK between today and today + days`. GSI-4 is a sparse index that only contains items with an active warranty, making the query efficient.
- Results are sorted by warranty expiry date ascending (soonest expiration first) to prioritize urgency.
- Only receipts with status "active" and a non-null, future warranty expiry date are included. Returned, archived, or deleted receipts are excluded.
- The `daysRemaining` field is computed as the number of calendar days between today (UTC) and the `warrantyExpiryDate`. It is always a non-negative integer (items with expired warranties are not returned by this endpoint).
- This endpoint returns a subset of receipt fields optimized for the "Expiring" tab display. Full receipt detail can be obtained via GET /receipts/{receiptId}.

---

## User and Account Endpoints

### 17. GET /user/profile

**Get User Profile**

Returns the authenticated user's profile information, including Cognito identity details and app-specific settings.

**Response** (200 OK)

```json
{
  "userId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "email": "user@example.com",
  "emailVerified": true,
  "signInProvider": "Google",
  "settings": {
    "defaultCurrency": "EUR",
    "language": "en",
    "reminderDaysBefore": [30, 7, 1],
    "storageMode": "cloud",
    "biometricEnabled": false,
    "weeklyDigestEnabled": true
  },
  "stats": {
    "totalReceipts": 42,
    "activeWarranties": 8,
    "totalWarrantyValue": 3420.50
  },
  "createdAt": "2026-01-15T10:00:00.000Z",
  "lastSyncAt": "2026-02-08T09:00:00.000Z"
}
```

| Field | Type | Description |
|-------|------|-------------|
| userId | String | Cognito `sub` claim (UUID) |
| email | String | User's email address |
| emailVerified | Boolean | Whether the email has been verified |
| signInProvider | String | "Email", "Google", or "Apple" |
| settings | Object | User's app settings (see PUT /user/settings) |
| stats | Object | Computed statistics about the user's vault |
| stats.totalReceipts | Integer | Total number of active (non-deleted) receipts |
| stats.activeWarranties | Integer | Number of receipts with unexpired warranties |
| stats.totalWarrantyValue | Number | Sum of totalAmount for all receipts with active warranties |
| createdAt | String (ISO 8601) | Account creation timestamp |
| lastSyncAt | String (ISO 8601) | Timestamp of the user's most recent successful sync operation |

**Error Cases**

This endpoint has no specific error cases beyond authentication failure. It always returns a result for authenticated users.

**Notes**

- The `stats` object is computed at query time from DynamoDB, not cached. For v1 scale (hundreds of receipts per user), this is acceptable. If performance becomes a concern at larger scale, stats can be pre-computed and cached.
- The `signInProvider` is determined from the Cognito identity attributes (`cognito:username` prefix or identity provider link data).
- User settings are stored in DynamoDB with `PK = USER#<userId>` and `SK = META#SETTINGS`. If no settings record exists (new user), default values are returned.

---

### 18. PUT /user/settings

**Update User Settings**

Updates the user's app-wide settings. This is a full replacement of the settings object.

**Request Body**

```json
{
  "defaultCurrency": "EUR",
  "language": "el",
  "reminderDaysBefore": [30, 7, 1],
  "storageMode": "cloud",
  "biometricEnabled": true,
  "weeklyDigestEnabled": true
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| defaultCurrency | String (ISO 4217) | Yes | Default currency for new receipts |
| language | String | Yes | App language: "en" or "el" |
| reminderDaysBefore | Array of integers | Yes | Days before warranty expiry to send reminders. Each value must be between 1 and 365. Maximum 5 reminder points. |
| storageMode | String | Yes | "cloud" (cloud + device sync) or "device_only" (local storage only, no cloud sync) |
| biometricEnabled | Boolean | Yes | Whether biometric/PIN lock is enabled (informational -- the actual lock is enforced client-side by local_auth) |
| weeklyDigestEnabled | Boolean | Yes | Whether to receive weekly warranty summary notifications |

**Response** (200 OK)

```json
{
  "settings": {
    "defaultCurrency": "EUR",
    "language": "el",
    "reminderDaysBefore": [30, 7, 1],
    "storageMode": "cloud",
    "biometricEnabled": true,
    "weeklyDigestEnabled": true
  },
  "updatedAt": "2026-02-08T11:30:00.000Z"
}
```

**Error Cases**

| Error Code | Condition |
|------------|-----------|
| VALIDATION_ERROR | Invalid field values (e.g., unsupported language, invalid currency) |
| INVALID_CURRENCY | defaultCurrency is not a valid ISO 4217 code |

**Notes**

- Changing `storageMode` from "cloud" to "device_only" does not trigger immediate deletion of cloud data. The user's data remains in DynamoDB and S3 but is no longer actively synced. The user can switch back to "cloud" mode at any time and resume syncing.
- Changing `storageMode` from "device_only" to "cloud" triggers a full sync push of all local data on the client side (the client initiates this, not the server).
- The `biometricEnabled` setting is stored server-side for sync purposes (so the preference carries across devices) but the actual biometric enforcement is handled entirely on the client by the `local_auth` Flutter package.
- The `reminderDaysBefore` array is used by the daily warranty-checker Lambda (EventBridge-triggered) to determine when to send push notifications for each user.

---

### 19. DELETE /user/account

**Delete User Account**

Permanently and irrecoverably deletes the user's account and all associated data across all AWS services. This is a hard delete with no recovery period. The operation requires a confirmation token to prevent accidental deletion.

**Request Body**

```json
{
  "confirmationToken": "DELETE-MY-ACCOUNT-a1b2c3d4"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| confirmationToken | String | Yes | A confirmation token previously obtained through the app's account deletion flow. The client generates this token by having the user type a specific confirmation phrase (e.g., "DELETE MY ACCOUNT") and combines it with a timestamp-based hash. |

**Response** (200 OK)

```json
{
  "status": "deletion_initiated",
  "message": "Account deletion has been initiated. All data will be permanently removed within 24 hours.",
  "deletionDetails": {
    "cognitoUser": "scheduled",
    "dynamoDbRecords": "scheduled",
    "s3Objects": "scheduled",
    "kmsKeyScheduled": false
  }
}
```

**Error Cases**

| Error Code | Condition |
|------------|-----------|
| DELETION_CONFIRMATION_REQUIRED | confirmationToken is missing from the request body |
| DELETION_CONFIRMATION_INVALID | The confirmationToken is invalid, expired, or does not match the expected format |

**Notes**

- Account deletion triggers the user-deletion Lambda, which performs the following cascade in order:
  1. **Cognito**: Deletes the user from the Cognito User Pool using the AdminDeleteUser API. This immediately invalidates all existing tokens and prevents future sign-in.
  2. **DynamoDB**: Performs a BatchWriteItem to delete all items with `PK = USER#<userId>`. This includes all receipt records and the META#CATEGORIES and META#SETTINGS items.
  3. **S3**: Lists and deletes all objects under the `users/<userId>/` prefix in the receipt images bucket. Because versioning is enabled, this includes deleting all object versions (delete markers and noncurrent versions) to ensure complete removal.
- KMS key destruction is not performed per-user because all users share the same Customer Managed Key. Per-user crypto-shredding via key deletion would require per-user KMS keys, which is not cost-effective at v1 scale. Instead, the physical deletion of all S3 objects and DynamoDB records provides equivalent data removal.
- The deletion process is designed to complete within minutes but the response conservatively states "within 24 hours" to account for potential DynamoDB throttling on large accounts or S3 eventual consistency delays.
- The confirmation token must be obtained through a client-side flow that requires deliberate user action. The token format is `DELETE-MY-ACCOUNT-<random8chars>` with a 5-minute expiry. The client generates the token locally and the server validates its format and freshness.
- This operation is irreversible. The server logs the deletion event (user ID, timestamp, item counts) to CloudWatch for audit purposes before deleting any data. No personally identifiable information is included in the audit log.

---

### 20. POST /user/export

**Request Full Data Export**

Initiates an asynchronous export of all the user's data (receipts, images, settings, and categories) into a downloadable ZIP file. The export is processed by a dedicated Lambda function and the user receives a push notification with a download link when the export is complete.

**Request Body**

```json
{
  "format": "json",
  "includeImages": true,
  "dateFrom": null,
  "dateTo": null
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| format | String | No | Export format for receipt data. Currently only "json" is supported. Future versions may support "csv" or "pdf". Defaults to "json". |
| includeImages | Boolean | No | Whether to include receipt images in the ZIP. Defaults to true. Setting to false produces a much smaller export. |
| dateFrom | String (ISO 8601 date) | No | If provided, only export receipts purchased on or after this date |
| dateTo | String (ISO 8601 date) | No | If provided, only export receipts purchased on or before this date |

**Response** (202 Accepted)

```json
{
  "exportId": "exp-7890abcd-1234-5678-efgh-ijklmnopqrst",
  "status": "processing",
  "estimatedCompletionMinutes": 5,
  "message": "Export initiated. You will receive a push notification when your data is ready for download."
}
```

**Error Cases**

| Error Code | Condition |
|------------|-----------|
| EXPORT_IN_PROGRESS | An export is already being processed for this user. Only one export can run at a time. |
| VALIDATION_ERROR | Invalid date range or unsupported format |

**Notes**

- The export-handler Lambda (1024 MB memory, 300-second timeout) performs the following:
  1. Queries DynamoDB for all user receipts (optionally filtered by date range).
  2. Serializes receipt data as JSON files (one per receipt, plus a summary index file).
  3. If `includeImages` is true, downloads all receipt images from S3 (originals, not thumbnails).
  4. Packages everything into a ZIP file.
  5. Uploads the ZIP to a temporary S3 location with a 7-day lifecycle expiration.
  6. Sends a push notification to the user's device via SNS with the pre-signed download URL.
- The temporary download URL expires after 24 hours. The ZIP file itself is deleted from S3 after 7 days via a lifecycle rule.
- For users with very large vaults (hundreds of receipts with images), the Lambda may approach its 300-second timeout. In this case, the Lambda writes partial progress to DynamoDB and is re-invoked via an SQS queue to continue from where it left off. The user sees a single push notification when the full export is complete.
- The export JSON format includes all receipt fields, making it suitable for import into other systems or for personal archival. The ZIP structure is:

```
export-2026-02-08/
  index.json              (summary: user info, receipt count, export date)
  receipts/
    550e8400.json         (individual receipt data)
    661f9500.json
    ...
  images/
    550e8400/
      receipt_front.jpg   (original image)
    661f9500/
      receipt_front.jpg
    ...
```

- This endpoint satisfies the GDPR right to data portability (Article 20).

---

## Webhook and Push Events

The server communicates asynchronous events to the client through push notifications delivered via Amazon SNS (which routes to FCM for Android and APNs for iOS). These are not HTTP webhooks -- they are mobile push notifications that the client app receives and processes.

### Event: receipt.refined

**LLM Refinement Complete**

Sent when the Bedrock Claude Haiku 4.5 (or Sonnet 4.5 fallback) has finished processing a receipt's OCR data and the refined structured data has been written to DynamoDB.

```json
{
  "event": "receipt.refined",
  "receiptId": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2026-02-08T10:30:05.000Z",
  "confidence": 0.94,
  "fieldsUpdated": ["merchantName", "purchaseDate", "totalAmount", "items", "warrantyMonths"]
}
```

**Client Action**: Trigger a delta sync pull to retrieve the updated receipt data. Display an optional in-app notification that refinement is complete.

---

### Event: warranty.expiring

**Warranty Expiring Soon**

Sent by the daily warranty-checker Lambda when a receipt's warranty expiry date falls within the user's configured reminder window (default: 30, 7, and 1 day before expiry).

```json
{
  "event": "warranty.expiring",
  "receiptId": "550e8400-e29b-41d4-a716-446655440000",
  "merchantName": "IKEA Greece",
  "itemName": "KALLAX Shelf Unit",
  "warrantyExpiryDate": "2028-02-05",
  "daysRemaining": 7,
  "timestamp": "2026-01-29T08:00:00.000Z"
}
```

**Client Action**: Display a system notification with the warranty details. Tapping the notification opens the receipt detail screen. This notification is also generated locally by `flutter_local_notifications` as a backup in case the push notification is not received (e.g., when the device is offline).

---

### Event: export.ready

**Data Export Ready for Download**

Sent when the export-handler Lambda has finished packaging the user's data and the ZIP file is ready for download.

```json
{
  "event": "export.ready",
  "exportId": "exp-7890abcd-1234-5678-efgh-ijklmnopqrst",
  "downloadUrl": "https://receiptvault-exports-prod.s3.eu-west-1.amazonaws.com/exports/a1b2c3d4/export-2026-02-08.zip?X-Amz-Algorithm=...",
  "expiresAt": "2026-02-09T10:30:00.000Z",
  "fileSizeMb": 45.2,
  "receiptCount": 42,
  "timestamp": "2026-02-08T10:35:00.000Z"
}
```

**Client Action**: Display a notification informing the user that their export is ready. Provide a "Download" action that opens the download URL in the system browser or triggers an in-app download.

---

### Event: warranty.weekly_summary

**Weekly Warranty Status Summary**

Sent every Monday at 9 AM UTC by the weekly-summary Lambda. Provides a digest of the user's warranty status for the coming week.

```json
{
  "event": "warranty.weekly_summary",
  "summary": {
    "expiringThisWeek": 1,
    "expiringThisMonth": 3,
    "totalActiveWarranties": 8,
    "totalWarrantyValue": 3420.50,
    "currency": "EUR",
    "soonestExpiry": {
      "receiptId": "772a0600-g41d-63f6-c938-668877662222",
      "merchantName": "Plaisio",
      "itemName": "Wireless Mouse",
      "daysRemaining": 3
    }
  },
  "timestamp": "2026-02-09T09:00:00.000Z"
}
```

**Client Action**: Display a notification with the summary headline (e.g., "1 warranty expiring this week, 3 this month"). Tapping the notification opens the "Expiring" tab.

**Notes**

- Weekly summaries are only sent to users who have `weeklyDigestEnabled: true` in their settings (default: true).
- If the user has no active warranties, no summary notification is sent.

---

## Common Data Structures

### Receipt Object (Full)

This is the complete receipt representation returned by detail endpoints and sync operations.

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| receiptId | String (UUID) | No | Unique identifier (client-generated) |
| merchantName | String | Yes | Store or merchant name |
| purchaseDate | String (ISO 8601 date) | Yes | Date of purchase |
| totalAmount | Number | Yes | Total receipt amount (2 decimal precision) |
| currency | String (ISO 4217) | Yes | Three-letter currency code |
| category | String | Yes | Category name |
| warrantyMonths | Integer | Yes | Warranty duration in months |
| warrantyExpiryDate | String (ISO 8601 date) | Yes | Calculated warranty expiry date |
| items | Array | Yes | Line items |
| items[].name | String | No | Item description |
| items[].quantity | Integer | Yes | Quantity (defaults to 1) |
| items[].price | Number | Yes | Item price (2 decimal precision) |
| notes | String | Yes | User-added notes |
| tags | Array of strings | Yes | User-added tags |
| ocrRawText | String | Yes | Raw OCR text from on-device extraction |
| llmConfidence | Number (0-1) | Yes | LLM extraction confidence score |
| imageKeys | Array of strings | Yes | S3 object keys for original images |
| thumbnailKeys | Array of strings | Yes | S3 object keys for thumbnails (server-populated) |
| storageMode | String | No | "cloud" or "device_only" |
| status | String | No | "active", "returned", "archived", or "deleted" |
| isFavorite | Boolean | No | Whether marked as favorite |
| userEditedFields | Array of strings | Yes | Fields manually edited by user (for conflict resolution) |
| serverVersion | Integer | No | Server-side version counter |
| clientVersion | Integer | No | Client-side version counter |
| createdAt | String (ISO 8601) | No | Server-side creation timestamp |
| serverUpdatedAt | String (ISO 8601) | No | Server-side last modification timestamp |
| clientUpdatedAt | String (ISO 8601) | No | Client-side last modification timestamp |
| deletedAt | String (ISO 8601) | Yes | Timestamp of soft deletion (only present when status is "deleted") |

### Receipt Object (Summary)

A reduced representation used in list endpoints to minimize payload size. Excludes `ocrRawText`, `llmConfidence`, `userEditedFields`, `clientVersion`, and `clientUpdatedAt`.

### Settings Object

| Field | Type | Description |
|-------|------|-------------|
| defaultCurrency | String (ISO 4217) | Default currency for new receipts |
| language | String | "en" or "el" |
| reminderDaysBefore | Array of integers | Days before warranty expiry to remind |
| storageMode | String | "cloud" or "device_only" |
| biometricEnabled | Boolean | Biometric lock preference (enforced client-side) |
| weeklyDigestEnabled | Boolean | Whether to receive weekly warranty summaries |

### Error Object

| Field | Type | Description |
|-------|------|-------------|
| error.code | String | Machine-readable error code (uppercase, underscores) |
| error.message | String | Human-readable error description |

---

*This document is part of the Receipt & Warranty Vault documentation suite. For related documents, see the [docs directory listing](../CLAUDE.md#documentation-files).*
