# 08 -- AWS Infrastructure

**Document**: AWS Infrastructure Specification
**Version**: 1.0
**Status**: Pre-Implementation (Documentation Phase)
**Last Updated**: 2026-02-08

---

## Table of Contents

1. [Overview](#overview)
2. [AWS Account Setup](#aws-account-setup)
3. [Amazon Cognito](#amazon-cognito)
4. [Amazon API Gateway](#amazon-api-gateway)
5. [AWS Lambda](#aws-lambda)
6. [Amazon DynamoDB](#amazon-dynamodb)
7. [Amazon S3](#amazon-s3)
8. [AWS KMS](#aws-kms)
9. [Amazon CloudFront](#amazon-cloudfront)
10. [Amazon SNS](#amazon-sns)
11. [Amazon EventBridge](#amazon-eventbridge)
12. [Amazon Bedrock](#amazon-bedrock)
13. [Amazon CloudWatch](#amazon-cloudwatch)
14. [IAM Roles and Policies](#iam-roles-and-policies)
15. [Cost Estimate](#cost-estimate)
16. [Infrastructure as Code](#infrastructure-as-code)

---

## Overview

Receipt & Warranty Vault runs on a fully serverless AWS architecture. Every component is pay-per-use with no fixed infrastructure costs, no servers to manage, and no capacity planning required at v1 scale. The architecture is designed to cost approximately $2/month during the 5-person testing phase and scale gracefully to approximately $88/month at 1,000 users without any architectural changes.

All resources are deployed in a single AWS region (eu-west-1, Ireland) to comply with GDPR data residency requirements and provide low latency to the initial EU-focused user base. Multi-region deployment is deferred to v2.

The infrastructure consists of 12 AWS services working together: Cognito for authentication, API Gateway for HTTP routing, Lambda for compute, DynamoDB for structured data, S3 for image storage, KMS for encryption key management, CloudFront for image delivery, SNS for push notifications, EventBridge for scheduled jobs, Bedrock for LLM processing, CloudWatch for monitoring, and IAM for access control.

---

## AWS Account Setup

### Account Structure

The v1 deployment uses a single AWS account for all environments and resources. A multi-account strategy (separate accounts for development, staging, and production using AWS Organizations) is deferred to post-launch when the operational complexity justifies the overhead.

| Setting | Value | Rationale |
|---------|-------|-----------|
| Account type | Single account | Simplicity for v1; 5 testers do not justify multi-account overhead |
| Region | eu-west-1 (Ireland) | GDPR compliance, low latency to EU users, full service availability |
| Multi-region | Deferred to v2 | Single region sufficient for global audience at v1 scale |
| Environment separation | Resource naming + tags (e.g., `prod` prefix) | Logical separation within single account |

### Region Selection: eu-west-1 (Ireland)

The Ireland region was chosen for the following reasons:

1. **GDPR Compliance**: All user data resides within the European Union, satisfying GDPR data residency expectations for EU users. GDPR is applied globally to all users regardless of location, so hosting in the EU provides the strongest compliance posture.

2. **Service Availability**: eu-west-1 is one of AWS's oldest and most complete regions. All services required by the application are available, including Bedrock with Claude model access (to be verified at deployment time -- see the Bedrock section for fallback strategy).

3. **Latency**: The initial user base is centered in Greece and broader Europe. Ireland provides sub-50ms latency to most European locations. Users in other regions (Americas, Asia) will experience acceptable latency (100-200ms) for an API that is not latency-critical (the app is offline-first and sync is asynchronous).

4. **Cost**: eu-west-1 pricing is competitive with US regions and identical for most services used in this architecture.

### Global Audience Strategy

The app serves a global audience from the single eu-west-1 region. This is acceptable because:

- The app is offline-first: users interact with the local Drift database for all primary operations. Cloud API calls are for sync, image upload/download, and LLM refinement -- none of which are latency-sensitive.
- CloudFront provides edge caching for thumbnail images, reducing perceived latency for image loading globally.
- Multi-region deployment (DynamoDB Global Tables, S3 Cross-Region Replication, multi-region API Gateway) is a v2 capability that will be introduced if the user base expands significantly beyond Europe.

---

## Amazon Cognito

### User Pool Configuration

Amazon Cognito provides authentication and user management for the application. The Lite tier is used, which is free for up to 10,000 monthly active users (MAUs).

| Setting | Value |
|---------|-------|
| Tier | Lite ($0/month up to 10,000 MAUs) |
| User Pool name | receiptvault-user-pool-prod |
| Sign-in identifiers | Email address (primary) |
| Social identity providers | Google Sign-In, Apple Sign-In |
| Client SDK | Amplify Flutter Gen 2 |
| Self-service sign-up | Enabled |
| Email verification | Required (Cognito sends verification code) |

### Authentication Methods

Three sign-in methods are supported in v1:

1. **Email and Password**: Standard Cognito user pool authentication. The user registers with an email address and password, verifies their email via a 6-digit code sent by Cognito's built-in email service, and signs in with their credentials.

2. **Google Sign-In**: OAuth 2.0 federated identity through Google. Configured as an external identity provider on the Cognito User Pool. The Amplify Flutter Gen 2 SDK handles the OAuth flow, including the redirect URI and token exchange. The user's Google email is mapped to the Cognito user record.

3. **Apple Sign-In**: OAuth 2.0 federated identity through Apple. Required by Apple's App Store guidelines whenever a third-party social sign-in option (Google) is offered on iOS. Configured similarly to Google as an external identity provider on the User Pool. Apple's email relay (private email) is supported.

### Token Configuration

| Token | Lifetime | Notes |
|-------|----------|-------|
| Access token | 1 hour | Used in Authorization header for API calls. Short lifetime limits exposure if compromised. |
| ID token | 1 hour | Contains user claims (email, sub). Used by client for display purposes, not for API authentication. |
| Refresh token | 30 to 90 days | Used to obtain new access/ID tokens without re-authentication. Amplify SDK handles refresh transparently. Exact lifetime set to 30 days initially, extended based on user feedback. |

The Amplify Flutter Gen 2 SDK manages token lifecycle automatically. When the access token expires, the SDK uses the refresh token to obtain a new access token without any user-visible interruption. The Dio HTTP client on the Flutter side includes an interceptor that detects 401 responses, triggers Amplify token refresh, and retries the failed request with the new token.

### Password Policy

| Requirement | Value |
|-------------|-------|
| Minimum length | 8 characters |
| Uppercase letter | Required (at least one) |
| Lowercase letter | Required (at least one) |
| Number | Required (at least one) |
| Special character | Required (at least one from: `^ $ * . [ ] { } ( ) ? - " ! @ # % & / \ , > < ' : ; _ ~ \` + =`) |
| Temporary password validity | 7 days |

### Multi-Factor Authentication (MFA)

| Setting | Value |
|---------|-------|
| MFA enforcement | Optional (user can enable in settings, not required) |
| MFA method | TOTP (Time-based One-Time Password via authenticator app) |
| SMS MFA | Not configured (TOTP is more secure and avoids SMS costs) |

MFA is not enforced in v1 to minimize onboarding friction for the 5-person testing team. The infrastructure supports enabling MFA enforcement later without migration.

### Amplify Flutter Gen 2 Integration

The client app uses the Amplify Flutter Gen 2 SDK (`amplify_auth_cognito` package) for all authentication operations. Gen 2 is the current-generation Amplify SDK that uses the Cognito User Pool directly (no Identity Pool required for this use case). The SDK provides:

- Sign-up with email verification
- Sign-in with email/password
- Social sign-in (Google, Apple) with OAuth redirect handling
- Automatic token management (storage, refresh, injection)
- Sign-out (local and global)
- Password reset flow
- MFA enrollment and verification (when the user opts in)

The Amplify configuration is generated during project setup and stored in `amplifyconfiguration.dart` (not committed to version control -- treated as a build-time configuration).

---

## Amazon API Gateway

### API Type and Configuration

A REST API (not HTTP API) is used because it provides features required by the application that HTTP APIs do not support.

| Setting | Value | Rationale |
|---------|-------|-----------|
| API type | REST API | Cognito authorizer integration, request validation, usage plans |
| API name | receiptvault-api-prod |
| Stage | prod | Single stage for v1 |
| Protocol | HTTPS (TLS 1.2+) | Enforced by API Gateway default |
| Endpoint type | Regional | eu-west-1 only |

### Why REST API Instead of HTTP API

HTTP API (v2) is newer, cheaper, and faster, but lacks three features required by this application:

1. **Cognito User Pool Authorizer**: REST API supports native Cognito User Pool authorizers that validate JWT tokens and extract claims automatically. HTTP API supports JWT authorizers but requires more manual configuration for Cognito-specific claim extraction.

2. **Request Validation**: REST API supports request body validation against JSON Schema models at the API Gateway level, rejecting malformed requests before they reach Lambda. This reduces Lambda invocations and improves error consistency.

3. **Usage Plans and API Keys**: REST API supports per-user throttling via usage plans, which provides the per-user rate limiting described in the API design. HTTP API only supports route-level throttling, not per-user.

The cost difference is minimal at v1 scale (REST API: $3.50/million requests vs HTTP API: $1.00/million requests). At 5 users, total API Gateway cost is within the free tier.

### Cognito Authorizer

A Cognito User Pool authorizer is attached to every API endpoint (except health check, if one is added).

| Setting | Value |
|---------|-------|
| Authorizer name | receiptvault-cognito-authorizer |
| Authorizer type | COGNITO_USER_POOLS |
| User Pool | receiptvault-user-pool-prod |
| Token source | Authorization header |
| Token validation | Access token (`aud` claim must match User Pool App Client ID) |

The authorizer validates the JWT signature, expiry, and audience claim. If validation fails, API Gateway returns 401 before the Lambda function is invoked, saving compute cost and providing consistent error handling.

### Throttling and Rate Limiting

| Setting | Value |
|---------|-------|
| Default method throttle (steady state) | 10 requests per second |
| Default method throttle (burst) | 100 requests |
| Per-user throttling | Enabled via usage plan keyed on `context.authorizer.claims.sub` |
| Account-level throttle | 1,000 requests per second (API Gateway regional default) |

Rate limiting protects the backend from abuse and ensures fair usage across users. The limits are generous for individual use (a single user performing normal operations will never approach 10 requests per second) but prevent runaway sync loops or automated abuse.

### Custom Domain

| Setting | Value |
|---------|-------|
| Domain name | api.receiptvault.app |
| Certificate | ACM certificate in eu-west-1 for *.receiptvault.app |
| DNS | Route 53 CNAME/ALIAS record pointing to API Gateway domain |
| Base path | /v1 |

The custom domain is configured after domain registration and DNS setup. During development and early testing, the auto-generated API Gateway URL (`https://{api-id}.execute-api.eu-west-1.amazonaws.com/prod`) is used directly.

### CORS Configuration

CORS is configured on API Gateway to support the mobile app's HTTP client. While native mobile apps do not typically enforce CORS (that is a browser security mechanism), configuring CORS properly ensures compatibility if a web client is added in the future and prevents issues with any browser-based development tools.

| Setting | Value |
|---------|-------|
| Allowed origins | `*` (mobile app does not send Origin header; permissive for development) |
| Allowed methods | GET, POST, PUT, PATCH, DELETE, OPTIONS |
| Allowed headers | Content-Type, Authorization, X-Amz-Date, X-Api-Key, X-Amz-Security-Token |
| Max age | 3600 seconds |

---

## AWS Lambda

### Runtime and General Configuration

All Lambda functions use Python 3.12 runtime. Python was chosen for its first-class Bedrock SDK support (boto3), simple JSON processing, fast cold start times at the configured memory levels, and the team's familiarity with the language.

| Setting | Value |
|---------|-------|
| Runtime | Python 3.12 |
| Architecture | arm64 (Graviton2) -- 20% cheaper and faster cold starts |
| Deployment package | ZIP file (or container image if dependencies exceed 250 MB) |
| Layer | Shared layer for common utilities (DynamoDB helpers, response formatting, error handling) |

### Lambda Functions

#### 1. receipt-crud

| Setting | Value |
|---------|-------|
| Function name | receiptvault-receipt-crud-prod |
| Purpose | Handles all CRUD operations for receipt records in DynamoDB |
| Trigger | API Gateway (POST, GET, PUT, DELETE, PATCH on /receipts endpoints) |
| Memory | 256 MB |
| Timeout | 10 seconds |
| Concurrency | Unreserved (uses account default) |
| Environment variables | TABLE_NAME, REGION |

This function handles the following API endpoints:
- POST /receipts (create receipt)
- GET /receipts (list receipts with filtering and pagination)
- GET /receipts/{receiptId} (get single receipt)
- PUT /receipts/{receiptId} (full update with version checking)
- DELETE /receipts/{receiptId} (soft delete)
- POST /receipts/{receiptId}/restore (restore soft-deleted)
- PATCH /receipts/{receiptId}/status (update status)

The function extracts the userId from the API Gateway event context, constructs the appropriate DynamoDB query or write operation, and returns the formatted response. All write operations use DynamoDB conditional expressions for optimistic concurrency control.

#### 2. ocr-refine

| Setting | Value |
|---------|-------|
| Function name | receiptvault-ocr-refine-prod |
| Purpose | Invokes Bedrock Claude Haiku 4.5 to refine on-device OCR output into structured receipt data |
| Trigger | API Gateway (POST /receipts/{receiptId}/refine) |
| Memory | 512 MB |
| Timeout | 30 seconds |
| Concurrency | Unreserved |
| Environment variables | TABLE_NAME, REGION, BEDROCK_MODEL_ID, BEDROCK_FALLBACK_MODEL_ID, S3_BUCKET, CONFIDENCE_THRESHOLD |

This function performs the following sequence:
1. Validates the receipt exists and belongs to the authenticated user.
2. Retrieves the receipt image from S3 if an imageKey is provided.
3. Constructs a structured prompt with the OCR raw text (and optionally the image in base64) for Claude Haiku 4.5.
4. Invokes the Bedrock InvokeModel API with the prompt.
5. Parses the LLM response into structured fields (merchant name, date, items, total, warranty).
6. If confidence is below the threshold (default 0.70), retries with Claude Sonnet 4.5 as fallback.
7. Updates the receipt in DynamoDB with the refined data, incrementing serverVersion.
8. Sends an SNS push notification to the user's device indicating refinement is complete.

The 512 MB memory allocation accommodates the Bedrock SDK and image processing. The 30-second timeout allows for Bedrock cold starts and multi-turn retry with fallback.

#### 3. sync-handler

| Setting | Value |
|---------|-------|
| Function name | receiptvault-sync-handler-prod |
| Purpose | Handles all sync operations: delta pull, batch push, and full reconciliation |
| Trigger | API Gateway (POST /sync/pull, POST /sync/push, POST /sync/full) |
| Memory | 512 MB |
| Timeout | 30 seconds |
| Concurrency | Unreserved |
| Environment variables | TABLE_NAME, REGION, MAX_BATCH_SIZE |

This is the most complex Lambda function in the application. It implements the custom sync engine's server-side logic:

- **Delta pull** (POST /sync/pull): Queries GSI-6 (ByUpdatedAt) for items modified after the client's last sync timestamp. Performs batch GetItem to retrieve full item data. Returns changed items and the new sync timestamp.

- **Batch push** (POST /sync/push): For each item in the batch, compares the client's serverVersion against the current DynamoDB version. If versions match, applies the client's changes directly. If versions differ, performs field-level merge using the conflict resolution tiers (Tier 1: server/LLM wins; Tier 2: client/user wins; Tier 3: client wins if field is in userEditedFields). Returns per-item outcomes (accepted, merged, or conflict).

- **Full reconciliation** (POST /sync/full): Queries all user receipts from DynamoDB with pagination. Returns the complete set for client-side comparison.

The 512 MB memory allocation and 30-second timeout accommodate large batch operations and complex merge logic for users with many receipts.

#### 4. thumbnail-generator

| Setting | Value |
|---------|-------|
| Function name | receiptvault-thumbnail-generator-prod |
| Purpose | Generates 200x300px JPEG thumbnails from uploaded receipt images |
| Trigger | S3 event notification (s3:ObjectCreated:* on the `users/*/receipts/*/original/*` prefix) |
| Memory | 512 MB |
| Timeout | 30 seconds |
| Concurrency | Unreserved |
| Environment variables | S3_BUCKET, THUMBNAIL_WIDTH (200), THUMBNAIL_HEIGHT (300), THUMBNAIL_QUALITY (70) |

When a receipt image is uploaded to S3 under the `original/` prefix, this Lambda is automatically triggered. It:
1. Downloads the original image from S3.
2. Resizes it to 200x300 pixels, maintaining aspect ratio with center-crop.
3. Compresses as JPEG at 70% quality.
4. Uploads the thumbnail to the same receipt's `thumbnail/` prefix in S3.

The function uses the Pillow (PIL) library for image processing, included as a Lambda layer. The 512 MB memory is required for processing large original images (up to 10 MB).

#### 5. warranty-checker

| Setting | Value |
|---------|-------|
| Function name | receiptvault-warranty-checker-prod |
| Purpose | Daily scan of all users' warranties to identify approaching expirations and send push notification reminders |
| Trigger | EventBridge scheduled rule (daily at 8 AM UTC) |
| Memory | 256 MB |
| Timeout | 60 seconds |
| Concurrency | 1 (only one instance should run at a time) |
| Environment variables | TABLE_NAME, REGION, SNS_PLATFORM_ARN |

This function executes daily and performs the following:
1. Scans DynamoDB for all users by querying for distinct user PKs.
2. For each user, queries GSI-4 (ByWarrantyExpiry) to find warranties expiring within the user's configured reminder windows (from their settings record).
3. For each matching warranty, checks whether a notification has already been sent for this expiry threshold (to avoid duplicate daily notifications).
4. Sends push notifications via SNS for each new expiry alert.
5. Records sent notifications in DynamoDB to prevent duplicates.

The 60-second timeout accommodates iterating through all users. At 5 users, this completes in under 1 second. At 1,000 users, the function may need up to 10-15 seconds depending on the number of active warranties.

The reserved concurrency of 1 ensures that overlapping EventBridge triggers (which should not happen but could in edge cases) do not cause duplicate notifications.

#### 6. weekly-summary

| Setting | Value |
|---------|-------|
| Function name | receiptvault-weekly-summary-prod |
| Purpose | Generates and sends weekly warranty status summary notifications to all users who have opted in |
| Trigger | EventBridge scheduled rule (weekly, Monday 9 AM UTC) |
| Memory | 256 MB |
| Timeout | 60 seconds |
| Concurrency | 1 |
| Environment variables | TABLE_NAME, REGION, SNS_PLATFORM_ARN |

This function:
1. Queries DynamoDB for all users with `weeklyDigestEnabled: true` in their settings.
2. For each user, queries GSI-4 (ByWarrantyExpiry) to compute summary statistics: warranties expiring this week, this month, total active warranties, total warranty value, and the soonest-expiring item.
3. Constructs a summary notification payload.
4. Sends the notification via SNS.

The function only sends notifications to users with active warranties and the weekly digest feature enabled. Users with no active warranties receive no notification.

#### 7. user-deletion

| Setting | Value |
|---------|-------|
| Function name | receiptvault-user-deletion-prod |
| Purpose | Cascade delete of all user data across Cognito, DynamoDB, and S3 when user requests account deletion |
| Trigger | API Gateway (DELETE /user/account) |
| Memory | 256 MB |
| Timeout | 120 seconds |
| Concurrency | Unreserved |
| Environment variables | TABLE_NAME, REGION, S3_BUCKET, USER_POOL_ID |

This function implements the GDPR-compliant account deletion cascade:

1. **Validate confirmation token**: Verifies the deletion confirmation token format and freshness (must be less than 5 minutes old).
2. **Delete Cognito user**: Calls `AdminDeleteUser` on the Cognito User Pool. This immediately invalidates all tokens and prevents future sign-in. This step is performed first because it is the most critical for security -- even if subsequent steps fail, the user can no longer authenticate.
3. **Delete DynamoDB records**: Queries all items with `PK = USER#<userId>` and performs a BatchWriteItem to delete every item. This includes all receipt records, the META#CATEGORIES item, and the META#SETTINGS item. DynamoDB's BatchWriteItem processes up to 25 items per call, so multiple batches may be needed for users with many receipts.
4. **Delete S3 objects**: Lists all objects under `users/<userId>/` prefix, including all versions (because versioning is enabled). Calls DeleteObjects in batches of 1,000 to remove all object versions and delete markers.
5. **Log audit record**: Writes a CloudWatch log entry recording the deletion event (user ID hash, timestamp, item counts deleted). No personally identifiable information is included in the log.

The 120-second timeout accommodates large accounts with hundreds of receipts and images. If the function times out (extremely unlikely at v1 scale), the partially-completed deletion is detectable by the absence of the Cognito user, and a cleanup mechanism can be triggered manually.

#### 8. export-handler

| Setting | Value |
|---------|-------|
| Function name | receiptvault-export-handler-prod |
| Purpose | Packages all user data (receipts + images) into a ZIP file for GDPR data portability |
| Trigger | API Gateway (POST /user/export), with async processing via SQS for large exports |
| Memory | 1024 MB |
| Timeout | 300 seconds (5 minutes) |
| Concurrency | 2 (limit concurrent exports to control S3 bandwidth) |
| Environment variables | TABLE_NAME, REGION, S3_BUCKET, EXPORT_BUCKET, EXPORT_TTL_DAYS (7) |

This is the most resource-intensive Lambda function. It:
1. Queries DynamoDB for all user receipts (optionally filtered by date range).
2. Serializes each receipt as a JSON file.
3. Downloads original images from S3 for each receipt.
4. Creates a ZIP archive in the Lambda's /tmp directory (up to 512 MB with 1024 MB memory).
5. Uploads the ZIP to a dedicated export S3 bucket with a 7-day lifecycle expiration.
6. Generates a pre-signed download URL (24-hour expiry).
7. Sends an SNS push notification with the download URL.

The 1024 MB memory provides 512 MB of /tmp storage for building the ZIP file. The 300-second timeout accommodates downloading many images from S3. For very large exports, the function uses streaming ZIP creation to minimize memory usage.

#### 9. category-handler

| Setting | Value |
|---------|-------|
| Function name | receiptvault-category-handler-prod |
| Purpose | Handles category CRUD operations (get defaults + custom, update custom list) |
| Trigger | API Gateway (GET /categories, PUT /categories) |
| Memory | 256 MB |
| Timeout | 10 seconds |
| Concurrency | Unreserved |
| Environment variables | TABLE_NAME, REGION |

A straightforward function that:
- On GET: Returns the hardcoded default categories and the user's custom categories from DynamoDB (PK = USER#<userId>, SK = META#CATEGORIES).
- On PUT: Validates the custom category list (max 50 categories, each 1-50 characters), performs a conditional write with version checking, and returns the updated list.

#### 10. presigned-url-generator

| Setting | Value |
|---------|-------|
| Function name | receiptvault-presigned-url-generator-prod |
| Purpose | Generates pre-signed S3 URLs for image upload and download |
| Trigger | API Gateway (POST /receipts/{receiptId}/images/upload-url, GET /receipts/{receiptId}/images/{imageKey}/download-url) |
| Memory | 128 MB |
| Timeout | 5 seconds |
| Concurrency | Unreserved |
| Environment variables | S3_BUCKET, REGION, KMS_KEY_ID, URL_EXPIRY_SECONDS (600), MAX_FILE_SIZE (10485760) |

The lightest Lambda function. It validates the request, confirms the receipt belongs to the authenticated user, and generates a pre-signed S3 URL using boto3's `generate_presigned_url` method. The URL includes conditions for content type, content length, and server-side encryption parameters.

128 MB memory is sufficient because the function performs no data processing -- just a DynamoDB GetItem to validate ownership and an S3 pre-sign API call.

---

## Amazon DynamoDB

### Table Configuration

| Setting | Value |
|---------|-------|
| Table name | ReceiptVault |
| Design pattern | Single-table design |
| Partition key (PK) | String |
| Sort key (SK) | String |
| Capacity mode | On-demand (pay-per-request) |
| Encryption | AWS-owned key (default) |
| Point-in-time recovery | Enabled |
| TTL attribute | ttl |
| Streams | Disabled (enable for v2 shared vault feature) |
| Deletion protection | Enabled |

### Capacity Mode: On-Demand

On-demand capacity is chosen over provisioned capacity because:

1. **Unpredictable traffic patterns**: A small user base with bursty sync operations makes provisioned capacity impractical. On-demand automatically scales from zero to thousands of requests per second.
2. **Cost efficiency at low scale**: At 5 users, the cost is less than $0.01/month. On-demand has no minimum charge. Provisioned capacity with auto-scaling would still incur minimum charges for the provisioned baseline.
3. **No capacity planning**: On-demand eliminates the need to estimate read/write capacity units, set up auto-scaling policies, or worry about throttling from unexpected traffic spikes.
4. **Simple operations**: No CloudWatch alarms, scaling policies, or capacity adjustments to manage.

At 1,000 users, on-demand pricing remains cost-effective (approximately $0.16/month based on estimated read/write volumes). The switch to provisioned capacity with auto-scaling should be evaluated if costs exceed $10/month, which would require approximately 60,000+ users.

### Global Secondary Indexes (6 GSIs)

All GSIs use on-demand capacity (inherited from the base table).

| GSI | Name | Partition Key | Sort Key | Projection | Purpose |
|-----|------|---------------|----------|------------|---------|
| GSI-1 | ByUserDate | USER#userId | purchaseDate | ALL | List receipts by purchase date, date range queries |
| GSI-2 | ByUserCategory | USER#userId | CAT#category | ALL | Filter receipts by category |
| GSI-3 | ByUserStore | USER#userId | STORE#storeName | ALL | Filter receipts by store/merchant |
| GSI-4 | ByWarrantyExpiry | USER#userId#ACTIVE | warrantyExpiryDate | ALL | Active warranties sorted by expiry date, expiring-soon queries |
| GSI-5 | ByUserStatus | USER#userId | STATUS#status#purchaseDate | ALL | Filter receipts by status (active, returned, archived, deleted) |
| GSI-6 | ByUpdatedAt | USER#userId | updatedAt | KEYS_ONLY | Delta sync queries (find items modified after timestamp) |

**GSI-4 Sparse Index**: The partition key for GSI-4 includes an `#ACTIVE` suffix (e.g., `USER#abc123#ACTIVE`). This attribute is only set on receipts with active, unexpired warranties and status "active". When a receipt is deleted, returned, or its warranty expires, this attribute is removed, and the item automatically disappears from GSI-4. This makes warranty queries extremely efficient -- they only scan active warranties, not the entire receipt collection.

**GSI-6 KEYS_ONLY**: GSI-6 uses KEYS_ONLY projection (only PK and SK are projected) to minimize storage cost and write cost for the most frequently updated index. The sync-handler Lambda performs a follow-up BatchGetItem to retrieve full item data for matching keys. This trade-off is worthwhile because delta sync queries are relatively infrequent (every few minutes at most per user) while receipt writes happen more frequently.

### Encryption

The DynamoDB table uses the default AWS-owned encryption key. This provides encryption at rest with zero additional cost and no key management overhead. A Customer Managed Key (CMK) is not used for DynamoDB because:

1. The data in DynamoDB is structured metadata (merchant names, dates, amounts), not high-sensitivity PII like government IDs or financial account numbers.
2. The actual receipt images (which are the sensitive artifacts) are stored in S3 with SSE-KMS using a Customer Managed Key.
3. AWS-owned encryption still provides AES-256 encryption at rest -- the data is never stored unencrypted.
4. CMK for DynamoDB would add $1/month per key plus $0.03 per 10,000 API calls, with minimal security benefit for this data type.

### Point-in-Time Recovery (PITR)

PITR is enabled to allow restoration of the table to any point in the last 35 days. This protects against:

- Accidental data corruption from a buggy Lambda deployment
- Accidental batch deletion from an administrative error
- DynamoDB service issues (extremely rare but not impossible)

PITR cost is included in the on-demand pricing and adds approximately 20% to storage costs (negligible at v1 scale).

### TTL (Time to Live)

The `ttl` attribute is used for automatic cleanup of soft-deleted receipts. When a receipt is soft-deleted (DELETE /receipts/{receiptId}), the Lambda function sets the `ttl` attribute to the current Unix epoch timestamp plus 30 days (2,592,000 seconds). DynamoDB automatically deletes the item after the TTL expires, typically within 48 hours of the TTL timestamp.

This mechanism ensures that soft-deleted receipts are permanently removed without requiring a scheduled cleanup job, while providing the 30-day recovery window for the restore functionality.

---

## Amazon S3

### Bucket Configuration

| Setting | Value |
|---------|-------|
| Bucket name | receiptvault-images-prod-eu-west-1 |
| Region | eu-west-1 |
| Versioning | Enabled |
| Encryption | SSE-KMS with Customer Managed Key + Bucket Keys |
| Public access | All public access blocked (Block Public Access enabled at bucket and account level) |
| Object Lock | Not enabled (versioning + lifecycle provides sufficient protection) |
| Transfer acceleration | Not enabled (not needed for v1 traffic volume) |
| Requester pays | Not enabled |

### Encryption: SSE-KMS with Customer Managed Key and Bucket Keys

S3 objects are encrypted using Server-Side Encryption with AWS Key Management Service (SSE-KMS). A Customer Managed Key (CMK) is used instead of the AWS-managed S3 key for the following reasons:

1. **GDPR Crypto-Shredding**: If a scenario arises where all data must be rendered permanently unreadable (e.g., a regulatory order), the CMK can be scheduled for deletion. Once the key is deleted, all objects encrypted with it become permanently unreadable, even though the encrypted ciphertext remains in S3. This is faster and more reliable than individually deleting millions of objects.

2. **CloudTrail Audit**: KMS with CMK logs every encrypt and decrypt operation in CloudTrail, providing a complete audit trail of who accessed receipt images and when. This supports GDPR accountability requirements.

3. **Fine-Grained Access Control**: The CMK's key policy restricts which IAM roles can use the key for encryption and decryption. Only specific Lambda execution roles and the pre-signed URL generator can access the key.

**Bucket Keys** are enabled to reduce KMS API costs. Without Bucket Keys, every S3 object operation (upload, download) requires a separate KMS API call ($0.03 per 10,000 calls). With Bucket Keys, S3 generates a time-limited bucket-level key from the CMK and uses it for multiple object operations, dramatically reducing KMS API calls. At 1,000 users, this saves approximately $0.50-1.00/month in KMS costs.

### Versioning

S3 versioning is enabled to support the soft-delete recovery mechanism for images. When a receipt is soft-deleted:

1. The receipt's DynamoDB record gets a TTL for 30-day auto-deletion.
2. The receipt's S3 images are not immediately deleted. They remain as current versions.
3. If the user restores the receipt within 30 days, the images are still accessible.
4. If the 30-day window passes and the DynamoDB TTL fires, a cleanup process can delete the S3 objects. Alternatively, the NoncurrentVersionExpiration lifecycle rule handles cleanup of any objects that are superseded.

Versioning also protects against accidental overwrites (e.g., if the thumbnail generator creates a corrupt thumbnail, the previous version is recoverable).

### Lifecycle Rules

| Rule | Configuration | Purpose |
|------|--------------|---------|
| NoncurrentVersionExpiration | Delete noncurrent versions after 30 days | Clean up old versions of overwritten or deleted images. Aligns with the 30-day soft-delete recovery window. |
| Intelligent-Tiering for current versions | Move current objects to Intelligent-Tiering | Automatically moves infrequently accessed images (older receipts) to lower-cost tiers. S3 Intelligent-Tiering has no retrieval fees and a small monitoring cost ($0.0025 per 1,000 objects/month). |

### Object Structure

All objects are organized under a consistent prefix hierarchy:

```
users/
  {userId}/
    receipts/
      {receiptId}/
        original/
          {filename}          (e.g., receipt_front.jpg)
        thumbnail/
          {filename}          (e.g., receipt_front.jpg, 200x300px JPEG 70%)
```

This structure enables:
- Efficient per-user listing and deletion (all user data under `users/{userId}/`).
- Per-receipt image grouping (all images for a receipt under `receipts/{receiptId}/`).
- Separation of original and thumbnail variants.
- S3 event notifications scoped to the `users/*/receipts/*/original/*` prefix for triggering the thumbnail-generator Lambda.

### Access Control

- **Block Public Access**: Enabled at both the bucket level and the account level. No S3 object can ever be made public.
- **Bucket policy**: Explicitly denies non-HTTPS access (`aws:SecureTransport: false`), enforces SSE-KMS encryption on all uploads, and restricts access to specific IAM roles.
- **Pre-signed URLs**: All client access to S3 objects is through pre-signed URLs generated by the presigned-url-generator Lambda. Pre-signed URLs have a 10-minute expiry and include content-type and content-length conditions for uploads.
- **CloudFront OAC**: Thumbnail access through CloudFront uses Origin Access Control, which restricts the CloudFront distribution to access only the `thumbnail/` prefix.

### Access Logging

S3 access logs are delivered to a separate logging bucket (`receiptvault-access-logs-prod-eu-west-1`). The logging bucket has:
- Versioning disabled (logs do not need versioning)
- Lifecycle rule: delete objects after 90 days
- Encryption: SSE-S3 (default encryption, no CMK needed for access logs)

Access logs record every S3 API operation (GetObject, PutObject, DeleteObject) and are useful for security auditing, debugging access issues, and GDPR accountability.

---

## AWS KMS

### Customer Managed Key Configuration

| Setting | Value |
|---------|-------|
| Key alias | alias/receiptvault-s3-cmk |
| Key type | Symmetric (AES-256) |
| Key usage | Encrypt and decrypt |
| Key rotation | Automatic annual rotation enabled |
| Region | eu-west-1 |
| Cost | $1.00/month per key |

### Key Rotation

Automatic annual key rotation is enabled. When AWS rotates the key, it creates a new backing key but retains all previous backing keys so that objects encrypted with older key versions can still be decrypted. The key alias and key ARN remain unchanged.

This provides cryptographic hygiene (limiting the exposure window of any single key material) with zero operational overhead.

### Key Policy

The KMS key policy follows least-privilege access:

| Principal | Permissions | Purpose |
|-----------|------------|---------|
| Account root | Full key administration | Recovery access, key management |
| Lambda execution roles (receipt-crud, ocr-refine, presigned-url-generator, thumbnail-generator, export-handler, user-deletion) | kms:Encrypt, kms:Decrypt, kms:GenerateDataKey | S3 object encryption/decryption during Lambda operations |
| S3 service principal | kms:GenerateDataKey, kms:Decrypt | S3 Bucket Keys integration (S3 uses the CMK to generate time-limited bucket-level keys) |
| CloudFront OAC | kms:Decrypt | CloudFront needs to decrypt S3 objects for thumbnail delivery |

No other principals have access to the key. IAM users and roles not explicitly listed cannot use the key for any operation.

### GDPR Crypto-Shredding

The CMK enables a "nuclear option" for data destruction: scheduling the key for deletion renders all S3 objects encrypted with it permanently unreadable. The minimum key deletion waiting period is 7 days, during which the deletion can be cancelled.

In practice, this capability is a safeguard rather than a routine operation. Normal account deletion uses the user-deletion Lambda to individually delete DynamoDB records and S3 objects. Crypto-shredding would only be used in extreme scenarios such as a regulatory order to destroy all data immediately.

---

## Amazon CloudFront

### Distribution Configuration

| Setting | Value |
|---------|-------|
| Distribution purpose | CDN for receipt thumbnail images |
| Origin | receiptvault-images-prod-eu-west-1 S3 bucket |
| Origin path | None (the distribution serves the full bucket; path-based restrictions are in the cache behavior) |
| Origin access | Origin Access Control (OAC) |
| Price class | PriceClass_100 (North America and Europe edge locations) |
| HTTP version | HTTP/2 |
| IPv6 | Enabled |
| Default root object | None (not a static website) |

### Origin Access Control (OAC)

CloudFront uses OAC (not the legacy Origin Access Identity / OAI) to access the S3 bucket. OAC is the current-generation mechanism recommended by AWS for S3 origins. It:

- Supports SSE-KMS encrypted objects (OAI does not).
- Uses SigV4 for signing requests to S3.
- Supports S3 bucket policies for access control.
- Does not require a special CloudFront identity in the S3 bucket policy.

The S3 bucket policy grants `s3:GetObject` permission to the CloudFront service principal (`cloudfront.amazonaws.com`) with a condition that the request's `AWS:SourceArn` matches the CloudFront distribution ARN. This ensures only this specific distribution can access the bucket through CloudFront.

### Cache Behavior

| Path Pattern | TTL | Behavior |
|-------------|-----|----------|
| `users/*/receipts/*/thumbnail/*` | 24 hours (86,400 seconds) | Cache thumbnails aggressively. Thumbnails are immutable (once generated, they do not change). A 24-hour TTL balances caching efficiency with the ability to regenerate thumbnails if needed. |
| Default (`*`) | No caching (forward to origin) | All other paths are not served through CloudFront. The default behavior forwards to origin but is effectively unused because only thumbnail URLs are constructed with the CloudFront domain. |

### Signed URLs vs Pre-Signed S3 URLs

The architecture uses two different URL mechanisms for image access:

1. **Thumbnails**: Served via CloudFront URLs (unsigned). Thumbnails are low-resolution (200x300px, JPEG 70%) and do not contain sensitive information beyond what is visible in the receipt listing. CloudFront caching provides fast global delivery. The CloudFront distribution is restricted to the `thumbnail/` prefix via the OAC and bucket policy, so original images cannot be accessed through CloudFront.

2. **Original images**: Served via pre-signed S3 URLs (signed, 10-minute expiry). Original images are high-resolution and may contain sensitive information. Pre-signed URLs provide fine-grained, time-limited access control that is validated on each request.

This dual approach optimizes for both performance (thumbnails via CDN) and security (originals via pre-signed URLs).

### Free Tier

CloudFront's free tier includes 1 TB of data transfer per month and 10 million HTTP requests per month. At v1 scale (5 users with hundreds of thumbnails), usage will be a tiny fraction of the free tier. Even at 1,000 users, the free tier is likely sufficient because thumbnails are small (5-15 KB each) and are cached at the edge.

---

## Amazon SNS

### Platform Application Configuration

SNS is used to deliver push notifications from the server to the mobile app. Two platform applications are configured, one for each mobile platform.

| Platform | Protocol | Configuration |
|----------|----------|---------------|
| Android | FCM (Firebase Cloud Messaging) | FCM API key from Firebase project. The Flutter app uses `firebase_messaging` package to register for push and receive the device token. |
| iOS | APNs (Apple Push Notification service) | APNs authentication key (.p8 file) from Apple Developer account. Token-based authentication (not certificate-based). |

### SNS Topics

| Topic | Name | Purpose | Subscribers |
|-------|------|---------|-------------|
| Warranty Expiring | receiptvault-warranty-expiring-prod | Notification channel for warranty expiry alerts | Per-user endpoint ARNs (device tokens registered via the app) |
| Export Ready | receiptvault-export-ready-prod | Notification channel for data export completion | Per-user endpoint ARNs |

### Device Registration Flow

1. The Flutter app obtains a device token from FCM (Android) or APNs (iOS) using the `firebase_messaging` package.
2. On app launch (after authentication), the app sends the device token to the backend.
3. The backend creates or updates an SNS platform endpoint for the device token.
4. The endpoint ARN is stored in DynamoDB associated with the user (in the META#SETTINGS item).
5. When a Lambda function needs to send a push notification to a specific user, it retrieves the endpoint ARN from DynamoDB and calls `SNS:Publish` with the platform-specific payload.

### Cost

SNS push notification delivery costs $0.50 per million notifications. At v1 scale (5 users, a few notifications per day), the cost is effectively zero. At 1,000 users with daily warranty checks and weekly summaries, the monthly cost is approximately $0.15.

---

## Amazon EventBridge

### Scheduled Rules

EventBridge provides serverless cron-like scheduling for periodic Lambda invocations.

#### Rule 1: Daily Warranty Check

| Setting | Value |
|---------|-------|
| Rule name | receiptvault-daily-warranty-check |
| Schedule expression | `cron(0 8 * * ? *)` |
| Schedule meaning | Every day at 8:00 AM UTC |
| Target | receiptvault-warranty-checker-prod Lambda function |
| Input | None (no custom input needed -- Lambda queries DynamoDB for all users) |
| Retry policy | 2 retries with exponential backoff |
| Dead-letter queue | None for v1 (add in v2 for observability) |

The 8 AM UTC schedule was chosen because it translates to morning hours across European timezones (9 AM CET, 10 AM EET), which is when users are most likely to act on warranty expiry reminders.

#### Rule 2: Weekly Warranty Summary

| Setting | Value |
|---------|-------|
| Rule name | receiptvault-weekly-summary |
| Schedule expression | `cron(0 9 ? * MON *)` |
| Schedule meaning | Every Monday at 9:00 AM UTC |
| Target | receiptvault-weekly-summary-prod Lambda function |
| Input | None |
| Retry policy | 2 retries with exponential backoff |
| Dead-letter queue | None for v1 |

The Monday 9 AM UTC schedule delivers the weekly digest at the start of the workweek, when users are most engaged with organizational tasks.

### Cost

EventBridge scheduled rules are free. There is no cost for the rules themselves -- only the Lambda invocations they trigger, which are covered by the Lambda free tier at v1 scale.

---

## Amazon Bedrock

### Model Configuration

| Setting | Value |
|---------|-------|
| Primary model | Claude Haiku 4.5 (anthropic.claude-haiku-4-5-v1) |
| Fallback model | Claude Sonnet 4.5 (anthropic.claude-sonnet-4-5-v1) |
| Region | eu-west-1 (if available; see availability note below) |
| API | InvokeModel (synchronous) |
| Max input tokens | ~4,000 (OCR text + image description) |
| Max output tokens | 1,000 (structured JSON response) |

### Fallback Strategy

The primary model is Claude Haiku 4.5, chosen for its low cost (~$0.004 per receipt) and fast response time (sub-1 second). If Haiku returns a response with confidence below the configurable threshold (default 0.70), or if Haiku is unavailable (throttled or experiencing an outage), the ocr-refine Lambda automatically retries with Claude Sonnet 4.5 as a fallback.

| Model | Cost per Receipt (approximate) | Latency | Use Case |
|-------|-------------------------------|---------|----------|
| Claude Haiku 4.5 | ~$0.004 | Sub-1 second | Primary model for all OCR refinement |
| Claude Sonnet 4.5 | ~$0.015 | 1-3 seconds | Fallback for low-confidence results or Haiku unavailability |

The fallback to Sonnet increases per-receipt cost by approximately 4x, but is only invoked when Haiku's output is insufficient. Based on testing expectations, the fallback should be needed for less than 5% of receipts (primarily complex, multi-language, or poorly photographed receipts).

### Regional Availability

Bedrock model availability varies by region. Claude models are generally available in us-east-1 and us-west-2, with expanding availability in eu-west-1. At deployment time, the team must verify that Claude Haiku 4.5 and Sonnet 4.5 are available in eu-west-1.

If the models are not available in eu-west-1, the ocr-refine Lambda will make cross-region API calls to a region where the models are available (likely us-east-1). This adds latency (50-100ms for the cross-region hop) but does not affect functionality because the refinement operation is asynchronous. The OCR text and receipt image would be sent to the Bedrock endpoint in the other region for processing, but the data is not stored by Bedrock (see data policy below).

### Data Policy

Amazon Bedrock's data policy (confirmed through AWS documentation and service terms) states:

- **No data storage**: Input data (OCR text, receipt images) is not stored by Bedrock after the inference request completes.
- **No model training**: User data is never used to train or fine-tune any model.
- **No data sharing**: User data is not shared with Anthropic or any other model provider.

These guarantees are critical for GDPR compliance. The receipt data processed by Bedrock is treated as transient -- it exists only in memory during the inference call and is discarded immediately after the response is generated.

### Cost at Scale

| Scale | Monthly Receipts | Haiku Cost | Sonnet Fallback (5%) | Total Bedrock Cost |
|-------|-----------------|------------|---------------------|-------------------|
| 5 users | ~100 | $0.40 | $0.075 | ~$0.48 |
| 1,000 users | ~20,000 | $80.00 | $15.00 | ~$95.00 |

Bedrock is the single largest cost component at scale, accounting for approximately 90% of the monthly AWS bill at 1,000 users. Cost optimization strategies for the future include:
- Increasing the Haiku confidence threshold to reduce Sonnet fallback rate.
- Caching LLM results for identical or near-identical OCR inputs.
- Offering a "basic extraction only" mode that skips LLM refinement for users who do not need high-accuracy parsing.

---

## Amazon CloudWatch

### Lambda Function Logs

Every Lambda function automatically creates a CloudWatch Log Group on first invocation. Log groups follow the naming convention `/aws/lambda/receiptvault-{function-name}-prod`.

| Setting | Value |
|---------|-------|
| Retention | 30 days |
| Encryption | Default (CloudWatch manages encryption) |
| Log format | JSON (structured logging from Lambda functions) |

All Lambda functions use structured JSON logging with consistent fields: timestamp, requestId, userId (hashed), function name, operation, duration, and outcome. No personally identifiable information (email addresses, receipt content) is included in logs.

### Custom Metrics

The following custom CloudWatch metrics are emitted by Lambda functions using the CloudWatch embedded metric format (EMF) for cost-efficient metric ingestion.

| Metric Namespace | Metric Name | Unit | Description | Emitted By |
|-----------------|-------------|------|-------------|------------|
| ReceiptVault/OCR | RefinementLatency | Milliseconds | Time from Bedrock API call to response received | ocr-refine |
| ReceiptVault/OCR | RefinementConfidence | None (0-1) | LLM confidence score for each refinement | ocr-refine |
| ReceiptVault/OCR | FallbackInvocations | Count | Number of times Sonnet fallback was triggered | ocr-refine |
| ReceiptVault/Sync | SyncDuration | Milliseconds | Time to complete a sync operation (pull, push, or full) | sync-handler |
| ReceiptVault/Sync | SyncItemCount | Count | Number of items processed in a sync operation | sync-handler |
| ReceiptVault/Sync | ConflictCount | Count | Number of merge conflicts detected during sync push | sync-handler |
| ReceiptVault/API | ErrorCount | Count | Number of 4xx and 5xx responses (per endpoint) | All API-triggered Lambdas |
| ReceiptVault/API | ReceiptCreateCount | Count | Number of new receipts created | receipt-crud |
| ReceiptVault/Users | ActiveUsers | Count | Number of distinct users who performed at least one API call (daily) | All API-triggered Lambdas |

### CloudWatch Alarms

| Alarm Name | Metric | Threshold | Period | Action |
|-----------|--------|-----------|--------|--------|
| HighLambdaErrorRate | AWS/Lambda Errors (all functions) | > 5% error rate | 5 minutes | SNS notification to ops email |
| SyncFailures | ReceiptVault/Sync ConflictCount | > 10 conflicts in single sync | 1 minute | SNS notification to ops email |
| BedrockThrottling | AWS/Bedrock ThrottledCount | > 0 | 1 minute | SNS notification to ops email |
| HighLatencyOCR | ReceiptVault/OCR RefinementLatency | p99 > 10,000ms | 5 minutes | SNS notification to ops email |
| UserDeletionFailure | AWS/Lambda Errors (user-deletion only) | > 0 | 1 minute | SNS notification to ops email (critical -- deletion must succeed) |

### CloudWatch Dashboard

A single CloudWatch dashboard (`ReceiptVault-Production`) provides at-a-glance operational visibility.

**Dashboard Widgets**:

1. **API Health** (top row)
   - API Gateway 4xx error rate (line chart, 1-hour period)
   - API Gateway 5xx error rate (line chart, 1-hour period)
   - API Gateway latency p50/p90/p99 (line chart, 1-hour period)

2. **Receipt Activity** (second row)
   - Daily receipt creation count (bar chart, 24-hour period)
   - Daily active users (bar chart, 24-hour period)

3. **OCR/LLM Performance** (third row)
   - Refinement latency p50/p90/p99 (line chart, 1-hour period)
   - Confidence score distribution (histogram)
   - Sonnet fallback rate (percentage, 24-hour period)

4. **Sync Performance** (fourth row)
   - Sync duration p50/p90/p99 (line chart, 1-hour period)
   - Conflict count (bar chart, 24-hour period)
   - Items synced per operation (line chart, 1-hour period)

5. **Cost Indicators** (bottom row)
   - Bedrock invocation count (daily, bar chart)
   - DynamoDB consumed read/write capacity (line chart, 1-hour period)
   - S3 storage used (single value, updated daily)

---

## IAM Roles and Policies

### Principle: Least Privilege

Every Lambda function has its own dedicated IAM execution role with the minimum permissions required for its specific functionality. No function shares roles with another function. Policies are scoped to specific resources (table ARN, bucket ARN, key ARN, model ARN) rather than using wildcards.

### Lambda Execution Roles

#### receipt-crud Execution Role

| Permission | Resource | Purpose |
|------------|----------|---------|
| dynamodb:GetItem | ReceiptVault table ARN | Read single receipt |
| dynamodb:Query | ReceiptVault table ARN + all GSI ARNs | List/filter receipts |
| dynamodb:PutItem | ReceiptVault table ARN | Create receipt |
| dynamodb:UpdateItem | ReceiptVault table ARN | Update receipt, soft delete, restore, status change |
| dynamodb:DeleteItem | ReceiptVault table ARN | Hard delete (used only by TTL, not directly by this function) |
| logs:CreateLogGroup, logs:CreateLogStream, logs:PutLogEvents | Function log group ARN | CloudWatch logging |

#### ocr-refine Execution Role

| Permission | Resource | Purpose |
|------------|----------|---------|
| dynamodb:GetItem | ReceiptVault table ARN | Read receipt for validation |
| dynamodb:UpdateItem | ReceiptVault table ARN | Write refined data back to receipt |
| s3:GetObject | receiptvault-images bucket ARN (`users/*`) | Download receipt image for LLM processing |
| kms:Decrypt | CMK ARN | Decrypt S3 objects |
| bedrock:InvokeModel | Model ARNs (Haiku 4.5 + Sonnet 4.5) | Call Bedrock for OCR refinement |
| sns:Publish | Platform endpoint ARNs | Send refinement-complete notification |
| logs:CreateLogGroup, logs:CreateLogStream, logs:PutLogEvents | Function log group ARN | CloudWatch logging |

#### sync-handler Execution Role

| Permission | Resource | Purpose |
|------------|----------|---------|
| dynamodb:GetItem | ReceiptVault table ARN | Read individual items during merge |
| dynamodb:BatchGetItem | ReceiptVault table ARN | Batch read for delta sync pull |
| dynamodb:Query | ReceiptVault table ARN + GSI-6 ARN | Query for changed items |
| dynamodb:PutItem | ReceiptVault table ARN | Write new items from push |
| dynamodb:UpdateItem | ReceiptVault table ARN | Update items during merge |
| dynamodb:BatchWriteItem | ReceiptVault table ARN | Batch write for push operations |
| logs:CreateLogGroup, logs:CreateLogStream, logs:PutLogEvents | Function log group ARN | CloudWatch logging |

#### thumbnail-generator Execution Role

| Permission | Resource | Purpose |
|------------|----------|---------|
| s3:GetObject | receiptvault-images bucket ARN (`users/*/receipts/*/original/*`) | Download original image |
| s3:PutObject | receiptvault-images bucket ARN (`users/*/receipts/*/thumbnail/*`) | Upload generated thumbnail |
| kms:Decrypt | CMK ARN | Decrypt original image |
| kms:GenerateDataKey | CMK ARN | Encrypt thumbnail |
| logs:CreateLogGroup, logs:CreateLogStream, logs:PutLogEvents | Function log group ARN | CloudWatch logging |

#### warranty-checker Execution Role

| Permission | Resource | Purpose |
|------------|----------|---------|
| dynamodb:Scan | ReceiptVault table ARN | Scan for all user PKs |
| dynamodb:Query | ReceiptVault table ARN + GSI-4 ARN | Query expiring warranties per user |
| dynamodb:GetItem | ReceiptVault table ARN | Read user settings for reminder preferences |
| dynamodb:UpdateItem | ReceiptVault table ARN | Record sent notification status |
| sns:Publish | Platform endpoint ARNs | Send warranty expiry notifications |
| logs:CreateLogGroup, logs:CreateLogStream, logs:PutLogEvents | Function log group ARN | CloudWatch logging |

#### weekly-summary Execution Role

| Permission | Resource | Purpose |
|------------|----------|---------|
| dynamodb:Scan | ReceiptVault table ARN | Scan for users with weekly digest enabled |
| dynamodb:Query | ReceiptVault table ARN + GSI-4 ARN | Query warranty data per user |
| sns:Publish | Platform endpoint ARNs | Send weekly summary notifications |
| logs:CreateLogGroup, logs:CreateLogStream, logs:PutLogEvents | Function log group ARN | CloudWatch logging |

#### user-deletion Execution Role

| Permission | Resource | Purpose |
|------------|----------|---------|
| cognito-idp:AdminDeleteUser | User Pool ARN | Delete Cognito user account |
| dynamodb:Query | ReceiptVault table ARN | Find all user items |
| dynamodb:BatchWriteItem | ReceiptVault table ARN | Batch delete all user items |
| s3:ListBucket | receiptvault-images bucket ARN (prefix `users/{userId}/`) | List all user objects |
| s3:DeleteObject | receiptvault-images bucket ARN (prefix `users/{userId}/`) | Delete user objects |
| s3:ListBucketVersions | receiptvault-images bucket ARN (prefix `users/{userId}/`) | List all object versions |
| s3:DeleteObjectVersion | receiptvault-images bucket ARN (prefix `users/{userId}/`) | Delete specific object versions |
| kms:Decrypt | CMK ARN | Access encrypted objects for deletion |
| logs:CreateLogGroup, logs:CreateLogStream, logs:PutLogEvents | Function log group ARN | CloudWatch logging |

#### export-handler Execution Role

| Permission | Resource | Purpose |
|------------|----------|---------|
| dynamodb:Query | ReceiptVault table ARN | Query all user receipts |
| s3:GetObject | receiptvault-images bucket ARN (`users/{userId}/*`) | Download user images |
| s3:PutObject | receiptvault-exports bucket ARN (`exports/{userId}/*`) | Upload export ZIP |
| kms:Decrypt | CMK ARN | Decrypt S3 images |
| kms:GenerateDataKey | CMK ARN | Encrypt export ZIP |
| sns:Publish | Platform endpoint ARNs | Send export-ready notification |
| logs:CreateLogGroup, logs:CreateLogStream, logs:PutLogEvents | Function log group ARN | CloudWatch logging |

#### category-handler Execution Role

| Permission | Resource | Purpose |
|------------|----------|---------|
| dynamodb:GetItem | ReceiptVault table ARN | Read user categories |
| dynamodb:PutItem | ReceiptVault table ARN | Write updated categories |
| dynamodb:UpdateItem | ReceiptVault table ARN | Conditional update categories |
| logs:CreateLogGroup, logs:CreateLogStream, logs:PutLogEvents | Function log group ARN | CloudWatch logging |

#### presigned-url-generator Execution Role

| Permission | Resource | Purpose |
|------------|----------|---------|
| dynamodb:GetItem | ReceiptVault table ARN | Validate receipt ownership |
| s3:PutObject | receiptvault-images bucket ARN (`users/*/receipts/*/original/*`) | Generate upload pre-signed URL |
| s3:GetObject | receiptvault-images bucket ARN (`users/*/receipts/*`) | Generate download pre-signed URL |
| kms:GenerateDataKey | CMK ARN | For upload URL SSE-KMS headers |
| kms:Decrypt | CMK ARN | For download URL decryption |
| logs:CreateLogGroup, logs:CreateLogStream, logs:PutLogEvents | Function log group ARN | CloudWatch logging |

### API Gateway Execution Role

API Gateway requires an IAM role to invoke Lambda functions.

| Permission | Resource | Purpose |
|------------|----------|---------|
| lambda:InvokeFunction | All receiptvault Lambda function ARNs | Invoke Lambda on API requests |

This role is attached to the API Gateway integration for each endpoint. It is a single role with InvokeFunction permission scoped to only the Receipt Vault Lambda functions.

### CloudFront Access

CloudFront does not use an IAM role. Access to S3 is granted through the S3 bucket policy, which allows the CloudFront service principal (`cloudfront.amazonaws.com`) to call `s3:GetObject` on the thumbnail prefix, conditioned on the CloudFront distribution ARN.

---

## Cost Estimate

### At 5 Users (Testing Phase)

| Service | Monthly Cost | Notes |
|---------|-------------|-------|
| DynamoDB | < $0.01 | On-demand: negligible reads/writes at 5 users |
| S3 storage | ~$0.50 | ~500 receipt images, Intelligent-Tiering |
| Bedrock (Haiku 4.5) | ~$0.40 | ~100 receipts/month at $0.004 each |
| KMS | ~$1.00 | 1 CMK ($1/month) + negligible API calls with Bucket Keys |
| Cognito | $0.00 | Lite tier, free up to 10,000 MAUs |
| Lambda | $0.00 | Within AWS free tier (1M requests + 400,000 GB-seconds/month) |
| API Gateway | $0.00 | Within free tier (1M REST API calls/month for first 12 months) |
| SNS | $0.00 | Negligible push notifications |
| CloudFront | $0.00 | Within free tier (1 TB transfer + 10M requests/month) |
| EventBridge | $0.00 | Scheduled rules are free |
| CloudWatch | $0.00 | Within free tier (basic metrics + 5 GB log ingestion) |
| **Total** | **~$2/month** | |

### At 1,000 Users

| Service | Monthly Cost | Notes |
|---------|-------------|-------|
| DynamoDB | ~$0.16 | On-demand: ~100K reads + 50K writes/month |
| S3 storage + transfer | ~$5.00 | ~100K images + Intelligent-Tiering + transfer |
| Bedrock (Haiku 4.5 + Sonnet fallback) | ~$80.00 | ~20K receipts at $0.004 avg (with 5% Sonnet fallback) |
| KMS | ~$1.00 | 1 CMK + Bucket Keys minimizing API calls |
| Cognito | $0.00 | Still within 10,000 MAU Lite tier |
| Lambda | ~$2.00 | ~5M invocations/month, beyond free tier |
| API Gateway | Included in Lambda estimate | ~500K REST API calls/month |
| SNS | < $0.15 | ~300K push notifications/month |
| CloudFront | $0.00 | Still within free tier |
| EventBridge | $0.00 | Scheduled rules remain free |
| CloudWatch | ~$0.50 | Custom metrics + log retention beyond free tier |
| **Total** | **~$88/month** | |

### Cost Dominance

Bedrock (LLM processing) dominates the cost structure at scale, accounting for approximately 90% of the total AWS bill at 1,000 users. All other services are negligible to modest. This cost structure means that the most impactful cost optimization lever is LLM usage: reducing the Sonnet fallback rate, caching duplicate OCR inputs, or offering LLM refinement as an optional/premium feature.

---

## Infrastructure as Code

### Recommended Tool: AWS CDK (Python)

AWS Cloud Development Kit (CDK) with Python is recommended for defining and deploying all infrastructure. CDK was chosen over alternatives for the following reasons:

| Tool | Consideration | Decision |
|------|--------------|----------|
| AWS CDK (Python) | Chosen | Imperative Python code, same language as Lambda functions, strong typing with constructs, synthesizes to CloudFormation |
| Terraform | Not chosen | Excellent tool but introduces HCL language and state management complexity not needed for single-account v1 |
| AWS SAM | Not chosen | Good for Lambda-focused apps but less expressive for non-Lambda resources (KMS, CloudFront, Cognito) |
| CloudFormation (raw) | Not chosen | Too verbose for the number of resources; CDK generates CloudFormation under the hood |

### CDK Stack Structure

For v1, all resources are defined in a single CDK stack (`ReceiptVaultStack`). This simplifies deployment and ensures all resources are created and destroyed atomically. A multi-stack architecture (separate stacks for auth, data, compute, and storage) can be introduced in v2 when independent deployment of subsystems becomes valuable.

The single stack defines:
- Cognito User Pool and App Client
- API Gateway REST API with Cognito authorizer and all route definitions
- All 10 Lambda functions with their execution roles
- DynamoDB table with 6 GSIs
- S3 bucket with lifecycle rules and bucket policy
- KMS Customer Managed Key with key policy
- CloudFront distribution with OAC
- SNS platform applications and topics
- EventBridge rules
- CloudWatch alarms and dashboard

### Environment Configuration

Lambda functions receive configuration through environment variables set in the CDK stack definition. No hardcoded values appear in Lambda function code.

| Environment Variable | Used By | Value |
|---------------------|---------|-------|
| TABLE_NAME | All Lambda functions | ReceiptVault |
| REGION | All Lambda functions | eu-west-1 |
| S3_BUCKET | Image-related functions | receiptvault-images-prod-eu-west-1 |
| KMS_KEY_ID | presigned-url-generator, thumbnail-generator | CMK ARN |
| BEDROCK_MODEL_ID | ocr-refine | anthropic.claude-haiku-4-5-v1 |
| BEDROCK_FALLBACK_MODEL_ID | ocr-refine | anthropic.claude-sonnet-4-5-v1 |
| CONFIDENCE_THRESHOLD | ocr-refine | 0.70 |
| USER_POOL_ID | user-deletion | Cognito User Pool ID |
| SNS_PLATFORM_ARN | warranty-checker, weekly-summary, ocr-refine | SNS platform application ARN |
| URL_EXPIRY_SECONDS | presigned-url-generator | 600 |
| MAX_FILE_SIZE | presigned-url-generator | 10485760 |
| EXPORT_BUCKET | export-handler | receiptvault-exports-prod-eu-west-1 |
| EXPORT_TTL_DAYS | export-handler | 7 |
| THUMBNAIL_WIDTH | thumbnail-generator | 200 |
| THUMBNAIL_HEIGHT | thumbnail-generator | 300 |
| THUMBNAIL_QUALITY | thumbnail-generator | 70 |
| MAX_BATCH_SIZE | sync-handler | 25 |

### Secrets Management

For v1, no external API keys or secrets are required beyond the AWS service credentials (which are provided automatically via IAM roles). If future integrations require API keys (e.g., a third-party email service for receipt forwarding in v2), those secrets will be stored in AWS Secrets Manager and referenced by Lambda functions at runtime.

The Cognito App Client secret, FCM API key, and APNs authentication key are stored as CDK context variables or SSM Parameter Store secure strings, not hardcoded in the CDK code or committed to version control.

### Deployment

CDK deployment follows the standard workflow:

1. `cdk synth` -- Synthesizes the CloudFormation template from CDK code. The output template can be reviewed before deployment.
2. `cdk diff` -- Shows the differences between the current deployed stack and the pending changes. This is critical for reviewing infrastructure changes before applying them.
3. `cdk deploy` -- Deploys the stack to the AWS account. Requires IAM credentials with sufficient permissions to create all resources.

For v1, deployments are performed manually by the developer. Automated CI/CD pipelines for infrastructure deployment are deferred to post-launch.

---

*This document is part of the Receipt & Warranty Vault documentation suite. For related documents, see the [docs directory listing](../CLAUDE.md#documentation-files).*
