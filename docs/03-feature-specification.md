# Feature Specification — Receipt & Warranty Vault v1.0

**Document Version**: 1.0
**Last Updated**: 2026-02-08
**Status**: Pre-Implementation (Documentation Phase)

---

## Table of Contents

1. [Introduction](#introduction)
2. [Feature Registry — v1.0](#feature-registry--v10)
   - [F-001: Photo Capture](#f-001-photo-capture)
   - [F-002: On-Device OCR](#f-002-on-device-ocr)
   - [F-003: Cloud LLM Refinement](#f-003-cloud-llm-refinement)
   - [F-004: Manual Field Edit](#f-004-manual-field-edit)
   - [F-005: Warranty Tracking](#f-005-warranty-tracking)
   - [F-006: Push Notification Reminders](#f-006-push-notification-reminders)
   - [F-007: Search and Filters](#f-007-search-and-filters)
   - [F-008: Offline-First Storage](#f-008-offline-first-storage)
   - [F-009: Storage Mode Choice](#f-009-storage-mode-choice)
   - [F-010: Authentication](#f-010-authentication)
   - [F-011: App Lock](#f-011-app-lock)
   - [F-012: Export and Share](#f-012-export-and-share)
   - [F-013: Custom Categories](#f-013-custom-categories)
   - [F-014: Mark as Returned](#f-014-mark-as-returned)
   - [F-015: Soft Delete](#f-015-soft-delete)
   - [F-016: Bulk Import](#f-016-bulk-import)
   - [F-017: Home Screen Widget](#f-017-home-screen-widget)
   - [F-018: Stats Display](#f-018-stats-display)
   - [F-019: English and Greek Localization](#f-019-english-and-greek-localization)
   - [F-020: Image Compression](#f-020-image-compression)
3. [Deferred Features — v1.5](#deferred-features--v15)
4. [Deferred Features — v2.0](#deferred-features--v20)
5. [Feature Dependency Map](#feature-dependency-map)

---

## Introduction

This document specifies every feature included in the v1.0 release of Receipt & Warranty Vault, a Flutter mobile application for capturing, organizing, and retrieving receipts and warranty information. The target audience for v1.0 is 5 internal testers. Each feature is assigned a unique identifier, described with a user story, and accompanied by acceptance criteria, priority level, dependencies, and edge case analysis.

Priority definitions used throughout this document:

- **Must-have**: The app cannot ship without this feature. It is essential to the core value proposition.
- **Should-have**: The feature is important and expected by users but the app could technically launch without it in a degraded state.
- **Nice-to-have**: The feature enhances the experience but is not critical to the core flow.

---

## Feature Registry -- v1.0

---

### F-001: Photo Capture

**Feature Name**: Photo Capture (Camera, Gallery Import, File Import)

**Description**: Users can capture receipt images using the device camera, import existing photos from the device gallery, or import files (images and PDFs) from the device file system. This is the primary entry point for getting receipt data into the application. The camera interface provides a viewfinder optimized for document capture. Imported images and PDFs are stored locally and queued for OCR processing.

**User Story**: As a user, I want to capture a receipt by taking a photo, choosing from my gallery, or importing a file, so that I can digitize my receipt without manual data entry.

**Acceptance Criteria**:
- The user can launch the device camera from within the app and capture one or more photos in a single session.
- The user can select one or more existing images from the device photo gallery.
- The user can import image files (JPEG, PNG) and PDF files from the device file system.
- Multi-page receipts are supported: the user can capture or import multiple images and associate them with a single receipt record.
- PDF files are converted to images for OCR processing and display.
- After capture or import, the user is shown a preview of the image(s) with the option to crop, rotate, or retake before proceeding.
- The capture flow works entirely offline; no internet connection is required.
- Camera permissions are requested at first use with a clear explanation of why the permission is needed.
- Gallery and file system permissions are requested only when the user chooses those import paths.
- Captured images are immediately written to local storage before any processing begins, preventing data loss if the app is interrupted.

**Priority**: Must-have

**Dependencies**:
- F-020 (Image Compression): Captured images are compressed before storage.
- F-008 (Offline-First Storage): Images are saved to the local Drift database.

**Edge Cases and Error Handling**:
- Camera permission denied: Display a clear message explaining that the camera is required for capture, with a button to open device settings.
- Gallery permission denied: Same pattern as camera, with settings redirect.
- Device storage full: Detect insufficient storage before capture and warn the user. If storage runs out mid-capture, save whatever was captured and notify the user.
- Corrupted or unsupported file: If an imported file cannot be read or is in an unsupported format, display an error message naming the file and suggesting supported formats.
- Very large PDF (many pages): Warn the user if the PDF exceeds 20 pages and confirm they want to proceed, as processing will take longer.
- Camera crashes or becomes unavailable mid-session: Save any images already captured and return the user to the home screen with a notification that the session was interrupted.
- Low-light or blurry capture: Do not block saving, but display a warning that OCR accuracy may be reduced and suggest retaking the photo.
- Importing a duplicate image (same file hash as an existing receipt): Warn the user that this image may already exist and let them choose to proceed or cancel.

---

### F-002: On-Device OCR

**Feature Name**: On-Device OCR (ML Kit for Latin + Tesseract for Greek, Hybrid Approach)

**Description**: Immediately after a receipt image is captured or imported, the app runs on-device optical character recognition to extract text. Google ML Kit handles Latin characters and numerals, which covers the majority of receipt content (prices, dates, product codes). Tesseract handles Greek text, filling the gap since ML Kit does not support the Greek script. The two engines run in sequence: ML Kit processes first, then Tesseract processes for Greek text detection. The combined output is parsed to extract structured fields: store name, date, total amount, individual line items, and any warranty-related information. This extraction happens instantly on the device with no internet required.

**User Story**: As a user, I want my receipts to be automatically read and the key information extracted the moment I capture them, so that I do not have to type in details manually.

**Acceptance Criteria**:
- OCR processing begins automatically after image capture or import, with no user action required.
- ML Kit processes Latin script text (including numbers, dates, currency symbols, and common punctuation).
- Tesseract processes Greek script text, specifically for store names, product descriptions, and other Greek-language content.
- The extracted raw text is stored in the local database for full-text search (FTS5) indexing.
- Structured fields are parsed from the raw text: store/merchant name, purchase date, total amount, currency, and line items where identifiable.
- Processing time is under 3 seconds for a standard single-page receipt on mid-range devices.
- A progress indicator is shown during OCR processing.
- The user can view and edit all extracted fields after processing completes (see F-004).
- OCR runs entirely on-device; no internet connection is needed.
- If the device supports it, OCR processing runs on a background isolate to keep the UI responsive.

**Priority**: Must-have

**Dependencies**:
- F-001 (Photo Capture): OCR requires a captured or imported image as input.
- F-008 (Offline-First Storage): Extracted text and fields are stored locally.

**Edge Cases and Error Handling**:
- Completely unreadable image (too blurry, too dark, or not a receipt): OCR returns empty or minimal text. The app saves the image anyway with a note that extraction was unsuccessful, and prompts the user to enter fields manually.
- Mixed-language receipt (Greek and Latin on the same receipt): Both ML Kit and Tesseract process the image. The results are merged, with deduplication logic to avoid double-extracting text that both engines can read (such as numbers).
- Handwritten receipts: OCR will likely fail or produce garbage text. The app should not crash; it saves whatever is extracted and flags it as low-confidence.
- Receipt with no date or no total: The app leaves those fields blank and highlights them for manual entry rather than guessing.
- Very long receipt (e.g., large grocery bill): Processing may take longer. The progress indicator should remain visible and the operation should not time out.
- Tesseract initialization failure: Fall back to ML Kit only and notify the user that Greek text may not be fully extracted.
- ML Kit initialization failure: Fall back to Tesseract only and notify the user that Latin text extraction may be degraded.
- Both engines fail: Save the image without any extracted text and prompt the user for manual entry.
- Image with receipt and non-receipt content (e.g., photo includes a hand holding the receipt): OCR processes whatever text is visible. The crop/rotate step in F-001 mitigates this.

---

### F-003: Cloud LLM Refinement

**Feature Name**: Cloud LLM Refinement (Bedrock Claude Haiku 4.5 Primary, Sonnet 4.5 Fallback)

**Description**: When the device has an internet connection, the on-device OCR output is sent to AWS Bedrock for refinement using Claude Haiku 4.5. The LLM receives the raw OCR text (and optionally the image itself via Claude's vision capability) and returns polished, structured data: corrected store names, properly formatted dates, accurate totals, categorization suggestions, and warranty period detection. If Haiku 4.5 fails or returns low-confidence results, the system falls back to Sonnet 4.5 for higher-quality extraction. The LLM refinement is asynchronous and non-blocking: the user can continue using the app with the on-device OCR results while cloud refinement happens in the background. When refinement completes, the receipt record is updated and the user is optionally notified.

**User Story**: As a user, I want the app to improve the accuracy of my receipt data using cloud AI when I am online, so that I get correct store names, dates, and totals without manual correction.

**Acceptance Criteria**:
- Cloud LLM refinement is triggered automatically when a new receipt is captured and the device has an internet connection.
- If the device is offline at capture time, refinement is queued and executed when connectivity is restored.
- Haiku 4.5 is used as the primary model. Sonnet 4.5 is invoked only if Haiku returns an error or a confidence score below a defined threshold.
- The LLM extracts and refines: merchant/store name, purchase date, total amount, currency, line items, suggested category, and detected warranty period.
- Refinement results are merged into the receipt record using the conflict resolution tiers defined in the data model: LLM-extracted fields are Tier 1 (server wins), unless the user has manually edited those fields (tracked via user_edited_fields), in which case the user's values are preserved.
- The user receives a subtle notification (in-app badge or toast) when cloud refinement updates a receipt they previously saved.
- The raw OCR text and the LLM-refined text are both stored for audit and debugging purposes.
- A confidence score is stored with each LLM extraction.
- No receipt image or text data is stored or used for training by AWS Bedrock (confirmed by AWS data policy).
- The cost per receipt is approximately $0.004 using Haiku 4.5.

**Priority**: Must-have

**Dependencies**:
- F-002 (On-Device OCR): Cloud refinement uses OCR output as input.
- F-008 (Offline-First Storage): Results are written to the local database.
- F-010 (Authentication): The user must be authenticated to make API calls to the backend, which proxies Bedrock requests.

**Edge Cases and Error Handling**:
- Bedrock service unavailable: Retry with exponential backoff (3 attempts). If all retries fail, keep the on-device OCR results and mark the receipt as "pending refinement." Retry on next sync cycle.
- Haiku 4.5 returns low confidence: Automatically escalate to Sonnet 4.5. If Sonnet also returns low confidence, keep the best result and flag for manual review.
- Sonnet 4.5 also fails: Keep on-device OCR results. The receipt is fully functional with local data.
- Network drops mid-request: The request times out and is retried. Partial responses are discarded.
- LLM returns hallucinated data (e.g., a store name that does not appear in the OCR text): The system should compare LLM output against the raw OCR text and flag significant discrepancies for user review rather than silently overwriting.
- User edits a field before cloud refinement completes: The user's edit takes precedence. The field is added to user_edited_fields and cloud refinement does not overwrite it.
- Device-only storage mode (F-009): Cloud refinement is completely disabled. No data leaves the device.
- Rate limiting by Bedrock: Queue requests and process them at a sustainable rate. The user should not experience errors, only delays.

---

### F-004: Manual Field Edit

**Feature Name**: Manual Field Edit (User Correction of All Auto-Extracted Fields)

**Description**: After OCR and/or LLM extraction, the user can review all extracted fields and manually correct any errors. Editable fields include: store/merchant name, purchase date, total amount, currency, category, individual line items, warranty duration, and any custom notes. User-edited fields are tracked in a `user_edited_fields` array so that the sync engine and conflict resolution system know to preserve user corrections over future LLM refinements.

**User Story**: As a user, I want to review and correct the automatically extracted receipt data, so that my records are accurate even when the OCR or AI makes mistakes.

**Acceptance Criteria**:
- All auto-extracted fields are presented in an editable form after OCR processing.
- The user can modify: store name, purchase date, total amount, currency, category (with dropdown), warranty duration (months), line items (add, edit, remove), and free-text notes.
- Each field shows the auto-extracted value as the default, which the user can accept or overwrite.
- When the user modifies a field, that field name is recorded in the `user_edited_fields` array on the receipt record.
- Fields in the `user_edited_fields` array are never overwritten by subsequent cloud LLM refinement.
- Date fields use a date picker with the auto-extracted date pre-selected.
- Amount fields use a numeric keyboard with currency symbol.
- The form validates input: dates must be valid, amounts must be non-negative numbers, required fields (at minimum: one image) are enforced.
- Changes are saved to the local database immediately on save, with no internet required.
- The user can return to edit a receipt at any time from the receipt detail view.

**Priority**: Must-have

**Dependencies**:
- F-002 (On-Device OCR): Provides the initial extracted values to populate the edit form.
- F-003 (Cloud LLM Refinement): Provides refined values. The edit form must handle updates arriving asynchronously.
- F-013 (Custom Categories): The category dropdown must include both default and user-created categories.
- F-008 (Offline-First Storage): Edits are saved locally.

**Edge Cases and Error Handling**:
- User edits a field while cloud LLM refinement is in progress: The user's edit wins. When the LLM result arrives, the edited field is skipped.
- User clears a required field and tries to save: Display inline validation error indicating which fields need values.
- User enters an invalid date (e.g., February 30): The date picker prevents invalid dates. If manual text entry is allowed, validate and show an error.
- User enters a negative amount: Display validation error.
- User changes the category to a custom category that is later deleted: The receipt retains the category name as a string, even if the category no longer appears in the category list. It does not break or reset.
- User edits a receipt on two devices while offline: On sync, field-level merge is applied. User-edited fields on the more recently modified device take precedence per the conflict resolution tiers.
- Very long store names or notes: Enforce reasonable character limits (e.g., 200 characters for store name, 2000 for notes) with clear counter feedback.

---

### F-005: Warranty Tracking

**Feature Name**: Warranty Tracking (Expiry Countdown, Progress Bar, Status Badges)

**Description**: The hero feature of the application. Each receipt can have an associated warranty period. The app calculates the warranty expiry date from the purchase date and warranty duration, then displays a visual countdown showing how much warranty time remains. A progress bar shows the percentage of warranty elapsed. Receipts are assigned one of four status badges: Active (warranty is valid with more than 30 days remaining), Expiring Soon (30 days or fewer remaining), Expired (warranty period has passed), or No Warranty (no warranty information associated with the receipt). The "Expiring" tab on the bottom navigation provides a dedicated view of warranties sorted by expiry date, with the most urgent at the top.

**User Story**: As a user, I want to see at a glance which of my warranties are still active and which are expiring soon, so that I can make claims or returns before it is too late.

**Acceptance Criteria**:
- Each receipt record can store a warranty duration in months (set manually or detected by LLM).
- The warranty expiry date is calculated as: purchase date + warranty duration in months.
- A visual progress bar shows the percentage of warranty time elapsed, colored green for Active, amber for Expiring Soon, and red for Expired.
- A status badge is displayed on each receipt card: "Active" (green), "Expiring Soon" (amber), "Expired" (red), or "No Warranty" (grey).
- The "Expiring Soon" threshold is 30 days by default.
- The "Expiring" tab shows all receipts with active or expiring-soon warranties, sorted by expiry date ascending (soonest expiry first).
- The receipt detail view shows a human-readable countdown (e.g., "47 days remaining" or "Expired 12 days ago").
- Warranty status is recalculated dynamically based on the current date, not stored as a static value.
- Receipts with no warranty are not shown in the Expiring tab unless the user opts to view them.
- The warranty information is stored locally and works fully offline.

**Priority**: Must-have

**Dependencies**:
- F-004 (Manual Field Edit): Warranty duration can be set or corrected via the edit form.
- F-003 (Cloud LLM Refinement): The LLM may detect and suggest a warranty period from receipt text.
- F-006 (Push Notification Reminders): Warranty expiry triggers notifications.

**Edge Cases and Error Handling**:
- Receipt with a purchase date but no warranty duration: Status is "No Warranty." The user can add a warranty duration at any time via edit.
- Receipt with a warranty duration but no purchase date: The app cannot calculate an expiry date. Display a prompt asking the user to enter the purchase date.
- Warranty expiry date is today: Status is "Expiring Soon" (not yet expired). It transitions to "Expired" the following day.
- Very long warranty (e.g., 120 months / 10 years): Progress bar and countdown should handle large durations gracefully, showing years and months rather than just days.
- User changes the purchase date or warranty duration after initial save: The expiry date and all visual indicators recalculate immediately.
- Receipt marked as returned (F-014): The warranty badge is replaced or supplemented with a "Returned" badge. The warranty countdown is no longer relevant but the data is preserved.
- Clock manipulation (user sets device date forward): Warranty status relies on system time. There is no server-side validation of the device clock for offline calculations. This is an accepted limitation.

---

### F-006: Push Notification Reminders

**Feature Name**: Push Notification Reminders (Local Notifications for Offline, SNS for Server Events, Configurable Timing)

**Description**: The app sends push notifications to remind users about upcoming warranty expirations. Two notification systems work together: local notifications (via `flutter_local_notifications`) handle scheduled reminders that work even when the device is offline, and SNS (via Firebase Cloud Messaging) handles server-triggered events such as daily warranty check results and weekly summaries. Users can configure when they want to be reminded: the default is 30 days and 7 days before expiry, but users can set custom reminder times. An EventBridge rule triggers a Lambda function daily to check for expiring warranties and send SNS notifications. Users can also receive a weekly summary of their warranty status.

**User Story**: As a user, I want to receive notifications before my warranties expire, so that I never miss a chance to make a claim or return.

**Acceptance Criteria**:
- Local notifications are scheduled for each receipt with a warranty, at the user-configured reminder times.
- Default reminder times are 30 days and 7 days before warranty expiry.
- Users can customize reminder timing in settings: add, remove, or modify reminder intervals (e.g., 90 days, 14 days, 1 day before expiry).
- Users can add custom reminder days (e.g., 60 days before, 3 days before) beyond the two defaults.
- Local notifications work without an internet connection.
- Server-side notifications are sent via SNS through FCM for: daily warranty expiry alerts (if a warranty expires within the user's configured reminder window) and an optional weekly warranty summary.
- Tapping a notification opens the app directly to the relevant receipt's detail view.
- Users can disable all notifications, disable only server notifications, or disable notifications for specific receipts.
- Notification content includes the store name, item description (if available), and days until expiry.
- Notifications are not sent for receipts that have been soft-deleted, marked as returned, or have a "No Warranty" status.
- When a warranty duration or purchase date is edited, all related scheduled local notifications are recalculated and rescheduled.

**Priority**: Must-have

**Dependencies**:
- F-005 (Warranty Tracking): Notifications are triggered by warranty expiry dates.
- F-010 (Authentication): Server-side notifications require authenticated users with registered device tokens.
- F-008 (Offline-First Storage): Local notification scheduling reads warranty data from the local database.

**Edge Cases and Error Handling**:
- Notification permission denied: Display a banner in the app explaining that reminders are disabled, with a settings redirect. The app functions fully without notifications.
- Device rebooted: Local notifications are cleared on reboot on Android. The app must reschedule all local notifications when it next launches after a reboot (using a boot-complete receiver or re-scheduling on app open).
- User changes device time zone: Notification times should be based on the user's local time. If the time zone changes, notifications are rescheduled.
- Hundreds of warranties: Ensure the notification scheduling system handles a large number of scheduled notifications without performance degradation. Android limits the number of pending alarms; batch or prioritize if necessary.
- User in device-only mode (F-009): Server-side notifications are not available. Only local notifications are used.
- SNS delivery failure: The server logs the failure. The user still has local notifications as a backup.
- User uninstalls and reinstalls the app: Local notifications are lost. Upon reinstall and login, server-side notifications resume. Local notifications are rescheduled after the local database is rebuilt from sync.
- Warranty expiry date is in the past at the time of receipt creation: Do not schedule notifications for already-expired warranties.

---

### F-007: Search and Filters

**Feature Name**: Search and Filters (Keyword Search, FTS5 Full-Text Search, Multi-Criteria Filters)

**Description**: Users can search their receipt collection using keyword search powered by SQLite FTS5 full-text search. The search queries the raw OCR text, store names, notes, line item descriptions, and category names. In addition to free-text search, users can apply structured filters: by category, store, date range, warranty status (Active, Expiring Soon, Expired, No Warranty), and amount range. Filters can be combined with search terms. The search interface is accessible from the Search tab in the bottom navigation bar.

**User Story**: As a user, I want to quickly find a specific receipt by searching for a store name, product, or keyword, and I want to filter my receipts by category, date, or warranty status, so that I can locate any receipt in seconds.

**Acceptance Criteria**:
- A search bar is prominently displayed in the Search tab.
- Typing a query returns results in real time (debounced at 300ms) as the user types.
- Search uses FTS5 full-text indexing on: raw OCR text, store/merchant name, notes, line item descriptions, and category name.
- Search results are ranked by relevance (FTS5 rank function).
- Filter options are presented as chips or a filter panel below the search bar.
- Available filters: category (multi-select from all categories), store (multi-select from known stores), date range (start and end date pickers), warranty status (multi-select: Active, Expiring Soon, Expired, No Warranty), and amount range (minimum and maximum).
- Filters and search terms can be combined (logical AND between search query and each filter; logical OR within multi-select filters).
- Active filters are displayed as removable chips above the results.
- Clearing all filters and search text shows all receipts sorted by date.
- Search and filtering operate entirely on the local database and work offline.
- Tapping a search result navigates to the receipt detail view.
- If no results match, a clear "No results found" message is displayed with suggestions (e.g., "Try a different keyword or adjust your filters").
- Recent searches are saved locally (last 10) for quick re-access.

**Priority**: Must-have

**Dependencies**:
- F-008 (Offline-First Storage): FTS5 index is maintained in the local Drift database.
- F-002 (On-Device OCR): Raw OCR text is the primary content indexed for search.
- F-013 (Custom Categories): Category filter options include user-created categories.
- F-005 (Warranty Tracking): Warranty status filter depends on warranty status calculation.

**Edge Cases and Error Handling**:
- FTS5 index corruption: Detect and rebuild the index from stored receipt data. This may take a few seconds for large collections and should show a progress indicator.
- Search query with special characters: Escape special FTS5 characters (e.g., quotes, asterisks) to prevent query syntax errors.
- Very broad search returning hundreds of results: Paginate or lazy-load results to avoid performance issues. Show the first 20 results immediately and load more on scroll.
- Search for text that exists only in OCR raw text (not in structured fields): FTS5 searches across all indexed content, so this should return results. Ensure the result display indicates where the match was found if it is not in the title or store name.
- Filter combination that returns zero results: Show all active filters and allow the user to remove individual filters to broaden the search.
- Amount range filter with min greater than max: Display a validation error and do not execute the query.
- Greek text search: Ensure FTS5 tokenization handles Greek characters correctly. Tesseract-extracted Greek text must be properly indexed.

---

### F-008: Offline-First Storage

**Feature Name**: Offline-First Storage (Drift/SQLCipher Local Database with Custom Sync Engine to DynamoDB)

**Description**: All receipt data is stored locally on the device in a Drift (SQLite) database encrypted with SQLCipher using AES-256 encryption. The app is fully functional without an internet connection: users can capture receipts, run OCR, edit fields, search, and view warranty status entirely offline. When the device comes online, a custom sync engine synchronizes local changes to the cloud (DynamoDB for structured data, S3 for images). The sync engine uses timestamp-based delta sync as the primary mechanism, with a full reconciliation sweep every 7 days as a safety net. Conflict resolution uses a field-level merge strategy with three ownership tiers: server/LLM wins for extraction fields, client/user wins for personal fields, and client-override-with-tracking for shared fields.

**User Story**: As a user, I want to capture and manage my receipts even when I have no internet connection, and have my data automatically sync to the cloud when I am back online, so that I never lose data and can access it across devices.

**Acceptance Criteria**:
- All receipt data (images, extracted text, structured fields, metadata) is stored in the local Drift database.
- The local database is encrypted with SQLCipher (AES-256) at rest.
- The app is fully functional without an internet connection: capture, OCR, edit, search, view warranty status, and receive local notifications all work offline.
- When the device comes online, the sync engine automatically pushes local changes to DynamoDB and S3.
- The sync engine uses delta sync: only records modified since the last successful sync are transferred, using the `updatedAt` timestamp and GSI-6.
- A full reconciliation runs every 7 days to catch any records that may have been missed by delta sync.
- Conflict resolution follows the three-tier model: Tier 1 (server wins for LLM fields), Tier 2 (client wins for user personal fields), Tier 3 (client override with tracking for shared fields like display_name, category, warranty_months).
- Each record has a version number that increments on every write. Conflicting writes are detected via version mismatch.
- Background sync is triggered by: silent push notification (primary), WorkManager periodic task (backup), and app resume from background.
- Sync progress is visible in the app (e.g., a subtle sync indicator in the app bar).
- Sync failures are retried with exponential backoff.
- The sync engine handles large backlogs gracefully (e.g., user captures 50 receipts offline and then comes online).
- Images are uploaded to S3 using pre-signed URLs with 10-minute expiry, content-type and size restrictions.

**Priority**: Must-have

**Dependencies**:
- F-010 (Authentication): Sync to the cloud requires authenticated sessions.
- F-009 (Storage Mode Choice): If the user selects device-only mode, cloud sync is disabled.

**Edge Cases and Error Handling**:
- Sync interrupted mid-transfer (e.g., network drops): The sync engine tracks progress per-record. On the next sync, it resumes from where it left off rather than restarting from scratch.
- Conflicting edits to the same receipt from two devices: Field-level merge is applied. If two devices edited different fields, both changes are preserved. If two devices edited the same Tier 3 field, the most recent edit (by timestamp) wins.
- Database migration on app update: Drift handles schema migrations. A migration strategy must be defined for each schema change to avoid data loss.
- SQLCipher key management: The encryption key is derived from the user's credentials and stored in flutter_secure_storage. If the key is lost (e.g., user clears app data without logging out), the local database is unrecoverable but cloud data can be re-synced on login.
- Pre-signed URL expiry: If an image upload takes longer than 10 minutes (unlikely for a single receipt image), the pre-signed URL expires. The sync engine detects the 403 error, requests a new URL, and retries.
- Full reconciliation detects a record deleted on the server but present locally: The local record is soft-deleted to match the server state.
- Device storage full: Warn the user when storage is low. Prevent new captures if storage is critically low rather than crashing.
- First sync after long offline period (many records to sync): Process records in batches to avoid timeout. Show progress to the user.

---

### F-009: Storage Mode Choice

**Feature Name**: Storage Mode Choice (Cloud+Device or Device-Only)

**Description**: During onboarding or at any time in settings, the user can choose their preferred storage mode. "Cloud+Device" stores data both locally and in the cloud (DynamoDB, S3), enabling cross-device access and cloud backup. "Device-Only" stores all data exclusively on the local device, with no data transmitted to or stored in the cloud. This choice supports GDPR user autonomy. In device-only mode, cloud LLM refinement (F-003) and server-side notifications (F-006) are also disabled, since they require sending data to the cloud.

**User Story**: As a user, I want to choose whether my receipt data is stored only on my device or also backed up to the cloud, so that I have full control over where my personal data lives.

**Acceptance Criteria**:
- The storage mode choice is presented during onboarding with a clear explanation of each option.
- The user can change their storage mode at any time in Settings.
- In "Cloud+Device" mode: data syncs between the local database and DynamoDB/S3, cloud LLM refinement is enabled, and server-side notifications are enabled.
- In "Device-Only" mode: no data leaves the device, cloud sync is disabled, cloud LLM refinement is disabled, and only local notifications are available.
- Switching from "Cloud+Device" to "Device-Only": the user is warned that cloud data will be deleted and is asked to confirm. Upon confirmation, a deletion request is sent to the server to wipe all cloud-stored data (DynamoDB records and S3 objects). Local data is preserved.
- Switching from "Device-Only" to "Cloud+Device": the user is informed that local data will begin syncing to the cloud. An initial full sync is triggered.
- The current storage mode is clearly indicated in Settings.
- The storage mode is stored locally and does not depend on an internet connection to read.

**Priority**: Must-have

**Dependencies**:
- F-008 (Offline-First Storage): The sync engine must respect the storage mode setting.
- F-003 (Cloud LLM Refinement): Disabled in device-only mode.
- F-006 (Push Notification Reminders): Server-side notifications disabled in device-only mode.
- F-010 (Authentication): Cloud+Device mode requires authentication. Device-only mode can function with or without authentication, but authentication is required to switch to Cloud+Device mode later.

**Edge Cases and Error Handling**:
- User switches to device-only while a sync is in progress: The current sync operation completes (to avoid partial state), then cloud sync is disabled and the cloud deletion request is sent.
- Cloud deletion fails (network error during mode switch): Queue the deletion request and retry. Inform the user that cloud data deletion is pending and will complete when connectivity is restored.
- User switches back to Cloud+Device shortly after switching to Device-Only: If the cloud deletion has already executed, the user starts fresh with a full upload. If deletion is still pending, cancel the pending deletion.
- User has a large amount of data when switching to Cloud+Device: The initial sync may take time. Show progress and allow the user to continue using the app during sync.
- User in device-only mode loses their phone: Data is unrecoverable. This is the expected trade-off and should be clearly communicated during the storage mode selection.

---

### F-010: Authentication

**Feature Name**: Authentication (Cognito Email+Password, Google Sign-In, Apple Sign-In via Amplify Gen 2)

**Description**: User authentication is handled by AWS Cognito User Pool (Lite tier) integrated via Amplify Flutter Gen 2. Users can sign up and log in with email and password, Google Sign-In, or Apple Sign-In. Apple Sign-In is mandatory because the app offers Google Sign-In on iOS (Apple App Store requirement). Access tokens expire after 1 hour, ID tokens after 1 hour, and refresh tokens after 30-90 days. Amplify handles token refresh transparently. Authentication is required for cloud features (sync, LLM refinement, server notifications) but the app can function in a limited mode without authentication if the user chooses device-only storage.

**User Story**: As a user, I want to create an account and log in securely using my email or my existing Google or Apple account, so that my data is protected and accessible across devices.

**Acceptance Criteria**:
- Users can sign up with email and password. Email verification is required.
- Users can sign in with Google Sign-In (OAuth 2.0 via Cognito hosted UI or native SDK).
- Users can sign in with Apple Sign-In (mandatory for iOS apps offering social login).
- Password requirements follow Cognito defaults: minimum 8 characters, at least one uppercase, one lowercase, one number, and one special character.
- Amplify Flutter Gen 2 handles the full auth flow: sign up, sign in, sign out, password reset, token management, and session refresh.
- Access and ID tokens expire after 1 hour. Refresh tokens expire after 30-90 days (configurable).
- Token refresh is handled transparently by Amplify; the user does not experience session interruptions during normal use.
- The user can sign out, which clears the local session but preserves local data.
- The user can reset their password via email.
- Auth state persists across app restarts (via refresh token).
- If the user's session expires entirely (refresh token expired), they are redirected to the login screen.

**Priority**: Must-have

**Dependencies**:
- None (foundational feature).

**Edge Cases and Error Handling**:
- Email already registered: Display a clear error message and suggest signing in or resetting the password.
- Google/Apple account already linked to a different Cognito account: Display an error and guide the user to sign in with their original method.
- Network error during sign-up: Display a retry option. Do not create a partial account.
- Email verification link expired: Offer to resend the verification email.
- User signs up with email, then tries Google Sign-In with the same email: Cognito handles account linking. The user should be prompted to link accounts or informed that the email is already registered.
- Refresh token expired while offline: The user continues using the app with local data. When they come online, they are prompted to re-authenticate. No data is lost.
- Simultaneous sessions on multiple devices: Allowed. Cognito does not enforce single-session by default. Sync handles multi-device data consistency.
- Account lockout after too many failed attempts: Cognito enforces brute-force protection. Display a message indicating the account is temporarily locked and suggest password reset.

---

### F-011: App Lock

**Feature Name**: App Lock (Biometric/PIN via local_auth, Optional, Prompted at Onboarding)

**Description**: Users can optionally enable an app lock that requires biometric authentication (fingerprint or face recognition) or a device PIN/passcode to open the app. This is a local security feature separate from Cognito authentication: it uses the device's built-in biometric capabilities via the `local_auth` Flutter package. App lock is prompted during onboarding but is not forced. It can be enabled or disabled at any time in settings. When enabled, the lock screen appears every time the app is opened or resumed from background after a configurable timeout.

**User Story**: As a user, I want to protect my receipt data with my fingerprint or face ID, so that no one else can access my financial information if they pick up my phone.

**Acceptance Criteria**:
- During onboarding, the user is asked if they want to enable app lock. They can skip this step.
- App lock can be toggled on or off in settings at any time.
- When enabled, the app requires biometric or PIN authentication on every app launch.
- When enabled, the app requires re-authentication after resuming from background if the app was in the background for longer than the configured timeout (default: immediately, configurable to 1 minute, 5 minutes, or 15 minutes).
- The lock screen uses the device's native biometric UI (Touch ID, Face ID on iOS; fingerprint, face unlock on Android).
- If biometrics are not available on the device, the device PIN/passcode is used as a fallback.
- If the device has no biometrics and no PIN/passcode set, the user is informed that app lock requires device security to be configured, with a link to device settings.
- App lock is independent of Cognito authentication; it works offline and does not require an internet connection.
- Failed biometric attempts fall back to device PIN/passcode.

**Priority**: Should-have

**Dependencies**:
- F-010 (Authentication): App lock is layered on top of Cognito auth. The user must be authenticated (or in device-only mode) before app lock is relevant.

**Edge Cases and Error Handling**:
- Device biometrics change (e.g., new fingerprint added): The `local_auth` package uses the device keystore, so new biometrics are automatically accepted. This is standard device behavior.
- User removes all biometrics from device after enabling app lock: The app falls back to device PIN/passcode. If no PIN/passcode is set either, app lock is effectively disabled with a warning to the user.
- App lock enabled but device security is later disabled: On next app open, detect that device security is no longer available, disable app lock, and inform the user.
- Multiple rapid failed attempts: Defer to the operating system's lockout behavior (e.g., iOS disables biometrics temporarily after too many failures).
- App lock screen and incoming notification: If the user taps a notification while the app is locked, the lock screen appears first, then the user is taken to the relevant receipt after successful authentication.

---

### F-012: Export and Share

**Feature Name**: Export and Share (Share Single Receipt, Batch Export by Date Range)

**Description**: Users can share individual receipts or export batches of receipts. Sharing a single receipt generates a shareable format (image or PDF) containing the receipt image(s) and key metadata (store name, date, total, warranty info). Batch export allows the user to select a date range and export all matching receipts as a bundled file (e.g., ZIP of PDFs, CSV of metadata). Export is useful for tax filing, insurance claims, or personal record-keeping.

**User Story**: As a user, I want to share a single receipt with someone or export a batch of my receipts for a time period, so that I can use my receipt data for tax filing, warranty claims, or personal records.

**Acceptance Criteria**:
- From the receipt detail view, the user can tap a "Share" button to share the receipt via the device's native share sheet.
- The shared output includes the receipt image(s) and a summary of key fields (store, date, total, warranty status).
- The shared format options include: image (annotated JPEG with metadata overlay) and PDF (receipt image with metadata below).
- Batch export is accessible from settings or a dedicated export option.
- Batch export allows the user to specify a date range (start date and end date).
- Batch export generates a ZIP file containing individual PDFs for each receipt and a summary CSV with all metadata.
- The export file is saved to the device's downloads folder or shared via the native share sheet.
- Export works offline using data from the local database.
- Export progress is shown for batch operations.
- The generated files do not include the raw OCR text or internal metadata, only user-facing fields.

**Priority**: Should-have

**Dependencies**:
- F-008 (Offline-First Storage): Export reads from the local database.
- F-001 (Photo Capture): Receipt images are included in the export.

**Edge Cases and Error Handling**:
- Date range with no receipts: Display a message indicating no receipts exist in the selected range.
- Very large batch export (hundreds of receipts): Show progress, process in chunks, and warn the user about estimated file size before starting.
- Insufficient device storage for export file: Check available storage before starting and warn the user if space is limited.
- Export interrupted (app killed or device restarted): The partial export file is cleaned up. The user must restart the export.
- Receipt with no image (e.g., manually created): Export the metadata only, with a placeholder noting no image is available.
- Sharing fails (no compatible app installed): Display the native OS error. On most devices, at least basic sharing options are always available.

---

### F-013: Custom Categories

**Feature Name**: Custom Categories (10 Defaults + User-Created, Edit, Delete)

**Description**: The app ships with 10 default receipt categories as suggestions. Users can also create their own custom categories. Default categories cannot be deleted or renamed, but custom categories can be edited and deleted. Categories are used for organizing receipts, filtering search results, and display purposes. Each receipt is assigned one category. The LLM may suggest a category during cloud refinement.

**Default Categories** (10):
1. Groceries
2. Electronics
3. Clothing
4. Home & Garden
5. Health & Beauty
6. Dining & Restaurants
7. Transportation
8. Entertainment
9. Services
10. Other

**User Story**: As a user, I want to organize my receipts into categories that make sense to me, including custom categories I create, so that I can find and group related receipts easily.

**Acceptance Criteria**:
- 10 default categories are available out of the box.
- Default categories cannot be deleted or renamed by the user.
- Users can create new custom categories with a name and optional icon/color.
- Users can edit custom category names and appearance.
- Users can delete custom categories. When a custom category is deleted, receipts in that category are moved to "Other" (or the user is asked to choose a replacement category).
- Each receipt is assigned exactly one category.
- The category selector in the receipt edit form shows default categories first, then custom categories in alphabetical order.
- Categories are synced across devices in Cloud+Device mode.
- Categories are stored in the DynamoDB table using the META#CATEGORIES sort key for cloud users.
- The LLM can suggest a category from the full list (defaults + custom) during cloud refinement.

**Priority**: Should-have

**Dependencies**:
- F-008 (Offline-First Storage): Categories are stored in the local database.
- F-004 (Manual Field Edit): Category assignment happens in the edit form.
- F-007 (Search and Filters): Category filter uses the category list.

**Edge Cases and Error Handling**:
- User creates a category with the same name as a default category: Prevent duplicates. Display an error indicating the name is already in use.
- User creates a category with the same name as an existing custom category: Prevent duplicates.
- Sync conflict on categories (two devices edit category list simultaneously): The sync engine merges category lists, keeping the union of all categories. If a category was renamed on one device and deleted on another, the rename takes precedence (preserve over delete).
- User has receipts in a custom category, then deletes the category on another device: On sync, the receipts are reassigned to "Other."
- Maximum number of custom categories: Enforce a reasonable limit (e.g., 50 custom categories) to prevent UI clutter.
- Category name with special characters or emoji: Allow alphanumeric characters, spaces, and common punctuation. Emoji support is optional and not a priority for v1.0.
- Category name too long: Enforce a character limit (e.g., 30 characters) with a visible counter.

---

### F-014: Mark as Returned

**Feature Name**: Mark as Returned (Status Toggle on Receipt)

**Description**: Users can mark a receipt as "Returned" to indicate that the purchased item was returned. This is a simple status toggle that changes the receipt's visual appearance (e.g., "Returned" badge) and excludes it from active warranty tracking. The return action is reversible: users can unmark a receipt as returned. Marking as returned does not delete the receipt or its data.

**User Story**: As a user, I want to mark a receipt as returned when I return an item, so that my warranty list and stats accurately reflect only items I still own.

**Acceptance Criteria**:
- A "Mark as Returned" button is available in the receipt detail view.
- Tapping the button shows a confirmation dialog before applying the status change.
- A "Returned" receipt displays a distinct visual badge or indicator (e.g., a "Returned" label in the card view and detail view).
- Returned receipts are excluded from the Expiring tab (warranty tracking view).
- Returned receipts are excluded from the warranty-related stats on the home screen.
- Returned receipts are still searchable and appear in search results and the main vault list.
- A "Returned" filter option is available in the search filters (F-007).
- The return status can be toggled off (unmarked) if the user changes their mind.
- The return date is recorded when the receipt is marked as returned.
- The status change syncs to the cloud in Cloud+Device mode.

**Priority**: Nice-to-have

**Dependencies**:
- F-005 (Warranty Tracking): Returned receipts are excluded from warranty views.
- F-018 (Stats Display): Returned receipts are excluded from stats calculations.
- F-008 (Offline-First Storage): Status change is saved locally and synced.

**Edge Cases and Error Handling**:
- Marking a receipt as returned while offline: The status change is saved locally and synced when connectivity is restored.
- Receipt is marked as returned on one device and edited on another simultaneously: The "returned" status is a single field; the most recent change wins via timestamp.
- Returned receipt with an active warranty: The warranty data is preserved but the receipt is no longer counted in active warranty displays. If the user unmarks the receipt, the warranty status becomes visible again.
- Bulk-marking receipts as returned: Not supported in v1.0. The user must mark each receipt individually.

---

### F-015: Soft Delete

**Feature Name**: Soft Delete (30-Day Recovery, Hard Wipe on Account Deletion)

**Description**: When a user deletes a receipt, it is not immediately permanently destroyed. Instead, it enters a "soft deleted" state where it is hidden from all views but can be recovered within 30 days. After 30 days, the receipt is permanently and irrecoverably deleted (hard delete). For cloud users, images in S3 use S3 Versioning with NoncurrentVersionExpiration set to 30 days, which handles image cleanup natively. DynamoDB records use TTL for automatic expiration. When a user deletes their entire account, all data is immediately hard-wiped (no 30-day grace period) via a Lambda cascade: Cognito user deletion, DynamoDB record deletion, and S3 object deletion.

**User Story**: As a user, I want to be able to recover a receipt I accidentally deleted within 30 days, and I want to be sure that when I delete my account, all my data is permanently and completely removed.

**Acceptance Criteria**:
- Deleting a receipt moves it to a "Deleted" state (soft delete). It disappears from all regular views.
- A "Recently Deleted" section is accessible in settings or a dedicated area, showing all soft-deleted receipts with their remaining recovery time.
- The user can restore a soft-deleted receipt, which returns it to its original state (including category, warranty, and all metadata).
- After 30 days, soft-deleted receipts are permanently removed from the local database and from cloud storage (DynamoDB TTL + S3 NoncurrentVersionExpiration).
- Account deletion triggers immediate hard wipe of all data: Cognito user record, all DynamoDB records for the user, and all S3 objects (images and thumbnails).
- Account deletion requires multiple confirmations (see user flow documentation).
- Soft-deleted receipts do not appear in search results, warranty tracking, stats, or any other view except the "Recently Deleted" section.
- Soft-deleted receipts do not trigger warranty expiry notifications.
- The soft delete status syncs between devices in Cloud+Device mode.

**Priority**: Must-have

**Dependencies**:
- F-008 (Offline-First Storage): Soft delete flag is stored in the local database and synced.
- F-010 (Authentication): Account deletion requires authentication.

**Edge Cases and Error Handling**:
- User soft-deletes a receipt while offline: The delete is recorded locally with a timestamp. When synced, the cloud record is also soft-deleted. The 30-day timer starts from the original delete timestamp.
- User restores a receipt on one device while it is still soft-deleted on another: On sync, the restore takes precedence (restore over delete).
- Account deletion while offline: The local database is wiped. The cloud deletion request is queued and executed when connectivity is restored. A flag is set to ensure the deletion completes.
- Account deletion fails mid-cascade (e.g., S3 deletion succeeds but DynamoDB deletion fails): The Lambda cascade logs the failure and retries. An alarm is triggered for manual investigation if retries exhaust.
- User tries to recover a receipt after 30 days: The receipt no longer exists. Display a clear message that the recovery period has expired.
- Device-only mode: Soft delete works identically on the local database. There is no cloud data to delete. Account deletion in device-only mode deletes the Cognito account (if one exists) and wipes the local database.

---

### F-016: Bulk Import

**Feature Name**: Bulk Import (Scan Gallery for Receipt-Like Images at Onboarding)

**Description**: During onboarding, the app offers to scan the user's photo gallery for images that look like receipts. This addresses the cold-start problem: new users likely have receipt photos scattered in their camera roll. The app uses image analysis heuristics (aspect ratio, text density, presence of numbers) to identify likely receipt images and presents them to the user for review. The user can select which images to import, and each selected image goes through the standard OCR pipeline.

**User Story**: As a new user, I want the app to find receipt photos already in my gallery and import them, so that I do not start with an empty vault and can immediately see value from the app.

**Acceptance Criteria**:
- During onboarding, after sign-up, the user is asked "Would you like to import receipts from your photo gallery?"
- If the user agrees, the app requests gallery read permission and scans for receipt-like images.
- The scanning process analyzes images for receipt characteristics: tall/narrow aspect ratio, high text density, presence of numbers and currency symbols, white/light background.
- Candidate images are presented in a grid for the user to review and select/deselect.
- The user can select all, deselect all, or individually toggle images.
- Selected images are imported and queued for OCR processing.
- A progress indicator shows import and processing progress.
- The bulk import feature is also accessible later from settings (not only during onboarding).
- OCR for bulk-imported images runs in the background so the user can start using the app immediately.
- The import process is rate-limited to avoid freezing the device: images are processed in batches.

**Priority**: Nice-to-have

**Dependencies**:
- F-001 (Photo Capture): Uses the same image import pipeline.
- F-002 (On-Device OCR): Each imported image is processed with OCR.
- F-020 (Image Compression): Imported images are compressed before storage.

**Edge Cases and Error Handling**:
- Gallery contains thousands of photos: Limit the scan to the most recent N photos (e.g., last 6 months or last 1000 images) to keep the scan time reasonable. Show progress during scanning.
- No receipt-like images found: Display a friendly message and skip the import step.
- User denies gallery permission: Skip the import step with a note that they can try again later from settings.
- Duplicate detection: If the user later imports the same image via the normal import flow, warn about the potential duplicate (same file hash).
- Image analysis falsely identifies a non-receipt as a receipt: The user can deselect false positives in the review grid. The heuristic should err on the side of inclusion.
- Image analysis misses an actual receipt: The user can manually import it later via the standard capture flow.
- Large number of selected images (e.g., 50+): Process in batches and warn the user that processing will take several minutes.
- App killed during bulk import: Track which images have been successfully imported. On next app launch, offer to resume the import.

---

### F-017: Home Screen Widget

**Feature Name**: Home Screen Widget (Quick Capture Shortcut)

**Description**: A home screen widget provides a one-tap shortcut to launch the receipt capture flow directly from the device's home screen. This reduces the friction of capturing a receipt by eliminating the need to open the app, navigate to the capture screen, and tap the capture button. The widget is small (1x1 or 2x1 cells) and branded with the app icon and a camera indicator. Tapping the widget opens the app directly to the camera capture screen.

**User Story**: As a user, I want a home screen widget that lets me start capturing a receipt with one tap, so that I build a habit of capturing receipts immediately at the store.

**Acceptance Criteria**:
- A home screen widget is available for both Android and iOS.
- The widget is selectable from the device's widget picker.
- Tapping the widget opens the app directly to the camera capture screen, bypassing the home screen.
- If app lock (F-011) is enabled, the lock screen appears before the camera screen.
- The widget is visually consistent with the app's brand: warm cream and forest green color scheme, app logo, and a camera icon.
- The widget is available in two sizes: 1x1 (icon only) and 2x1 (icon + "Capture Receipt" label).
- On iOS, the widget uses WidgetKit. On Android, the widget uses the standard AppWidgetProvider approach (via Flutter's home_widget package or similar).
- The widget does not display sensitive data (no receipt information on the widget itself).

**Priority**: Nice-to-have

**Dependencies**:
- F-001 (Photo Capture): The widget launches directly into the capture flow.
- F-011 (App Lock): If enabled, the lock screen intercepts the widget launch.

**Edge Cases and Error Handling**:
- Camera permission not yet granted: The widget opens the app, which requests camera permission via the standard permission flow.
- Widget tapped while offline: The capture flow works offline, so this is not an issue.
- App not logged in (session expired): The widget opens the app to the login screen. After login, the user can navigate to capture.
- iOS widget limitations: iOS widgets are more restricted than Android widgets. The 1x1 widget may be the only supported size on iOS due to WidgetKit constraints.
- App updates that change the widget: Ensure backward compatibility so existing widget placements are not broken.

---

### F-018: Stats Display

**Feature Name**: Stats Display ("X receipts, Y in active warranties" on Home Screen)

**Description**: The home screen displays a summary statistics bar showing the total number of receipts in the vault and the total monetary value covered by active warranties. This reinforces the app's value to the user by quantifying what the app is protecting. The stats are calculated from the local database and update in real time as receipts are added, edited, or deleted.

**User Story**: As a user, I want to see a quick summary of how many receipts I have and the total value of my active warranties, so that I understand the value the app is providing me.

**Acceptance Criteria**:
- The home screen (Vault tab) displays a stats bar with: "X receipts" (total non-deleted receipts) and "Y in active warranties" (sum of total amounts for receipts with Active or Expiring Soon warranty status).
- The currency symbol matches the user's most frequently used currency, or defaults to the Euro sign if no receipts exist.
- Stats update in real time: adding, editing, deleting, or restoring a receipt immediately updates the displayed numbers.
- Returned receipts (F-014) are excluded from the active warranty value.
- Soft-deleted receipts (F-015) are excluded from both counts.
- The stats calculation runs locally and works offline.
- The numbers are formatted with appropriate locale-aware separators (e.g., "1,234 receipts" in English or "1.234 receipts" in Greek).

**Priority**: Nice-to-have

**Dependencies**:
- F-008 (Offline-First Storage): Stats are computed from local database queries.
- F-005 (Warranty Tracking): Active warranty calculation depends on warranty status logic.
- F-014 (Mark as Returned): Returned receipts are excluded from warranty stats.
- F-015 (Soft Delete): Soft-deleted receipts are excluded from all stats.
- F-019 (English and Greek Localization): Number formatting follows locale conventions.

**Edge Cases and Error Handling**:
- No receipts in the vault: Display "0 receipts" and hide or show a zero value for warranties.
- Receipts with different currencies: Sum only receipts in the most frequently used currency. Display a note if multiple currencies are present (e.g., "and 3 receipts in other currencies"). Alternatively, display the total per currency if space allows.
- Very large numbers: Ensure formatting handles totals in the thousands or tens of thousands without truncation or overflow.
- Receipts with no amount: These are excluded from the monetary total but included in the receipt count.

---

### F-019: English and Greek Localization

**Feature Name**: English and Greek Localization

**Description**: The app is fully localized in two languages for v1.0: English (en) and Greek (el). All user-facing text, labels, buttons, error messages, notifications, and system messages are translated. The app detects the device language and defaults to the matching locale. If the device language is neither English nor Greek, the app defaults to English. Users can override the language in settings.

**User Story**: As a Greek-speaking user, I want to use the app in my native language, so that the interface is comfortable and intuitive for me.

**Acceptance Criteria**:
- All user-facing strings are externalized using Flutter's localization framework (intl package and ARB files).
- Complete translations exist for both English (en) and Greek (el).
- The app auto-detects the device locale and sets the language accordingly.
- If the device locale is not English or Greek, the app defaults to English.
- Users can manually select their preferred language in settings, overriding the device locale.
- The language selection takes effect immediately without requiring an app restart.
- Date formats follow the selected locale (e.g., MM/DD/YYYY for English, DD/MM/YYYY for Greek).
- Number formats follow the selected locale (e.g., 1,234.56 for English, 1.234,56 for Greek).
- Currency display follows the selected locale.
- Right-to-left layouts are not required (neither English nor Greek is RTL).
- Push notification content (both local and server-side) is in the user's selected language.
- Default category names are translated in both languages.
- Error messages and validation text are translated.
- Onboarding screens are fully translated.
- The app name in the app store listing is provided in both languages (for future submission).

**Priority**: Must-have

**Dependencies**:
- All features that display user-facing text depend on the localization framework being in place.

**Edge Cases and Error Handling**:
- Missing translation key: Fall back to the English string rather than showing a key identifier or empty string.
- Dynamic content (e.g., store names from OCR): These are not translated; they are displayed as extracted. Only UI labels and system messages are localized.
- Pluralization: Use the intl package's plural support for messages like "1 receipt" vs. "5 receipts" and "1 day remaining" vs. "30 days remaining." Greek has different plural rules than English; both must be handled correctly.
- Text expansion: Greek translations may be longer than English equivalents. UI layouts must accommodate text expansion without truncation or overflow.
- User switches language while viewing a receipt: The UI labels update immediately. Receipt data (store name, notes) remains in its original language.

---

### F-020: Image Compression

**Feature Name**: Image Compression (JPEG 85%, Strip GPS EXIF, 200x300 Thumbnails)

**Description**: All captured or imported receipt images are compressed and processed before storage. Full-size images are saved as JPEG at 85% quality, which provides a good balance between file size (1-2MB per receipt) and visual quality that preserves OCR readability. GPS EXIF data is stripped from all images for privacy (users may capture receipts at home and not want their home location embedded in the image). Thumbnails are generated at 200x300 pixels and JPEG 70% quality for use in list views and grid displays. For cloud users, a Lambda function generates thumbnails server-side upon S3 upload. For device-only users, thumbnails are generated locally.

**User Story**: As a user, I want my receipt images to be stored efficiently without wasting device storage, and I want my location data stripped from receipt photos for privacy.

**Acceptance Criteria**:
- Captured images are compressed to JPEG format at 85% quality before local storage.
- Imported images (JPEG, PNG) are re-encoded to JPEG at 85% quality.
- GPS/location EXIF data is stripped from all images before storage.
- Other EXIF data (orientation, timestamp) is preserved to ensure correct display.
- Thumbnails are generated at 200x300 pixels, JPEG 70% quality.
- Thumbnails are generated locally for device-only users and server-side (Lambda) for cloud users.
- The original uncompressed image is not stored; only the compressed version is saved.
- Compression runs before OCR to ensure OCR processes the same image that is stored.
- Image quality at 85% JPEG remains sufficient for OCR accuracy (validated during testing).
- Resulting file sizes are in the 1-2MB range for typical receipt photos.
- PDF imports: each page is rendered as a JPEG at 85% quality following the same pipeline.

**Priority**: Must-have

**Dependencies**:
- F-001 (Photo Capture): Compression is applied to captured/imported images.
- F-002 (On-Device OCR): OCR processes the compressed image.
- F-008 (Offline-First Storage): Compressed images and thumbnails are stored locally.

**Edge Cases and Error Handling**:
- Image already smaller than 200x300 pixels: Do not upscale for the thumbnail. Use the original image dimensions.
- Extremely large image (e.g., 50MP camera): Resize to a maximum resolution (e.g., 4000 pixels on the longest side) before applying 85% JPEG compression, to keep file sizes under 2MB.
- Image with no EXIF data: Proceed normally; there is nothing to strip.
- PNG with transparency: Convert to JPEG, replacing transparency with a white background.
- Corrupted image file: If the image cannot be read or compressed, report an error to the user and skip the image.
- Lambda thumbnail generation fails: The app uses the full-size image as a fallback in list views (scaled down by the image widget). A retry mechanism re-triggers thumbnail generation on the next sync.

---

## Deferred Features -- v1.5

The following features are planned for v1.5 (Polish release, before public launch). They are not included in v1.0.

### DF-001: LLM Smart Search (Natural Language)

**Description**: Users can search their receipts using natural language queries processed by Bedrock Claude. For example, "What did I buy at IKEA last summer?" or "Show me all electronics purchases over 100 euros." The LLM interprets the query, translates it into structured filters, and returns relevant results.

**Rationale for Deferral**: The keyword search and structured filters in v1.0 (F-007) cover the primary search needs. Natural language search requires additional Bedrock API calls per query (cost implications), prompt engineering, and testing to ensure quality. It is a polish feature that enhances usability but is not essential for core functionality.

### DF-002: Spending Insights Dashboard

**Description**: A dedicated insights view that shows spending breakdowns by category, store, and time period. Includes charts (bar, pie, line) showing spending trends, top categories, most visited stores, and month-over-month comparisons.

**Rationale for Deferral**: Requires substantial UI development (charts, animations) and data aggregation logic. The stats display (F-018) provides a basic value indicator in v1.0. Full insights are a high-value feature but not critical for the initial tester release.

### DF-003: Additional Languages

**Description**: Expand localization beyond English and Greek to include additional languages based on user demand. Candidate languages include German, French, Spanish, Italian, and Arabic (RTL support required for Arabic).

**Rationale for Deferral**: Each language requires complete translation of all UI strings, date/number formatting, and potentially OCR engine support. English and Greek cover the initial tester audience.

### DF-004: Auto-Archiving

**Description**: Configurable auto-archiving that moves old receipts (e.g., older than 1 year with expired warranties) to an archive view. The user controls the archiving rules and can approve or reject batch archive suggestions.

**Rationale for Deferral**: Requires designing the archive UX, configurable rules engine, and user approval flow. Low priority for a small receipt collection (v1 testers).

---

## Deferred Features -- v2.0

The following features are planned for v2.0 (Growth release). They are not included in v1.0 or v1.5.

### DF-005: Email Forwarding Capture

**Description**: Users receive a dedicated email address (e.g., user@receiptvault.app) where they can forward digital receipts. The system parses incoming emails, extracts receipt attachments (PDFs, images), and adds them to the user's vault automatically. Supports common digital receipt formats from major retailers and online stores.

**Rationale for Deferral**: Requires email infrastructure (SES inbound, parsing Lambda), handling diverse email formats, and significant anti-spam/security work. Too complex for v1.

### DF-006: Household Shared Vault

**Description**: Multiple users can share a single vault, enabling families or households to pool their receipts. Features include shared access, per-user permissions (viewer vs. editor), activity log, and conflict resolution for multi-user edits.

**Rationale for Deferral**: Multi-user sync introduces substantial complexity: shared data models, permission systems, invitation flows, and concurrent edit handling. Deferred to v2.0 when single-user architecture is proven stable.

### DF-007: Return Window Tracking

**Description**: Separate from warranty tracking, return window tracking monitors store-specific return policies (e.g., "30-day return policy at Store X"). The app would maintain a database of known return policies and alert users before return windows close.

**Rationale for Deferral**: Requires building and maintaining a store return policy database, which is region-specific and changes frequently. The current "Mark as Returned" feature (F-014) provides a manual approach for v1.

### DF-008: Multi-Region Deployment

**Description**: Deploy the backend to multiple AWS regions (e.g., eu-west-1 for Europe, us-east-1 for North America, ap-southeast-1 for Asia) with data residency controls. Users' data is stored in their selected region. Global DynamoDB tables or cross-region replication handles travelers.

**Rationale for Deferral**: Requires DynamoDB Global Tables, multi-region S3 replication, and region-aware routing. The single eu-west-1 deployment covers all initial users with GDPR compliance applied globally.

---

## Feature Dependency Map

The following diagram shows the dependency relationships between all v1.0 features. An arrow from Feature A to Feature B means Feature A depends on Feature B.

```
F-001 (Photo Capture)
  ├── depends on → F-020 (Image Compression)
  └── depends on → F-008 (Offline-First Storage)

F-002 (On-Device OCR)
  ├── depends on → F-001 (Photo Capture)
  └── depends on → F-008 (Offline-First Storage)

F-003 (Cloud LLM Refinement)
  ├── depends on → F-002 (On-Device OCR)
  ├── depends on → F-008 (Offline-First Storage)
  └── depends on → F-010 (Authentication)

F-004 (Manual Field Edit)
  ├── depends on → F-002 (On-Device OCR)
  ├── depends on → F-003 (Cloud LLM Refinement)
  ├── depends on → F-013 (Custom Categories)
  └── depends on → F-008 (Offline-First Storage)

F-005 (Warranty Tracking)
  ├── depends on → F-004 (Manual Field Edit)
  └── depends on → F-003 (Cloud LLM Refinement)

F-006 (Push Notification Reminders)
  ├── depends on → F-005 (Warranty Tracking)
  ├── depends on → F-010 (Authentication)
  └── depends on → F-008 (Offline-First Storage)

F-007 (Search and Filters)
  ├── depends on → F-008 (Offline-First Storage)
  ├── depends on → F-002 (On-Device OCR)
  ├── depends on → F-013 (Custom Categories)
  └── depends on → F-005 (Warranty Tracking)

F-008 (Offline-First Storage)
  ├── depends on → F-010 (Authentication) [for cloud sync]
  └── depends on → F-009 (Storage Mode Choice) [to determine sync behavior]

F-009 (Storage Mode Choice)
  ├── depends on → F-008 (Offline-First Storage)
  ├── depends on → F-003 (Cloud LLM Refinement)
  ├── depends on → F-006 (Push Notification Reminders)
  └── depends on → F-010 (Authentication) [for cloud mode]

F-010 (Authentication)
  └── no dependencies (foundational)

F-011 (App Lock)
  └── depends on → F-010 (Authentication)

F-012 (Export and Share)
  ├── depends on → F-008 (Offline-First Storage)
  └── depends on → F-001 (Photo Capture)

F-013 (Custom Categories)
  ├── depends on → F-008 (Offline-First Storage)
  └── depends on → F-004 (Manual Field Edit) [category selector in edit form]

F-014 (Mark as Returned)
  ├── depends on → F-005 (Warranty Tracking)
  ├── depends on → F-018 (Stats Display)
  └── depends on → F-008 (Offline-First Storage)

F-015 (Soft Delete)
  ├── depends on → F-008 (Offline-First Storage)
  └── depends on → F-010 (Authentication) [for account deletion]

F-016 (Bulk Import)
  ├── depends on → F-001 (Photo Capture)
  ├── depends on → F-002 (On-Device OCR)
  └── depends on → F-020 (Image Compression)

F-017 (Home Screen Widget)
  ├── depends on → F-001 (Photo Capture)
  └── depends on → F-011 (App Lock)

F-018 (Stats Display)
  ├── depends on → F-008 (Offline-First Storage)
  ├── depends on → F-005 (Warranty Tracking)
  ├── depends on → F-014 (Mark as Returned)
  ├── depends on → F-015 (Soft Delete)
  └── depends on → F-019 (English and Greek Localization)

F-019 (English and Greek Localization)
  └── no feature dependencies (cross-cutting concern)

F-020 (Image Compression)
  ├── depends on → F-001 (Photo Capture)
  ├── depends on → F-002 (On-Device OCR)
  └── depends on → F-008 (Offline-First Storage)
```

### Implementation Priority Order (Suggested)

Based on the dependency graph, the recommended implementation order is:

1. **F-010** (Authentication) — foundational, no dependencies
2. **F-019** (Localization) — cross-cutting, should be in place early
3. **F-008** (Offline-First Storage) — foundational data layer
4. **F-020** (Image Compression) — needed before capture pipeline
5. **F-001** (Photo Capture) — primary input mechanism
6. **F-002** (On-Device OCR) — core extraction
7. **F-013** (Custom Categories) — needed by edit form
8. **F-004** (Manual Field Edit) — edit form with categories
9. **F-003** (Cloud LLM Refinement) — cloud extraction polish
10. **F-005** (Warranty Tracking) — hero feature
11. **F-009** (Storage Mode Choice) — user autonomy
12. **F-007** (Search and Filters) — findability
13. **F-006** (Push Notification Reminders) — proactive engagement
14. **F-015** (Soft Delete) — data safety
15. **F-014** (Mark as Returned) — status management
16. **F-018** (Stats Display) — value reinforcement
17. **F-011** (App Lock) — optional security
18. **F-012** (Export and Share) — data portability
19. **F-016** (Bulk Import) — onboarding enhancement
20. **F-017** (Home Screen Widget) — habit formation

---

*End of Feature Specification*
