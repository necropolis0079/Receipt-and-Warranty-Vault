# 10 -- Offline & Sync Architecture

**Document**: Offline-First Design and Sync Engine Architecture
**Version**: 1.0
**Status**: Pre-Implementation (Documentation Phase)
**Last Updated**: 2026-02-08

---

## Table of Contents

1. [Design Philosophy](#design-philosophy)
2. [Network Detection](#network-detection)
3. [Local Storage Architecture](#local-storage-architecture)
4. [Sync Engine Design](#sync-engine-design)
5. [Conflict Resolution Algorithm](#conflict-resolution-algorithm)
6. [Sync Queue Management](#sync-queue-management)
7. [Background Sync](#background-sync)
8. [Edge Cases](#edge-cases)

---

## Design Philosophy

Receipt & Warranty Vault is built as an offline-first application. This is not a marketing distinction or a feature flag -- it is a foundational architectural decision that shapes every layer of the system, from the database schema on the device to the API contract with the cloud backend.

### Offline-First Means Offline-Primary

The term "offline-first" is often misunderstood as "works offline sometimes" or "degrades gracefully without connectivity." In this architecture, it means something stronger: the app is designed to operate without any network connection as its default state. Online connectivity is treated as an enhancement -- a way to back up data, sync across devices, and leverage cloud-powered LLM extraction -- not as a prerequisite for core functionality.

A user can install the app, create a local-only account (device-only storage mode), capture hundreds of receipts, search and browse their vault, track warranty expiry dates, receive local notification reminders, and manage their entire receipt archive without ever connecting to the internet. The app is not waiting for the network. The network, when available, makes the app better -- but its absence never makes the app worse.

### Two Sources of Truth

The architecture recognizes that in an offline-first system, there is no single global source of truth. Instead, there are two:

- **The local database (Drift/SQLCipher)** is the source of truth for the client. Every read operation in the app -- displaying a receipt list, showing warranty details, performing a search -- reads from the local database, never from a network call. The app's UI is always fast and always available because it never waits for a server response to render content.
- **The cloud database (DynamoDB)** is the source of truth for the server. It represents the canonical, authoritative state of the user's data as known to the backend. When a second device syncs, it receives data from DynamoDB, not from the first device directly.

These two sources of truth will inevitably diverge when the device is offline or when multiple devices edit the same data simultaneously. The sync engine exists to reconcile these divergences, bringing both sources back into agreement using a deterministic conflict resolution algorithm.

### Seamless User Experience

The user should never encounter a blocking "you're offline" dialog that prevents them from using the app. Offline and online states are communicated subtly -- through a small indicator in the UI, through a "pending sync" badge on modified receipts, or through a brief toast notification when connectivity is restored and sync begins. The user's workflow is never interrupted by connectivity changes.

When the user captures a receipt while offline, the receipt is saved locally and appears immediately in their vault. When connectivity returns, the receipt syncs to the cloud silently in the background. The user does not need to take any action, monitor sync progress, or retry failed operations manually (unless an unrecoverable error occurs after maximum retries).

---

## Network Detection

Determining whether the device has a functioning internet connection is more nuanced than checking whether Wi-Fi or cellular data is enabled. The app uses a two-layer network detection strategy to distinguish between having a network interface and actually being able to reach the internet.

### Layer 1: connectivity_plus (Network Type Detection)

The connectivity_plus Flutter package detects the type of network connection available on the device: Wi-Fi, cellular (mobile data), ethernet (for emulators and specialized devices), or none. This is a fast, low-cost check that tells the app whether the device has any active network interface.

However, the presence of a network interface does not guarantee internet access. A device can be connected to a Wi-Fi network that has no internet access (captive portals, local-only networks, or networks with firewall restrictions). A cellular connection can be active but have no data connectivity (out of coverage, data cap reached, or carrier-level restrictions).

### Layer 2: internet_connection_checker_plus (Internet Verification)

The internet_connection_checker_plus package performs an actual reachability check by attempting to connect to known, reliable internet endpoints. This confirms whether the device can actually reach the internet, not just whether a network interface is active.

This check is more expensive than connectivity_plus (it requires an actual network request), so it is not performed continuously. It is triggered when:

- connectivity_plus reports a change in network type (for example, switching from none to Wi-Fi).
- A sync operation fails with a network error.
- The app resumes from background.

### Network States

The combination of these two layers produces three meaningful states:

| State | Meaning | App Behavior |
|-------|---------|-------------|
| **Online** | Network interface active AND internet reachable | Sync engine active, cloud operations proceed normally |
| **Offline** | No network interface OR internet not reachable | Sync engine paused, all operations local-only, changes queued |
| **Limited** | Network interface active BUT internet not reachable | Treated as offline for sync purposes, but app may display a distinct "limited connectivity" indicator to help the user understand the situation |

### State Change Triggers

When the network state changes, the following actions are triggered:

- **Offline to Online**: The sync engine is activated. Any operations queued in the sync_queue table are processed. A delta sync pull is initiated to check for server-side changes that may have occurred while the device was offline.
- **Online to Offline**: The sync engine is paused gracefully. Any in-progress sync operations are allowed to complete or fail (with appropriate retry logic). New operations are queued locally.
- **Any state to Limited**: Treated as a transition to offline. The limited state exists primarily for user communication, not for different app behavior.

---

## Local Storage Architecture

The local storage layer is the foundation of the offline-first architecture. It stores all user data on the device in an encrypted database, manages a queue of pending sync operations, and caches receipt images for offline access.

### Drift Database (SQLite + SQLCipher AES-256)

The local database is implemented using Drift, a reactive persistence library for Flutter that generates type-safe Dart code from SQL table definitions. Drift operates on top of SQLite, and the app uses the sqlcipher_flutter_libs package to replace the standard SQLite library with SQLCipher, which provides transparent AES-256 encryption of the entire database file.

The database contains four primary tables:

#### receipts Table

The receipts table is the core data store, mirroring the attributes stored in DynamoDB with additional client-specific fields for sync management.

| Column | Type | Description |
|--------|------|-------------|
| id | TEXT (UUID) | Client-generated unique identifier (matches DynamoDB receiptId) |
| userId | TEXT | The authenticated user's ID |
| storeName | TEXT | Merchant or store name (from OCR/LLM or user input) |
| purchaseDate | TEXT (ISO 8601) | Date of purchase |
| totalAmount | REAL | Total purchase amount |
| currency | TEXT | Currency code (EUR, USD, etc.) |
| category | TEXT | Receipt category (from defaults or user-created) |
| warrantyMonths | INTEGER | Warranty duration in months (null if no warranty) |
| warrantyExpiryDate | TEXT (ISO 8601) | Calculated warranty expiry date |
| ocrRawText | TEXT | Raw text extracted by on-device OCR |
| extractedMerchantName | TEXT | Merchant name extracted by LLM |
| extractedDate | TEXT | Date extracted by LLM |
| extractedTotal | TEXT | Total amount extracted by LLM |
| llmConfidence | REAL | LLM's confidence score for the extraction |
| userNotes | TEXT | User-written notes |
| userTags | TEXT (JSON array) | User-assigned tags |
| isFavorite | INTEGER (boolean) | Whether the user marked this as favorite |
| userEditedFields | TEXT (JSON array) | List of field names the user has manually edited |
| status | TEXT | Receipt status (active, returned, deleted) |
| imageKeys | TEXT (JSON array) | S3 object keys for receipt images |
| localImagePaths | TEXT (JSON array) | Local file system paths for cached images |
| version | INTEGER | Optimistic concurrency version number |
| syncStatus | TEXT | Sync state: synced, pending, conflict |
| lastSyncedAt | TEXT (ISO 8601) | Timestamp of last successful sync for this receipt |
| createdAt | TEXT (ISO 8601) | Creation timestamp |
| updatedAt | TEXT (ISO 8601) | Last modification timestamp |
| isDeleted | INTEGER (boolean) | Soft delete flag |
| deletedAt | TEXT (ISO 8601) | Soft deletion timestamp |

The syncStatus field is critical for the sync engine. Its values indicate the current sync state of each receipt:

- **synced**: The local version matches the server version. No sync action needed.
- **pending**: The local version has been modified since the last sync. This receipt needs to be pushed to the server.
- **conflict**: The sync engine detected a conflict that could not be automatically resolved. The user needs to resolve this manually.

#### categories Table

| Column | Type | Description |
|--------|------|-------------|
| id | TEXT (UUID) | Unique identifier for the category |
| name | TEXT | Category display name |
| icon | TEXT | Icon identifier (maps to a Flutter icon) |
| isDefault | INTEGER (boolean) | Whether this is one of the 10 default categories |
| sortOrder | INTEGER | Display order in the category list |

Categories are managed locally and synced as part of the user's metadata. The 10 default categories are seeded on first launch and can be customized by the user.

#### sync_queue Table

| Column | Type | Description |
|--------|------|-------------|
| id | TEXT (UUID) | Unique identifier for the queue entry |
| receiptId | TEXT | The receipt this operation applies to |
| operation | TEXT | The operation type: create, update, or delete |
| payload | TEXT (JSON) | The full data payload to be sent to the server |
| createdAt | TEXT (ISO 8601) | When the operation was queued |
| retryCount | INTEGER | Number of times this operation has been retried |
| maxRetries | INTEGER | Maximum retry attempts (default 5) |

The sync_queue table is the outbound queue for operations that need to be pushed to the server. When the user creates, updates, or deletes a receipt while offline (or while the sync push fails), an entry is added to this queue. The sync engine processes this queue in FIFO order when connectivity is available.

#### settings Table

| Column | Type | Description |
|--------|------|-------------|
| key | TEXT | Setting identifier (e.g., "storageMode", "language", "lastSyncTimestamp") |
| value | TEXT | Setting value (stored as text, parsed by the app as needed) |

The settings table stores user preferences and sync metadata as simple key-value pairs. The most important sync-related setting is lastSyncTimestamp, which records the timestamp of the last successful delta sync and is used as the starting point for the next delta sync pull.

### File System: Image Cache

Receipt images are stored on the device's file system in an app-private directory. The localImagePaths field in the receipts table maps each receipt to its cached image files.

Image cache management follows these principles:

- **Capture images are always saved locally first**: When the user captures a receipt photo, the image is saved to the local file system immediately, before any upload attempt. This ensures the image is available for offline viewing regardless of connectivity.
- **Downloaded images are cached**: When the app downloads a receipt image from S3 (for example, when syncing a receipt created on another device), the image is cached locally for offline access.
- **Cache cleanup**: When device disk space runs low, the app can clean up cached images for old receipts that are unlikely to be viewed frequently. The S3 object keys in the imageKeys field allow the images to be re-downloaded when needed. Thumbnails are prioritized for retention over full-size images, as they consume less space and are used more frequently (in list views).

---

## Sync Engine Design

The sync engine is a custom implementation that reconciles the local Drift database with the cloud DynamoDB table. It was built custom rather than using AWS AppSync DataStore because AppSync DataStore is a Gen 1 product in maintenance mode and does not align with the Amplify Flutter Gen 2 architecture chosen for this project.

The sync engine uses a combination of timestamp-based delta sync (for efficiency) and periodic full reconciliation (for safety), with field-level conflict resolution that respects the distinction between machine-generated and user-edited data.

### Sync Triggers

The sync engine does not run on a fixed timer. Instead, it is triggered by specific events that indicate either new data to push or potential data to pull:

#### 1. Silent Push Notification (Primary Trigger)

When the server-side backend processes a change that the client should know about (for example, an LLM extraction completing for a receipt uploaded from another device), it sends a silent push notification via SNS/FCM. The mobile app receives this notification in the background and triggers a delta sync pull to fetch the updated data.

Silent push is the primary trigger because it is event-driven: the client syncs only when there is actually something to sync, avoiding unnecessary network requests and battery drain.

#### 2. WorkManager Periodic Task (Backup Trigger)

A WorkManager periodic task runs approximately every 15 minutes when the app is backgrounded. This serves as a backup trigger in case a silent push notification is missed (which can happen due to OS-level notification throttling, especially on Android with battery optimization enabled).

The periodic task checks whether there are pending items in the sync_queue and whether a delta sync pull is overdue, and performs the necessary operations.

#### 3. On App Resume

When the app transitions from background to foreground, a sync is triggered. This ensures that any changes made on another device (or server-side LLM extractions completed) while this device was backgrounded are pulled immediately, so the user sees up-to-date data.

#### 4. After Local Write

When the user creates, updates, or deletes a receipt, the sync engine immediately attempts to push the change to the server if the device is online. This provides the fastest possible sync for single-device users and minimizes the window of inconsistency for multi-device users.

If the device is offline, the operation is queued in the sync_queue table and pushed when connectivity is restored.

#### 5. Manual Pull-to-Refresh

The user can manually trigger a sync by performing a pull-to-refresh gesture on the receipt list. This initiates both a delta sync pull (to fetch server changes) and a sync queue flush (to push any pending local changes). This gives the user explicit control when they want to ensure their data is up to date.

### Delta Sync (Primary Sync Mechanism)

Delta sync is the primary synchronization mechanism. It transfers only the data that has changed since the last sync, minimizing network usage, battery consumption, and server load.

#### Step 1: Pull — Client Requests Changes

The client sends a POST request to /sync/pull with the following payload:

- **lastSyncTimestamp**: The timestamp of the last successful delta sync, stored in the local settings table. For the first sync, this value is 0 (epoch), which causes the server to return all data.

The server queries DynamoDB using GSI-6 (ByUpdatedAt), which is a KEYS_ONLY index with the partition key USER#{userId} and the sort key updatedAt. This index returns all items for the user that have an updatedAt value greater than the provided lastSyncTimestamp.

#### Step 2: Server Returns Changed Items

The server responds with:

- **items**: An array of receipt objects that have been created, updated, or deleted since the lastSyncTimestamp. Deleted items are included with an isDeleted flag so the client can remove them locally.
- **newSyncTimestamp**: The server's current timestamp, which the client will use as the lastSyncTimestamp for the next sync.

The server's timestamp is used (not the client's local clock) to avoid clock skew issues. If the client's clock is ahead or behind the server's clock, using the client's timestamp could cause items to be missed or duplicated in future syncs.

#### Step 3: Client Applies Changes

The client iterates through the returned items and applies them to the local Drift database using the conflict resolution algorithm (described in the next section). For each item:

- If the item does not exist locally, it is inserted.
- If the item exists locally and is in the "synced" state, the server version replaces the local version.
- If the item exists locally and is in the "pending" state (the user modified it while offline), the conflict resolution algorithm determines the merged result.

#### Step 4: Push — Client Sends Local Changes

After applying the pull results, the client sends a POST request to /sync/push with an array of locally modified items. Each item in the array includes:

- **receiptId**: The unique identifier of the receipt.
- **version**: The version number the client's changes are based on (for optimistic concurrency).
- **changedFields**: A list of field names that the client has modified.
- **data**: The full receipt data including the client's changes.

#### Step 5: Server Applies Conflict Resolution

The server receives the push payload and, for each item, compares the client's baseVersion with the current server version. If they match, the client's changes are applied directly. If they differ (another client or server process has modified the item in the meantime), the server runs the conflict resolution algorithm and returns one of three per-item results:

- **accepted**: The server accepted the client's version without modification. This happens when there is no conflict (versions match) or when the client's changes win on all conflicting fields.
- **merged**: The server merged the client's changes with the server's changes using field-level conflict resolution. The merged result is returned to the client.
- **conflict**: The conflict could not be resolved automatically (this should be rare with field-level merge). The item is flagged for manual user resolution.

#### Step 6: Client Updates Based on Server Response

The client processes the server's response for each item:

- **accepted**: The client updates the local version number to match the server and sets syncStatus to "synced."
- **merged**: The client replaces the local data with the server's merged result, updates the version number, and sets syncStatus to "synced."
- **conflict**: The client sets syncStatus to "conflict" and surfaces the conflict to the user for manual resolution.

### Full Reconciliation (Safety Net)

Delta sync is efficient but can theoretically miss changes in edge cases -- for example, if the lastSyncTimestamp is corrupted, if a server-side batch operation modifies items outside the normal API flow, or if a network error causes a delta sync response to be partially applied.

To guard against these edge cases, a full reconciliation runs automatically every 7 days.

#### Full Reconciliation Process

1. The client sends a POST request to /sync/full.
2. The server returns ALL receipts for the user, paginated to handle large data sets.
3. The client loads all local receipts from the Drift database.
4. The client performs a full comparison:
   - Items on the server but not locally: inserted into the local database.
   - Items locally but not on the server (and not in "pending" sync state): deleted from the local database (they were deleted on another device or by a server process).
   - Items on both sides with different data: conflict resolution algorithm applied.
   - Items locally in "pending" state but not on the server: pushed to the server (they were created offline and never synced).
5. The lastSyncTimestamp is reset to the server's current timestamp.

Full reconciliation is more expensive than delta sync (it transfers all data, not just changes), which is why it runs infrequently. It serves as a periodic consistency check that catches any drift that delta sync may have missed.

### Image Sync

Images are synced separately from receipt metadata. This separation is deliberate: receipt metadata is small (a few kilobytes per receipt) and can be synced quickly, while images are large (1-2 MB per image) and may take significant time and bandwidth to transfer. Decoupling the two ensures that metadata is always up to date even if image uploads are still in progress.

#### Image Upload Flow

1. **Local save**: The image is saved to the device's file system immediately after capture. The local file path is stored in the receipt's localImagePaths field.
2. **Generate pre-signed URL**: The client requests a pre-signed upload URL from the server via the API. The server generates a URL with content-type (image/jpeg), size limit, and 10-minute expiry constraints.
3. **Upload to S3**: The client uploads the image directly to S3 using the pre-signed URL. This direct upload avoids routing large binary data through API Gateway and Lambda, reducing latency and cost.
4. **Confirm upload**: After a successful upload, the client updates the receipt's imageKeys field (adding the S3 object key) via a normal receipt update API call. This update triggers the standard sync flow for the metadata.

#### Image Download Flow

1. **Receipt has imageKeys**: When the client syncs a receipt from the server, the receipt's imageKeys field lists the S3 object keys for its images.
2. **Generate pre-signed download URL**: The client requests a pre-signed download URL from the server for each image key.
3. **Download and cache locally**: The client downloads the image and saves it to the local file system. The local file path is stored in the receipt's localImagePaths field.
4. **Thumbnail priority**: Thumbnails (200x300px, JPEG 70%) are downloaded before full-size images. Thumbnails are smaller (tens of kilobytes versus megabytes) and are displayed in list views, making them the higher priority for a responsive user experience. Full-size images are downloaded on demand when the user opens a receipt's detail view.

#### Failed Image Uploads

If an image upload fails (due to network issues, timeout, or server error), the upload operation is queued in the sync_queue table with the operation type set appropriately. The retry logic (exponential backoff, maximum 5 retries) applies to image uploads the same way it applies to metadata sync operations.

During the retry period, the receipt metadata syncs normally -- the receipt appears in the vault with all extracted data, but the imageKeys field does not yet include the failed image's S3 key. Once the image upload eventually succeeds, a receipt update is pushed to add the image key.

---

## Conflict Resolution Algorithm

Conflicts occur when the same receipt is modified in two places (for example, on two different devices while both are offline, or on the device while the server is performing LLM extraction) and the modifications overlap. The conflict resolution algorithm is designed to handle these situations deterministically, preserving user intent while allowing machine-generated data to be updated transparently.

### Conflict Detection

A conflict is detected during the push phase of delta sync. The client sends its changes along with the version number its changes are based on (baseVersion). The server compares this baseVersion with its current version for the same receipt:

- **If server.version equals client.baseVersion**: No conflict. The client's changes are applied directly, and the version is incremented.
- **If server.version is greater than client.baseVersion**: Conflict detected. The receipt was modified on the server (by another device, by LLM processing, or by another sync operation) after the client last synced it.

### Field-Level Merge with Ownership Tiers

When a conflict is detected, the algorithm does not simply choose one version over the other. Instead, it performs a field-by-field merge, using ownership tiers to determine which version of each conflicting field should win.

#### Tier 1: Server/LLM Wins

The following fields are machine-generated by the LLM extraction pipeline. The server always has the latest and most accurate version of these fields because they are produced by cloud processing that the client does not replicate locally.

| Field | Rationale |
|-------|-----------|
| extractedMerchantName | LLM-extracted, may be refined by server-side reprocessing |
| extractedDate | LLM-extracted, server has the latest extraction result |
| extractedTotal | LLM-extracted, server has the latest extraction result |
| ocrRawText | May be updated by server-side OCR reprocessing |
| llmConfidence | Server-side metric, not user-editable |

For Tier 1 fields, the server's version always wins in a conflict. The rationale is straightforward: these fields are outputs of a machine process that runs on the server. The client never produces better values for these fields than the server does.

#### Tier 2: Client/User Wins

The following fields are personal, user-generated data. The user's intent is paramount for these fields, and the server should never overwrite them.

| Field | Rationale |
|-------|-----------|
| userNotes | Personal notes written by the user |
| userTags | Tags assigned by the user for personal organization |
| isFavorite | A personal preference marker |

For Tier 2 fields, the client's version always wins in a conflict. The rationale is that these fields represent the user's personal intent and organizational choices. If the user wrote a note or tagged a receipt on their phone while offline, that action should be preserved regardless of what the server's version says.

#### Tier 3: Conditional (userEditedFields Determines Winner)

The following fields occupy a middle ground. They may be initially populated by the LLM extraction (making the server the logical owner) but can be overridden by the user (making the client the logical owner after the override).

| Field | Rationale |
|-------|-----------|
| storeName | Initially extracted by LLM, but user may correct or enhance it |
| category | Initially suggested by LLM, but user may reassign it |
| warrantyMonths | Initially detected by LLM, but user may correct it |

For Tier 3 fields, the winner is determined by the userEditedFields array:

- **If the field name IS in userEditedFields**: The client's version wins. The user has explicitly edited this field at some point, signaling that they have taken ownership of its value. The LLM's suggestions should not overwrite the user's conscious decision.
- **If the field name IS NOT in userEditedFields**: The server's version wins. The user has never manually edited this field, so the LLM's latest extraction (which may be more accurate than a previous extraction) should be applied.

### The Merge Process

The step-by-step merge process when the server detects a conflict:

1. **Identify changed fields on both sides**: Compare the client's submitted data with the server's current data, noting which fields differ on each side relative to the common ancestor version.
2. **For each field that changed on both sides**, determine the ownership tier:
   - Tier 1 field: Take the server's value.
   - Tier 2 field: Take the client's value.
   - Tier 3 field: Check userEditedFields. If the field is listed, take the client's value. If not, take the server's value.
3. **For fields changed on only one side**: Take the changed value (no conflict exists for these fields).
4. **For fields changed on neither side**: Retain the existing value.
5. **Increment the version number** on the merged result.
6. **Store the merged result** in DynamoDB.
7. **Return the merged result** to the client with a status of "merged."

### Automatic Resolution Success Rate

The field-level merge with ownership tiers is designed to resolve virtually all real-world conflicts automatically. True unresolvable conflicts can only occur when both the client and server modify the same Tier 3 field AND the field is not in userEditedFields AND the client's and server's changes are both valid but different. In practice, this scenario is rare because:

- Tier 1 and Tier 2 fields have deterministic winners -- no ambiguity.
- Tier 3 fields have a clear tiebreaker (userEditedFields).
- Most real-world conflicts involve non-overlapping field changes (the user edits notes on their phone while the server completes LLM extraction on the image).

If, despite these mechanisms, a merge cannot be completed (a safety-net catch for unforeseen scenarios), the receipt is marked with syncStatus = "conflict" and surfaced to the user for manual resolution. The user is presented with both versions and can choose which values to keep for each field.

### userEditedFields Tracking

The userEditedFields array is a critical component of the conflict resolution system. It tracks which Tier 3 fields the user has manually edited, allowing the system to distinguish between "the user accepted the LLM's suggestion" (field not in array) and "the user explicitly set this value" (field in array).

#### How It Works

- When the user manually edits a Tier 3 field through the app's edit interface, the field name is added to the userEditedFields array.
- The array is stored as part of the receipt record in both the local Drift database and DynamoDB.
- The array persists across syncs -- once a field is marked as user-edited, it remains marked.
- The array is included in the sync push payload, so the server knows which fields the user has taken ownership of.

#### Example Scenario

1. The user captures a receipt. The LLM extracts storeName as "IKEA."
2. The user edits storeName to "IKEA Thessaloniki" because they want to record the specific store location.
3. The app adds "storeName" to the userEditedFields array.
4. Later, the server reprocesses the receipt image with an improved LLM model, which extracts storeName as "IKEA Greece."
5. A sync conflict is detected for the storeName field.
6. The conflict resolution algorithm checks userEditedFields and finds "storeName" listed.
7. The client's value ("IKEA Thessaloniki") wins. The user's deliberate edit is preserved.
8. Meanwhile, if the LLM also improves the extractedTotal (a Tier 1 field), that improvement is applied automatically because Tier 1 always takes the server's value.

This mechanism allows the LLM to continuously improve non-edited fields (as models get better over time or as images are reprocessed) while respecting the user's explicit overrides. The user never has to re-enter information they have already corrected.

---

## Sync Queue Management

The sync queue is the outbound buffer for operations that need to be pushed to the server. It ensures that no user action is lost, regardless of connectivity state.

### Queue Operations

When the user performs a create, update, or delete operation on a receipt, the following happens:

1. The operation is applied to the local Drift database immediately. The receipt's syncStatus is set to "pending."
2. A new entry is added to the sync_queue table with the operation type (create, update, or delete), the receipt ID, the full data payload (serialized as JSON), the current timestamp, and a retry count of 0.
3. If the device is online, the sync engine immediately attempts to process the queue entry by pushing it to the server.
4. If the push succeeds, the queue entry is deleted and the receipt's syncStatus is set to "synced."
5. If the push fails (network error, server error), the queue entry remains and will be retried.

### FIFO Processing

Queue entries are processed in first-in-first-out order. This preserves the causal ordering of operations -- if the user creates a receipt and then updates it, the create must be processed before the update. Processing out of order could result in an update being applied to a receipt that does not yet exist on the server.

### Retry with Exponential Backoff

Failed queue entries are retried with exponential backoff to avoid overwhelming the server or wasting battery on repeated failures:

| Retry | Delay |
|-------|-------|
| 1st | 1 second |
| 2nd | 2 seconds |
| 3rd | 4 seconds |
| 4th | 8 seconds |
| 5th | 16 seconds |

The maximum number of retries is 5 (configurable via the maxRetries field on each queue entry). After the 5th retry fails, the queue entry is marked as "failed."

### Failed Operations

When a queue entry exhausts its maximum retries and is marked as failed, the app surfaces the failure to the user. The user is informed that a specific operation could not be synced and is given the option to retry manually or discard the pending change.

Failed operations are not silently discarded -- data integrity requires that the user is aware of and can act on any operation that could not be synced.

### Queue Size Monitoring

The sync engine monitors the number of entries in the sync_queue table. If the queue size exceeds 100 items (indicating a prolonged period of offline activity or persistent sync failures), the engine flags the situation and triggers a full reconciliation on the next successful connection. A large queue increases the risk of complex conflicts and data drift, so the full reconciliation serves as a corrective measure.

---

## Background Sync

The app needs to sync data even when it is not in the foreground. Background sync ensures that the user's data is up to date when they open the app, and that receipts captured on one device are available on other devices without requiring the app to be actively open.

### Platform Implementation

Background sync is implemented using the workmanager Flutter package, which provides a cross-platform abstraction over the native background task APIs:

- **Android**: WorkManager, which is the recommended API for deferrable, guaranteed background work. WorkManager respects battery optimization, doze mode, and other OS-level restrictions while ensuring that the registered task eventually runs.
- **iOS**: BGTaskScheduler, which allows the app to register background tasks that the OS schedules at its discretion. iOS is more restrictive about background execution than Android, but BGTaskScheduler provides a reliable mechanism for periodic background work.

### Registered Background Task

A single periodic background task is registered: sync. This task runs approximately every 15 minutes when the app is in the background.

The task performs the following steps:

1. Check network connectivity (using the two-layer detection described above).
2. If offline, exit immediately (no work to do).
3. If online, process any pending items in the sync_queue (push local changes).
4. If online, perform a delta sync pull (fetch server changes).
5. Complete the task and report success or failure to the OS.

### Constraints

The background task is registered with a network connectivity constraint: the OS will not schedule the task if the device has no network connection. This prevents the task from running (and consuming battery) when it has no chance of completing useful work.

### Battery Considerations

The background sync task is designed to be battery-friendly:

- It runs at most every 15 minutes, not continuously.
- It exits immediately if there is no network or no pending work.
- It respects OS-level battery optimization settings. On Android, if the user has enabled battery saver or restricted background activity for the app, WorkManager will defer the task. On iOS, BGTaskScheduler inherently respects battery state.
- Delta sync transfers only changed data, minimizing the volume of network communication.

### On-Resume Sync

In addition to the periodic background task, a sync is triggered when the app enters the foreground (resumes from background). This is the most important sync trigger for user experience: when the user opens the app, they should see the latest data, including any changes made on another device or any LLM extractions completed while the app was backgrounded.

The on-resume sync performs both a sync queue flush (push) and a delta sync pull, ensuring bidirectional synchronization.

---

## Edge Cases

Offline-first architectures encounter a variety of edge cases that simple client-server systems do not. The following scenarios are explicitly accounted for in the sync engine design.

### Edge Case 1: Same Receipt Edited on Two Devices While Both Are Offline

**Scenario**: The user has two devices (a phone and a tablet), both offline. They edit the same receipt on both devices -- changing the storeName on the phone and adding userNotes on the tablet.

**Resolution**: When the phone comes online first and pushes its changes, the server accepts them (no conflict, since the server version has not changed). When the tablet comes online and pushes its changes, the server detects a conflict (server.version > tablet.baseVersion). The conflict resolution algorithm runs:

- storeName: Changed only by the phone (already on the server). The tablet did not change it. No conflict for this field -- the server's (phone's) value is retained.
- userNotes: Changed only by the tablet. The server's version has no change to this field. No conflict -- the tablet's value is applied.

Result: Both edits are preserved. The merged receipt has the phone's storeName and the tablet's userNotes.

If both devices edited the same field, the ownership tiers determine the winner (Tier 2 for userNotes would give the client the win, but in this case "client" is ambiguous because both devices are clients -- the second device to sync would win, since its push triggers the conflict resolution).

### Edge Case 2: Large Batch Import While Offline

**Scenario**: The user imports 100+ receipts from their photo gallery during onboarding while the device is offline.

**Resolution**: All 100+ receipts are saved to the local Drift database immediately. Each receipt generates a "create" entry in the sync_queue. When connectivity is restored, the sync engine processes the queue in batches of 25 to avoid overwhelming the server with a single massive request and to allow for partial progress (if connectivity is lost again during the sync, completed batches are not retried).

The batching is transparent to the user. They see all 100+ receipts in their vault immediately (from the local database), and a progress indicator shows the sync status as receipts are pushed to the cloud.

### Edge Case 3: Image Upload Fails

**Scenario**: A receipt's metadata syncs successfully, but the image upload to S3 fails due to a network timeout.

**Resolution**: The receipt metadata is synced to DynamoDB without the image's S3 object key. The failed image upload is queued in the sync_queue with retry logic. On another device, the receipt appears with all metadata but without an image (or with a placeholder indicating that the image is still uploading from the original device).

When the image upload eventually succeeds, the client pushes a receipt update that adds the S3 object key to the imageKeys field. Other devices then see the image appear on their next sync pull.

This decoupling ensures that metadata (which is small and fast to sync) is never blocked by large image uploads. The user can see, search, and manage the receipt on all devices even before the image has finished uploading.

### Edge Case 4: Server Unavailable

**Scenario**: The server is down or unreachable for an extended period (not just a network issue on the device).

**Resolution**: The sync engine treats this identically to an offline state. Operations are queued locally. Retry attempts use exponential backoff (1s, 2s, 4s, 8s, 16s). After the maximum retries, the operation is marked as failed and the user is notified.

If the server remains unavailable for a very long time and the sync queue grows beyond 100 items, the engine flags the situation for a full reconciliation when the server becomes available again.

The app remains fully functional throughout the outage. The user can capture, browse, search, and manage receipts without any degradation.

### Edge Case 5: Clock Skew

**Scenario**: The user's device clock is significantly ahead of or behind the server's clock, causing timestamp-based sync comparisons to produce incorrect results.

**Resolution**: The sync engine uses server-provided timestamps for all sync-related comparisons, never the local device clock. Specifically:

- The lastSyncTimestamp stored locally is the newSyncTimestamp returned by the server in the delta sync pull response.
- The updatedAt timestamps used for delta sync queries are set by the server (by the Lambda function processing the API call), not by the client.
- The createdAt timestamp on a receipt is set locally (for immediate display) but is overwritten by the server timestamp on first sync.

This means that even if the device clock is wrong by hours or days, the sync engine produces correct results because all comparisons use the server's consistent clock.

### Edge Case 6: First Sync After Install on a New Device

**Scenario**: The user installs the app on a new device and signs in. The local database is empty, but the server has hundreds of receipts.

**Resolution**: The first sync is effectively a full sync. Since lastSyncTimestamp is 0 (no previous sync), the delta sync pull returns all receipts. The client inserts all receipts into the local Drift database.

For images, thumbnails are downloaded first (prioritized by the download queue) because they are displayed in the list view. Full-size images are downloaded on demand -- only when the user taps on a receipt to view its details. This prioritization ensures that the user can browse their vault quickly without waiting for all full-size images to download.

If the user has a large vault (hundreds of receipts), the initial sync is paginated on the server side, and the client processes each page sequentially, inserting receipts and downloading thumbnails as they arrive.

### Edge Case 7: Storage Mode Switch (Cloud to Device-Only)

**Scenario**: The user decides to switch from cloud+device mode to device-only mode.

**Resolution**: The following steps occur:

1. The sync engine is stopped. No further push or pull operations are performed.
2. The sync_queue is cleared. Any pending operations that have not yet been pushed to the server are discarded (the user has chosen to stop cloud syncing, so pending pushes are irrelevant).
3. Local data is retained. All receipts, images, and settings in the local Drift database remain intact and accessible.
4. The lastSyncTimestamp is preserved (but not used) so that if the user switches back to cloud mode, a delta sync can resume from where it left off rather than requiring a full sync.
5. Cloud data is NOT deleted. The user's data remains in DynamoDB and S3 unless the user explicitly requests account deletion. This allows the user to switch back to cloud mode later without data loss.

### Edge Case 8: Storage Mode Switch (Device-Only to Cloud)

**Scenario**: The user has been operating in device-only mode and decides to enable cloud sync.

**Resolution**: The following steps occur:

1. A full sync is triggered. Because the cloud and local databases may have diverged significantly (the local database has been modified without any sync), a full reconciliation is performed rather than a delta sync.
2. All local receipts are pushed to the server. Each local receipt that does not exist on the server is created via the sync push.
3. All local images are uploaded. Each image that has not been uploaded to S3 is queued for upload.
4. Any receipts on the server (from a previous cloud session on another device) are pulled and merged with the local database using the standard conflict resolution algorithm.
5. The sync engine resumes normal operation with delta sync.

This process may take significant time and bandwidth if the user has accumulated many receipts in device-only mode. The app shows a progress indicator and allows the user to continue using the app normally during the sync.

---

*This document is part of the Receipt & Warranty Vault documentation suite. For related documents, see the [docs directory listing](../CLAUDE.md#documentation-files).*
