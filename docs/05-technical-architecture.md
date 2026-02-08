# 05 - Technical Architecture

> Receipt & Warranty Vault -- Comprehensive Technical Architecture
>
> Status: Finalized | Last Updated: 2026-02-08

---

## Table of Contents

1. [System Architecture Overview](#1-system-architecture-overview)
2. [Client Architecture (Flutter)](#2-client-architecture-flutter)
3. [Server Architecture (AWS)](#3-server-architecture-aws)
4. [Cross-Cutting Concerns](#4-cross-cutting-concerns)
5. [Technology Stack Summary](#5-technology-stack-summary)

---

## 1. System Architecture Overview

### 1.1 High-Level Architecture Diagram

```
+-------------------------------------------------------------------+
|                        MOBILE CLIENT                               |
|  +-------------------------------------------------------------+  |
|  |                    Flutter Application                       |  |
|  |  +-------------+  +-----------+  +------------------------+ |  |
|  |  | Presentation|  | Business  |  | Data Layer             | |  |
|  |  | Layer       |->| Logic     |->| +-----------+          | |  |
|  |  | (UI/Widgets)|  | (BLoC /   |  | |Repository |          | |  |
|  |  +-------------+  |  Cubit)   |  | +-----+-----+          | |  |
|  |                    +-----------+  |       |                | |  |
|  |                                   | +-----v-----+ +------+| |  |
|  |                                   | |Local Data  | |Remote|| |  |
|  |                                   | |Source      | |Data  || |  |
|  |                                   | |(Drift/     | |Source|| |  |
|  |                                   | | SQLCipher) | |(Dio) || |  |
|  |                                   | +-----------+ +--+---+| |  |
|  |                                   +------------------------+ |  |
|  |  +-------------------+  +----------------------------------+ |  |
|  |  | On-Device OCR     |  | Background Services              | |  |
|  |  | ML Kit + Tesseract|  | WorkManager | Local Notifications | |  |
|  |  +-------------------+  +----------------------------------+ |  |
|  +-------------------------------------------------------------+  |
+-------------------------------|------------------------------------+
                                | HTTPS (TLS 1.2+)
                                v
+-------------------------------------------------------------------+
|                        AWS CLOUD (eu-west-1)                       |
|                                                                    |
|  +--------------------+       +-------------------------------+    |
|  |   Amazon Cognito   |<----->|   API Gateway (REST)          |    |
|  |   User Pool        |       |   + Cognito Authorizer        |    |
|  |   (Auth + Tokens)  |       +---------------+---------------+    |
|  +--------------------+                       |                    |
|                                               v                    |
|                               +---------------+---------------+    |
|                               |        AWS Lambda              |    |
|                               |   (Python 3.12 Functions)      |    |
|                               +---+-------+-------+-------+---+    |
|                                   |       |       |       |        |
|                    +--------------+--+ +--+--+ +--+---+ +-+-----+ |
|                    |   DynamoDB      | |  S3  | |Bedrock| | SNS  | |
|                    |   (ReceiptVault | | (img)| |(LLM) | |(push)| |
|                    |    single table)| |      | |      | |      | |
|                    +-----------------+ +--+---+ +------+ +------+ |
|                                           |                        |
|                                    +------+------+                 |
|                                    |  CloudFront  |                |
|                                    |  (CDN / OAC) |                |
|                                    +--------------+                |
|                                                                    |
|  +--------------------+   +--------------------+                   |
|  |   EventBridge      |   |   CloudWatch       |                   |
|  |   (Scheduled Jobs) |   |   (Logging/Metrics)|                   |
|  +--------------------+   +--------------------+                   |
+-------------------------------------------------------------------+
```

### 1.2 Component Interaction Summary

The system follows a clean client-server architecture with an offline-first mobile client and a fully serverless AWS backend. Every component has a single, well-defined responsibility:

**Mobile Client** -- The Flutter application is the user's primary interface. It captures receipts via the camera or file import, performs immediate on-device OCR, stores all data locally in an encrypted SQLite database (via Drift + SQLCipher), and queues changes for cloud synchronization. The app functions fully offline; cloud connectivity enhances but never gates functionality.

**API Gateway** -- The single entry point for all client-to-server communication. Every request passes through a Cognito authorizer that validates the JWT access token before the request reaches any Lambda function. The gateway enforces rate limiting, request validation, and payload size constraints.

**Lambda Functions** -- Stateless compute units that handle all server-side business logic: receipt CRUD operations, OCR refinement via Bedrock, warranty expiry checks, sync resolution, user account deletion cascades, and thumbnail generation. Python 3.12 is the runtime, chosen for its native Bedrock SDK support (boto3) and straightforward JSON handling.

**DynamoDB** -- The single source of truth for all structured data. A single-table design with six Global Secondary Indexes (GSIs) supports all access patterns without joins or complex queries. On-demand capacity mode keeps costs proportional to actual usage.

**S3 + CloudFront** -- Receipt images are stored in S3 with SSE-KMS encryption, versioning for soft-delete recovery, and Intelligent-Tiering for cost optimization. CloudFront serves images to clients via Origin Access Control (OAC), so S3 is never exposed directly. Thumbnails are generated by a Lambda trigger on upload.

**Bedrock** -- Amazon Bedrock hosts the Claude Haiku 4.5 model (with Sonnet 4.5 as fallback) for LLM-powered OCR refinement. The on-device OCR provides a fast initial extraction; Bedrock refines it into structured, high-confidence data when the device is online. Bedrock does not store or train on user data.

**Cognito** -- Manages user authentication (email/password, Google Sign-In, Apple Sign-In) via Amplify Flutter Gen 2. Issues JWT tokens (access, ID, refresh) that flow through the entire authorization chain.

**SNS + EventBridge** -- SNS delivers server-initiated push notifications via Firebase Cloud Messaging (FCM) and Apple Push Notification Service (APNs). EventBridge triggers scheduled Lambda functions for daily warranty expiry checks and weekly receipt summaries.

### 1.3 Separation of Concerns

| Boundary | Left Side | Right Side | Contract |
|----------|-----------|------------|----------|
| UI / Business Logic | Widgets render state | BLoCs emit state from events | BLoC states and events |
| Business Logic / Data | BLoCs call repository methods | Repositories abstract data source | Repository interface |
| Local / Remote Data | Drift database + file system | Dio HTTP client + S3 pre-signed URLs | Data source interface |
| Client / Server | Flutter app | API Gateway | REST API + JSON payloads |
| Server / Storage | Lambda functions | DynamoDB, S3, Bedrock | AWS SDK calls |
| Auth / Everything | Cognito tokens | All other components | JWT claims (userId) |

The key architectural principle is that the client never directly accesses AWS resources (DynamoDB, S3, Bedrock). Every interaction is mediated through API Gateway and Lambda, which enforce authorization, validate inputs, and maintain the integrity of the data model.

---

## 2. Client Architecture (Flutter)

### 2.1 App Layer Structure

```
+-------------------------------------------------------------------+
|                      PRESENTATION LAYER                            |
|  Screens, Widgets, Dialogs, Bottom Sheets                         |
|  - Receives state from BLoC, dispatches events                    |
|  - Zero business logic                                            |
|  - Handles navigation, animations, responsive layout              |
+-------------------------------+-----------------------------------+
                                |  BLoC States / Events
                                v
+-------------------------------------------------------------------+
|                     BUSINESS LOGIC LAYER                           |
|  BLoCs (complex flows) and Cubits (simple state)                  |
|  - Receipt capture flow (BLoC)                                    |
|  - Warranty tracking (BLoC)                                       |
|  - Search and filter (BLoC)                                       |
|  - Auth state (Cubit)                                             |
|  - Settings / theme (Cubit)                                       |
|  - Sync orchestration (BLoC)                                      |
+-------------------------------+-----------------------------------+
                                |  Repository method calls
                                v
+-------------------------------------------------------------------+
|                      REPOSITORY LAYER                              |
|  Abstract interfaces + concrete implementations                   |
|  - ReceiptRepository                                              |
|  - CategoryRepository                                             |
|  - AuthRepository                                                 |
|  - SyncRepository                                                 |
|  - SettingsRepository                                             |
|  - Decides: read from local or remote? Queue for sync?            |
|  - Merges local + remote data according to conflict rules         |
+---------------+-------------------------------+-------------------+
                |                               |
                v                               v
+-------------------------------+   +---------------------------+
|       LOCAL DATA SOURCE       |   |    REMOTE DATA SOURCE     |
| - Drift (SQLite + SQLCipher)  |   | - Dio HTTP client         |
|   for structured receipt data |   | - API Gateway endpoints   |
| - File system for cached      |   | - S3 pre-signed URL       |
|   images and thumbnails       |   |   uploads/downloads       |
| - flutter_secure_storage for  |   | - Amplify Cognito for     |
|   encryption keys and tokens  |   |   auth token management   |
+-------------------------------+   +---------------------------+
```

Each layer has strict dependency rules:

- **Presentation** depends on Business Logic only. It never imports repository or data source classes.
- **Business Logic** depends on Repository interfaces only. It never knows whether data comes from SQLite or an API.
- **Repository** depends on both data source interfaces. It contains the offline-first logic: always write to local first, queue remote writes for sync.
- **Data Sources** depend on external packages only (Drift, Dio, Amplify). They are the lowest layer and have no upward dependencies.

### 2.2 State Management: BLoC Pattern

**Why BLoC for this application:**

The BLoC (Business Logic Component) pattern is the recommended state management approach for Receipt & Warranty Vault for five specific reasons:

1. **Complex async flows with clear state transitions.** Receipt capture involves a multi-step pipeline: image selection, cropping, compression, on-device OCR, display to user, queuing for cloud refinement. Each step produces a distinct state (capturing, processing, extracting, extracted, refining, complete) that the UI must reflect. BLoC's explicit event-in / state-out model makes these transitions traceable and testable.

2. **Offline-first sync requires observable state.** The sync engine operates in the background and can produce state changes at any time (sync started, conflict detected, sync complete, sync failed). BLoC's stream-based architecture lets multiple widgets react to sync state changes without polling or manual notification wiring.

3. **Separation of business logic from Flutter framework.** BLoC classes are plain Dart; they do not import Flutter. This means all business logic -- OCR pipeline orchestration, conflict resolution, warranty calculation -- can be unit-tested without widget testing infrastructure.

4. **Event sourcing for debugging.** Every user action is an explicit event (AddReceiptRequested, WarrantyReminderSet, SyncTriggered). In development and testing, the full event stream can be logged, replayed, and inspected. This is valuable for diagnosing sync conflicts and OCR pipeline issues.

5. **Proven ecosystem and tooling.** The flutter_bloc package provides BlocObserver for centralized logging, BlocProvider for dependency injection via the widget tree, and hydrated_bloc for persisting BLoC state across app restarts (useful for maintaining filter/sort preferences).

**When to use Cubit instead of BLoC:** Simple, non-event-driven state such as theme toggling, locale switching, and app-lock status uses Cubit (a simplified BLoC without the event class). The decision rule: if the state change is a direct 1:1 response to a single action with no intermediate states, use Cubit. If multiple events can produce the same state or the flow has intermediate states, use BLoC.

### 2.3 Local Data Layer

**Drift (SQLite + SQLCipher):**

All structured receipt data is stored locally in an encrypted SQLite database managed by Drift. SQLCipher provides AES-256 encryption at the database file level, meaning the data is encrypted at rest even if the device is compromised. The encryption key is derived from a securely stored secret managed by flutter_secure_storage (Keychain on iOS, EncryptedSharedPreferences on Android).

Drift was chosen over alternatives (Isar, Hive, ObjectBox) because:
- Isar is abandoned/maintenance mode as of 2025.
- Drift supports SQLCipher encryption natively via the sqlcipher_flutter_libs package.
- Drift provides FTS5 (Full-Text Search 5) virtual tables, which power the app's keyword search over store names, OCR text, notes, and tags.
- Drift supports typed, compile-time-checked SQL queries with Dart code generation.
- Drift has a robust migration system for schema evolution across app updates.

**File system for cached images:**

Receipt images and thumbnails downloaded from CloudFront are cached in the app's private documents directory. A simple LRU (Least Recently Used) eviction policy prevents unbounded storage growth. The cache target size is configurable in settings (default: 500 MB). Original images are always available from S3; the local cache is a performance optimization, not a source of truth (except for images captured offline that have not yet been uploaded).

### 2.4 Network Layer

**Dio HTTP Client:**

All network communication (except Cognito auth, which uses Amplify SDK directly) flows through a single Dio instance configured with the following interceptors, applied in order:

1. **AuthInterceptor** -- Reads the current Cognito access token from Amplify, attaches it as a Bearer token in the Authorization header. If the token is expired, triggers a silent refresh via Amplify before retrying the request. If refresh fails, emits an "unauthenticated" event to the AuthBloc, which navigates the user to the login screen.

2. **ConnectivityInterceptor** -- Before sending any request, checks network reachability using connectivity_plus (network type detection) and internet_connection_checker_plus (actual internet verification via DNS lookup). If offline, the request is rejected immediately with a custom OfflineException, which the repository layer catches and handles by falling back to local data.

3. **RetryInterceptor** -- For transient server errors (HTTP 500, 502, 503, 504) and network timeouts, retries the request up to 3 times with exponential backoff (1s, 2s, 4s) plus random jitter (0-500ms). Idempotent requests (GET, PUT, DELETE) are retried automatically; POST requests are only retried if the server supports idempotency keys (which all write endpoints do via the receiptId).

4. **LoggingInterceptor** -- In debug builds, logs request method, URL, status code, and response time. In release builds, logs only errors. Sensitive data (tokens, image payloads) is never logged.

**Base configuration:**
- Base URL: `https://api.receiptvault.app/v1` (configured per environment)
- Connect timeout: 10 seconds
- Receive timeout: 30 seconds (increased for Bedrock refinement endpoint)
- Content-Type: application/json (except image uploads, which use multipart or pre-signed URL PUT)

### 2.5 OCR Pipeline

The OCR pipeline is a multi-stage process designed to give the user immediate results while improving accuracy in the background.

```
+----------+    +-------------+    +-----------+    +------------------+
| 1. IMAGE |    | 2. PRE-     |    | 3. ON-    |    | 4. STRUCTURED    |
| CAPTURE  |--->| PROCESSING  |--->| DEVICE    |--->| TEXT DISPLAY     |
| (Camera/ |    | (Crop,      |    | OCR       |    | (Show to user,   |
|  Gallery/ |    | Rotate,     |    | ML Kit +  |    |  allow manual    |
|  Files)  |    | Compress)   |    | Tesseract |    |  editing)        |
+----------+    +-------------+    +-----------+    +--------+---------+
                                                             |
                                                    User sees results
                                                    immediately. Then:
                                                             |
                                                             v
                                                    +--------+---------+
                                                    | 5. QUEUE FOR     |
                                                    | CLOUD LLM        |
                                                    | REFINEMENT       |
                                                    | (When online,    |
                                                    |  send to Bedrock |
                                                    |  via API)        |
                                                    +--------+---------+
                                                             |
                                                             v
                                                    +--------+---------+
                                                    | 6. MERGE LLM     |
                                                    | RESULTS           |
                                                    | (Update fields,   |
                                                    |  respect user     |
                                                    |  edits, show      |
                                                    |  confidence)      |
                                                    +------------------+
```

**Stage 1 -- Image Capture:**
The user captures a receipt via the device camera (using image_picker), selects from the photo gallery, or imports a file (image or PDF). PDF pages are rasterized to images before proceeding.

**Stage 2 -- Preprocessing:**
The captured image is processed to maximize OCR accuracy:
- **Crop/Rotate:** The user is presented with an interactive crop and rotation interface (image_cropper) to frame the receipt precisely.
- **Compression:** The image is compressed to JPEG at 85% quality using flutter_image_compress. This typically produces a 1-2 MB file from a 5-10 MB camera image, preserving enough detail for OCR while being practical for storage and upload.
- **GPS EXIF Stripping:** All GPS/location EXIF metadata is removed from the image before storage or upload. This is a privacy measure -- receipt images should never leak the user's location. Non-location EXIF data (orientation, camera model) is preserved for proper display rendering.

**Stage 3 -- On-Device OCR:**
Two OCR engines run in parallel on the preprocessed image:
- **Google ML Kit Text Recognition** handles Latin script characters and numbers. It is fast (sub-second), runs fully on-device, and produces good results for English-language receipts.
- **Tesseract OCR** (via flutter_tesseract_ocr) handles Greek script. ML Kit does not support Greek, so Tesseract fills this gap. Tesseract is slower (1-3 seconds) but provides adequate accuracy for Greek store names, addresses, and product descriptions.

The outputs from both engines are merged: ML Kit results are used for numbers, prices, and Latin text; Tesseract results supplement with Greek text blocks. A simple heuristic assigns each text block to the engine that produced the higher-confidence result for that region of the image.

**Stage 4 -- Structured Text Display:**
The merged OCR output is immediately displayed to the user in editable fields: store name, purchase date, total amount, and raw text. The user can correct any field. This is the "instant gratification" step -- the user sees results within seconds of capturing the receipt, with no network dependency.

**Stage 5 -- Queue for Cloud LLM Refinement:**
If the user's storage mode is "Cloud + Device" and the device is online (or becomes online later), the raw OCR text and the receipt image are sent to the Bedrock refinement endpoint via the API. If offline, the refinement request is queued in the local sync_queue table and processed when connectivity is restored.

**Stage 6 -- Merge LLM Results:**
When Bedrock returns its refined extraction (store name, date, total, currency, itemized list), the results are merged with local data according to the conflict resolution tiers (see doc 06). If the user has already manually edited a field (tracked via userEditedFields), the user's version is preserved. If the user has not edited a field, the LLM's higher-confidence extraction replaces the on-device OCR result. The user is notified via a subtle UI indicator that the receipt has been "enhanced by AI" and can review the changes.

### 2.6 Background Services

**WorkManager (Background Sync):**

The workmanager package schedules periodic background tasks that run even when the app is not in the foreground:

- **Periodic sync task:** Runs every 15 minutes (configurable) when the device has network connectivity. Processes the sync_queue (pending uploads, updates, deletes) and pulls down any changes from the server (delta sync based on updatedAt). Constraints: requires network connectivity, does not require charging (sync payloads are small).

- **Full reconciliation task:** Runs once every 7 days. Performs a complete comparison of local and server state to catch any items missed by delta sync. Constraints: requires network connectivity and the device to be charging (this task is more resource-intensive).

- **Image upload task:** Processes queued image uploads. Requests a pre-signed URL from the API, uploads the image directly to S3 via PUT, confirms the upload via the API. Constraints: requires network connectivity; prefers unmetered (Wi-Fi) connections for large uploads but will use cellular if the user has enabled it in settings.

**flutter_local_notifications (Warranty Reminders):**

Local notifications are scheduled on the device for warranty expiry reminders. When a receipt is created or its warranty information is updated, the app calculates the reminder dates and schedules local notifications accordingly.

Default reminder schedule (user-configurable):
- 30 days before warranty expiry
- 7 days before warranty expiry
- 1 day before warranty expiry
- On the day of expiry

Local notifications work entirely offline -- they do not depend on server connectivity or push notification infrastructure. This ensures that the app's hero feature (warranty tracking) works regardless of network conditions.

**Server-Side Notifications (SNS + EventBridge):**

In addition to local notifications, the server runs a daily EventBridge-triggered Lambda that checks all users' warranties expiring within the next 30 days and sends push notifications via SNS (which routes to FCM for Android and APNs for iOS). This serves as a backup to local notifications and covers edge cases where the user has reinstalled the app or cleared local data. A weekly summary notification ("You have 3 warranties expiring this month") is also sent via EventBridge + SNS.

---

## 3. Server Architecture (AWS)

### 3.1 API Gateway

**Type:** REST API (not HTTP API), chosen for Cognito authorizer integration, request validation, and usage plan support.

**Cognito Authorizer:** Every endpoint (except health check) requires a valid Cognito access token. The authorizer validates the token's signature, expiration, and audience claim. The Lambda function receives the authenticated userId (Cognito `sub` claim) in the request context -- it never trusts a userId from the request body or path parameters.

**Endpoints** are organized by resource:
- `/receipts` -- CRUD operations for receipts
- `/receipts/sync` -- Delta sync and full reconciliation
- `/receipts/{id}/refine` -- LLM OCR refinement trigger
- `/receipts/{id}/upload-url` -- Pre-signed URL generation for S3 image upload
- `/categories` -- User category management
- `/user/export` -- Data export
- `/user/delete` -- Account deletion cascade

**Rate limiting:** 100 requests per second per user (burst: 200). This is generous for a single-user app but prevents abuse.

**Payload limits:** 10 MB maximum request body (covers base64-encoded images in refinement requests, though the preferred path is pre-signed URL upload).

### 3.2 Lambda Functions

**Runtime:** Python 3.12, chosen for:
- Native boto3 SDK with first-class Bedrock support.
- Fast cold starts (typically under 500ms with optimized packaging).
- Simple JSON handling with Python's built-in json module and Pydantic for validation.
- Team familiarity with Python over Node.js for data processing tasks.

**Function inventory:**

| Function | Trigger | Purpose | Memory | Timeout |
|----------|---------|---------|--------|---------|
| receipt-crud | API Gateway | Create, read, update, delete receipts in DynamoDB | 256 MB | 10s |
| receipt-sync | API Gateway | Delta sync and full reconciliation | 512 MB | 30s |
| ocr-refine | API Gateway | Send OCR text + image to Bedrock, parse response, update DynamoDB | 512 MB | 60s |
| upload-url | API Gateway | Generate pre-signed S3 URL with content-type and size constraints | 128 MB | 5s |
| thumbnail-gen | S3 Event (PUT) | Generate 200x300px JPEG 70% thumbnail from uploaded image | 512 MB | 15s |
| warranty-check | EventBridge (daily) | Query GSI-4 for warranties expiring in 30 days, send SNS notifications | 256 MB | 60s |
| weekly-summary | EventBridge (weekly) | Aggregate user stats, send weekly summary via SNS | 256 MB | 60s |
| user-delete | API Gateway | Cascade delete: Cognito user, DynamoDB items (batch), S3 objects (all versions) | 512 MB | 300s |
| category-crud | API Gateway | Create, read, update, delete custom categories | 128 MB | 5s |
| export-data | API Gateway | Query all user items, generate JSON/CSV, package images, return download URL | 1024 MB | 300s |

**Error handling:** Every Lambda function wraps its handler in a try/except block. Unhandled exceptions return HTTP 500 with a generic error message (no stack traces in production). Failed asynchronous invocations (S3 triggers, EventBridge) are routed to a Dead Letter Queue (SQS) for manual inspection and retry.

**Layers:** Common dependencies (boto3 extensions, Pydantic, Pillow for thumbnail generation, shared utility functions) are packaged in a Lambda Layer to reduce deployment package size and share code across functions.

### 3.3 DynamoDB

**Table:** `ReceiptVault` -- single-table design with 6 GSIs.

Full schema details are in [doc 06 -- Data Model](./06-data-model.md). The key architectural points:

- **On-demand capacity mode** eliminates the need to provision read/write capacity units. At 5 test users, this keeps costs under $0.01/month. At 1,000 users, projected cost is approximately $0.16/month.
- **Single-table design** means receipts, category metadata, and any future entity types (e.g., shared vault members in v2) all live in the same table, differentiated by their sort key prefix. This eliminates cross-table joins and keeps the infrastructure simple.
- **TTL attribute** enables automatic cleanup of soft-deleted items after 30 days, with no Lambda function or scheduled job required.
- **Six GSIs** cover all 13 identified access patterns. GSI-6 (ByUpdatedAt) uses KEYS_ONLY projection to minimize storage cost, since it is only used for delta sync queries.

### 3.4 S3 Image Storage

**Bucket:** `receiptvault-images-eu-west-1` (single bucket for both originals and thumbnails, separated by key prefix).

**Key structure:**
```
originals/{userId}/{receiptId}/{imageIndex}.jpg
thumbnails/{userId}/{receiptId}/{imageIndex}_thumb.jpg
```

**Security and encryption:**
- All public access is blocked at the bucket level.
- SSE-KMS encryption with a Customer Managed Key (CMK) and Bucket Keys enabled (reduces KMS API call costs by up to 99%).
- Bucket policy enforces TLS-only access (denies HTTP) and KMS-only encryption (denies uploads without SSE-KMS headers).
- IAM access is restricted to the specific Lambda execution roles that need it.
- S3 access logging is enabled for audit trail.

**Versioning and lifecycle:**
- S3 Versioning is enabled to support soft-delete recovery. When a receipt is soft-deleted, the image objects are not deleted from S3 -- they remain accessible for 30 days. After 30 days, a lifecycle rule (NoncurrentVersionExpiration) automatically removes old versions.
- S3 Intelligent-Tiering is applied to the `originals/` prefix. Receipts accessed frequently (recently scanned) stay in the Frequent Access tier; older receipts automatically transition to Infrequent Access, saving approximately 40% on storage.
- Thumbnails remain in S3 Standard (they are small and accessed frequently for list views).

**CloudFront distribution:**
- Origin Access Control (OAC) ensures that only CloudFront can read from the S3 bucket. Direct S3 URLs are never exposed to clients.
- Cache behavior: images are cached at CloudFront edge locations with a 30-day TTL. Since receipt images are immutable after upload, cache invalidation is not needed under normal operation.
- The free tier includes 1 TB/month of data transfer, which is sufficient for the projected user base.

### 3.5 Bedrock (LLM-Powered OCR Refinement)

**Model selection:**
- **Primary:** Claude Haiku 4.5 (anthropic.claude-haiku-4-5-v1) -- fast, cost-effective at approximately $0.004 per receipt.
- **Fallback:** Claude Sonnet 4.5 (anthropic.claude-sonnet-4-5-v1) -- higher accuracy for ambiguous or complex receipts, approximately 10x the cost of Haiku.

**Invocation flow:**
1. Lambda receives the raw OCR text and (optionally) the receipt image via base64 or S3 reference.
2. A structured prompt instructs the model to extract: store name, purchase date, total amount, currency, itemized line items, and any warranty information.
3. The model responds with a JSON object containing the extracted fields and a confidence score (0-100).
4. Lambda validates the response schema, stores the extracted fields in DynamoDB, and updates the receipt record.

**Fallback logic:** If Haiku returns a confidence score below 60, the same request is automatically retried with Sonnet. If Sonnet also returns low confidence, the receipt is marked as "needs manual review" and the user is notified.

**Privacy:** Bedrock does not store input or output data. AWS has confirmed that data sent to Bedrock is not used for model training. All processing occurs within the eu-west-1 region.

### 3.6 Cognito Authentication

**User Pool:** Cognito User Pool in Lite tier (free for up to 10,000 monthly active users).

**Sign-in methods:**
- Email + password (with Cognito's built-in password policy)
- Google Sign-In (via Cognito federated identity provider)
- Apple Sign-In (required by Apple if Google Sign-In is offered on iOS)

**Token configuration:**
- Access token: 1-hour expiry
- ID token: 1-hour expiry
- Refresh token: 30-day expiry (configurable up to 90 days)

**Client integration:** Amplify Flutter Gen 2 handles all Cognito interactions -- sign-up, sign-in, token refresh, sign-out, and account deletion. The Amplify SDK transparently refreshes expired access tokens using the refresh token, so the app almost never needs to prompt the user to re-authenticate.

### 3.7 SNS (Push Notifications)

SNS serves as the server-side push notification dispatch:
- A platform application is configured for FCM (Android) and APNs (iOS).
- When a user signs in, the app registers its device token with a `/notifications/register` endpoint, which creates an SNS platform endpoint.
- Lambda functions (warranty-check, weekly-summary) publish messages to the user's SNS endpoint.
- SNS delivers the notification via FCM or APNs to the device.
- The app receives the notification via firebase_messaging and displays it using flutter_local_notifications.

### 3.8 EventBridge (Scheduled Jobs)

Two scheduled rules:

| Rule | Schedule | Target Lambda | Purpose |
|------|----------|---------------|---------|
| daily-warranty-check | `cron(0 8 * * ? *)` (08:00 UTC daily) | warranty-check | Query GSI-4 for warranties expiring within 30 days; send reminder notifications |
| weekly-summary | `cron(0 9 ? * MON *)` (09:00 UTC every Monday) | weekly-summary | Aggregate user stats (total receipts, active warranties, total spend this month); send summary notification |

---

## 4. Cross-Cutting Concerns

### 4.1 Authentication Flow

```
+--------+        +----------+       +-----------+       +--------+
| Client |        | Cognito  |       | API       |       | Lambda |
| (App)  |        | User Pool|       | Gateway   |       |        |
+---+----+        +----+-----+       +-----+-----+       +---+----+
    |                  |                   |                   |
    | 1. Sign in       |                   |                   |
    | (email/password  |                   |                   |
    |  or social)      |                   |                   |
    +----------------->|                   |                   |
    |                  |                   |                   |
    | 2. Tokens        |                   |                   |
    | (access, id,     |                   |                   |
    |  refresh)        |                   |                   |
    |<-----------------+                   |                   |
    |                  |                   |                   |
    | 3. API request   |                   |                   |
    | (Authorization:  |                   |                   |
    |  Bearer <access  |                   |                   |
    |  token>)         |                   |                   |
    +------------------------------------>|                   |
    |                  |                   |                   |
    |                  | 4. Validate token |                   |
    |                  |<------------------+                   |
    |                  |                   |                   |
    |                  | 5. Token valid,   |                   |
    |                  | return claims     |                   |
    |                  +------------------>|                   |
    |                  |                   |                   |
    |                  |                   | 6. Invoke with    |
    |                  |                   | userId from       |
    |                  |                   | token claims      |
    |                  |                   +------------------>|
    |                  |                   |                   |
    |                  |                   |  7. Process       |
    |                  |                   |  request using    |
    |                  |                   |  trusted userId   |
    |                  |                   |<------------------+
    |                  |                   |                   |
    | 8. Response      |                   |                   |
    |<-------------------------------------+                   |
    |                  |                   |                   |
```

**Key security principle:** The userId is never sent by the client in the request body or URL. It is always extracted from the validated Cognito token by API Gateway and passed to Lambda in the request context. This prevents impersonation attacks.

**Token refresh:** Amplify Flutter handles token refresh transparently. When an access token expires, the SDK uses the refresh token to obtain new tokens without user interaction. If the refresh token itself is expired (after 30 days of inactivity), the user is prompted to sign in again.

**Offline authentication:** When the device is offline, the app relies on the locally cached tokens and the biometric/PIN lock (via local_auth). The app does not require network connectivity to open and view locally stored receipts.

### 4.2 Error Handling Strategy

**Client-Side:**

| Error Type | Handling |
|------------|----------|
| Network timeout | Retry with exponential backoff (1s, 2s, 4s) + jitter. Max 3 retries. |
| HTTP 401 (Unauthorized) | Trigger token refresh via Amplify. If refresh fails, navigate to login. |
| HTTP 409 (Conflict) | Trigger conflict resolution flow (see doc 06 conflict model). |
| HTTP 429 (Rate Limited) | Back off for the duration specified in the Retry-After header. |
| HTTP 5xx (Server Error) | Retry with exponential backoff. If all retries fail, queue for background retry. |
| Offline | Save operation to sync_queue. Process when connectivity is restored. |
| OCR failure | Show error toast, allow user to manually enter receipt details. |
| Image capture failure | Show error dialog with option to retry or import from gallery. |

All errors are displayed to the user via non-intrusive snackbar notifications (for recoverable errors) or blocking dialogs (for errors that require user action). Error messages are localized in English and Greek.

**Server-Side:**

| Error Type | Handling |
|------------|----------|
| Lambda unhandled exception | Catch-all handler returns HTTP 500 with generic error. Log full stack trace to CloudWatch. |
| DynamoDB throttling | AWS SDK automatic retry with exponential backoff (built into boto3). |
| Bedrock model error | Retry once with the same model. If still failing, try fallback model. If both fail, return partial results with low confidence. |
| S3 upload failure | Return error to client; client retries the upload with a new pre-signed URL. |
| Failed async invocation | Route to SQS Dead Letter Queue for manual inspection. CloudWatch alarm triggers on DLQ depth > 0. |

### 4.3 Logging and Monitoring

**Server-side (CloudWatch):**
- All Lambda functions log to CloudWatch Logs with structured JSON logging (timestamp, request ID, userId, action, duration, error details).
- CloudWatch Metrics track: Lambda invocation count, error rate, duration (P50/P90/P99), DynamoDB consumed capacity, S3 request counts, Bedrock invocation latency.
- CloudWatch Alarms are configured for: Lambda error rate > 5%, DLQ depth > 0, Bedrock latency P99 > 10s, and any 5xx errors from API Gateway.

**Client-side (Local Logging):**
- In debug builds: verbose logging of all BLoC events/states, network requests, OCR pipeline stages, and sync operations via Dart's built-in logging package.
- In release builds: error-level logging only, stored in a rotating log file (max 5 MB). The user can optionally share this log file with support via an in-app "Report Issue" feature.
- No client logs are automatically uploaded to the server. User privacy is maintained.

### 4.4 Image Pipeline (End-to-End)

```
1. CAPTURE          User takes photo or imports image
      |
      v
2. CROP/ROTATE      User adjusts framing (image_cropper)
      |
      v
3. COMPRESS         JPEG 85% quality (flutter_image_compress)
                    Typical output: 1-2 MB
      |
      v
4. STRIP GPS        Remove GPS/location EXIF metadata
                    Preserve orientation EXIF
      |
      v
5. ENCRYPT          Store in Drift-managed encrypted file cache
   LOCALLY          (SQLCipher AES-256 for metadata,
                     file system for image bytes)
      |
      v
6. DISPLAY          Show to user immediately (from local cache)
      |
      v
7. REQUEST          Client calls /receipts/{id}/upload-url
   PRE-SIGNED       Lambda generates S3 pre-signed PUT URL
   URL              (10-minute expiry, content-type: image/jpeg,
                     max size: 10 MB)
      |
      v
8. UPLOAD           Client PUTs image directly to S3
   TO S3            via pre-signed URL
                    SSE-KMS encryption applied automatically
                    by S3 bucket policy
      |
      v
9. THUMBNAIL        S3 PUT event triggers thumbnail-gen Lambda
   GENERATION       Lambda reads original, resizes to 200x300px,
                    compresses to JPEG 70%, writes to
                    thumbnails/ prefix in same bucket
      |
      v
10. CDN             CloudFront caches both original and thumbnail
    DELIVERY        at edge locations (OAC restricts S3 direct access)
                    Client downloads via CloudFront URL
```

**Privacy guarantees at each stage:**
- Stage 4 ensures no location metadata leaves the device.
- Stage 5 ensures data at rest on the device is encrypted.
- Stage 8 ensures data in transit is encrypted (HTTPS + SSE-KMS).
- Stage 10 ensures images are only accessible via authenticated CloudFront requests.

---

## 5. Technology Stack Summary

### 5.1 Client Technologies

| Technology | Version / Tier | Purpose |
|------------|---------------|---------|
| Flutter | 3.x (latest stable) | Cross-platform UI framework (iOS + Android) |
| Dart | 3.x (latest stable) | Programming language |
| flutter_bloc | Latest stable | BLoC/Cubit state management |
| Drift | Latest stable | SQLite ORM with type-safe queries, migrations, FTS5 |
| sqlcipher_flutter_libs | Latest stable | SQLCipher (AES-256) encryption for Drift database |
| google_mlkit_text_recognition | Latest stable | On-device OCR for Latin script and numbers |
| flutter_tesseract_ocr | Latest stable | On-device OCR for Greek script |
| amplify_auth_cognito | Gen 2 (latest) | Cognito authentication (email, Google, Apple sign-in) |
| local_auth | Latest stable | Biometric (fingerprint, Face ID) and PIN app lock |
| firebase_messaging | Latest stable | Push notification reception (FCM) |
| flutter_local_notifications | Latest stable | Offline warranty reminder notifications |
| connectivity_plus | Latest stable | Network type detection (Wi-Fi, cellular, none) |
| internet_connection_checker_plus | Latest stable | Actual internet reachability verification |
| workmanager | Latest stable | Background task scheduling (sync, uploads) |
| dio | Latest stable | HTTP client with interceptors |
| image_picker | Latest stable | Camera and gallery image capture |
| image_cropper | Latest stable | User-guided crop and rotation |
| flutter_image_compress | Latest stable | JPEG compression and EXIF manipulation |
| image | Latest stable | Programmatic image processing |
| uuid | Latest stable | Client-side UUID v4 generation |
| flutter_secure_storage | Latest stable | Secure storage for encryption keys and tokens |

### 5.2 Server Technologies

| Technology | Version / Tier | Purpose |
|------------|---------------|---------|
| AWS API Gateway | REST API | HTTPS entry point, request routing, Cognito authorization |
| AWS Lambda | Python 3.12 | Serverless compute for all backend logic |
| Amazon DynamoDB | On-demand capacity | NoSQL database, single-table design, 6 GSIs |
| Amazon S3 | Standard + Intelligent-Tiering | Receipt image storage with SSE-KMS encryption |
| Amazon CloudFront | Standard distribution | CDN for image delivery with OAC |
| Amazon Bedrock | Claude Haiku 4.5 / Sonnet 4.5 | LLM-powered OCR refinement |
| Amazon Cognito | User Pool, Lite tier | User authentication and authorization |
| Amazon SNS | Standard | Server-initiated push notifications via FCM/APNs |
| Amazon EventBridge | Scheduler | Cron jobs for warranty checks and weekly summaries |
| Amazon SQS | Standard | Dead Letter Queue for failed Lambda invocations |
| AWS KMS | Customer Managed Key + Bucket Keys | S3 encryption key management |
| Amazon CloudWatch | Logs, Metrics, Alarms | Server-side logging, monitoring, and alerting |
| AWS IAM | Policies + Roles | Fine-grained access control for all AWS services |

### 5.3 Infrastructure and Tooling

| Technology | Version / Tier | Purpose |
|------------|---------------|---------|
| AWS CDK or SAM | Latest stable | Infrastructure as Code for all AWS resources |
| GitHub Actions | Free tier | CI/CD pipeline for Lambda deployment and Flutter builds |
| Firebase (FCM only) | Free tier | Push notification delivery to Android and iOS devices |
| Pillow (Python) | Latest stable | Server-side image processing for thumbnail generation |
| Pydantic (Python) | v2 | Request/response validation in Lambda functions |
| boto3 (Python) | Bundled with Lambda | AWS SDK for DynamoDB, S3, Bedrock, SNS, Cognito interactions |

### 5.4 Development Region

| Aspect | Value |
|--------|-------|
| Primary AWS region | eu-west-1 (Ireland) |
| Rationale | GDPR compliance, proximity to initial user base |
| Multi-region | Deferred to v2.0 |

---

*This document defines the technical architecture for Receipt & Warranty Vault. For data model details, see [06 - Data Model](./06-data-model.md). For API endpoint specifications, see [07 - API Design](./07-api-design.md). For AWS infrastructure provisioning, see [08 - AWS Infrastructure](./08-aws-infrastructure.md).*
