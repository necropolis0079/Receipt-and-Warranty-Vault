# 13 -- Testing Strategy

**Document**: Testing Strategy
**Version**: 1.0
**Status**: Pre-Implementation (Documentation Phase)
**Last Updated**: 2026-02-08

---

## Table of Contents

1. [Testing Philosophy](#testing-philosophy)
2. [Unit Tests (Flutter)](#unit-tests-flutter)
3. [Widget Tests (Flutter)](#widget-tests-flutter)
4. [Integration Tests (Flutter)](#integration-tests-flutter)
5. [Backend Tests (Python / pytest)](#backend-tests-python--pytest)
6. [OCR Accuracy Testing](#ocr-accuracy-testing)
7. [Sync Engine Testing](#sync-engine-testing)
8. [Security Testing](#security-testing)
9. [Performance Testing](#performance-testing)
10. [Device Testing](#device-testing)
11. [Test Data Management](#test-data-management)

---

## Testing Philosophy

### The Test Pyramid

Receipt & Warranty Vault follows a strict test pyramid discipline. The pyramid is not a suggestion -- it is a structural rule that governs where testing effort is invested.

**Base: Many unit tests.** The foundation of all quality assurance. Unit tests cover every BLoC state transition, every repository method, every data model serialization, every utility function, and every Lambda handler. These tests are fast (milliseconds each), isolated (no network, no database, no file system), and deterministic (no flaky failures). The target is hundreds of unit tests that run in under 60 seconds on any developer machine.

**Middle: Fewer integration tests.** Integration tests verify that components work together correctly within the Flutter app and across the client-server boundary. These tests are slower (seconds each), require more setup (emulators, mock servers), and cover complete user flows rather than individual functions. The target is dozens of integration tests covering every critical user journey.

**Top: Minimal end-to-end tests.** Full E2E tests that exercise the real AWS backend are expensive to run, slow, and inherently less stable due to network and infrastructure variability. These are reserved for staging environment validation before releases and are never part of the developer's inner loop.

### Offline-First Means Testing Without Network Is Critical

Because Receipt & Warranty Vault is architecturally offline-first, testing without network connectivity is not an edge case -- it is a primary test condition. Every feature must be tested in three network states:

1. **Online** -- full connectivity, all services reachable.
2. **Offline** -- airplane mode, no network of any kind.
3. **Transitioning** -- starting offline and going online mid-operation, or starting online and losing connectivity mid-operation.

Tests that only pass when the device is online are incomplete. If a feature claims to work offline, a test must prove it.

### OCR Accuracy Testing Requires a Receipt Image Test Corpus

OCR accuracy cannot be tested with synthetic data. The on-device OCR pipeline (ML Kit + Tesseract hybrid) and the cloud LLM refinement pipeline (Bedrock Haiku 4.5) must be evaluated against real receipt images with known correct values. This requires building and maintaining a test corpus of annotated receipt images -- a dedicated, versioned dataset that grows over time and serves as the ground truth for accuracy metrics.

### The Sync Engine Is the Most Complex Component

The custom sync engine -- with its delta sync, full reconciliation, field-level conflict resolution across three ownership tiers, offline queue management, and image sync pipeline -- is the single most complex component in the entire system. It is also the component where bugs have the highest cost: data loss or data corruption in a personal receipt vault destroys user trust irreversibly. The sync engine therefore receives disproportionate testing attention, with dedicated scenario coverage that exceeds what any other component requires.

---

## Unit Tests (Flutter)

### BLoC and Cubit Tests

Every BLoC and Cubit in the application must have comprehensive state transition tests. The pattern is consistent: mock the repository dependencies, dispatch events (for BLoCs) or call methods (for Cubits), and assert that the correct sequence of states is emitted.

**ReceiptListBloc:**
- Initial state is loading, then emits loaded state with receipts from repository.
- Emits filtered state when a filter event is dispatched (by category, store, date range, warranty status).
- Emits sorted state when a sort event is dispatched (by date, by store, by amount).
- Emits error state when the repository throws an exception.
- Handles empty list gracefully (no receipts yet).
- Handles pagination if the receipt list exceeds display threshold.
- Refreshes correctly when a pull-to-refresh event is dispatched.
- Reacts to sync completion events by refreshing the list.

**ReceiptDetailBloc:**
- Loads a single receipt by ID from the repository.
- Emits updated state when the receipt is edited and saved.
- Emits error state when the receipt is not found (deleted on another device).
- Handles the "mark as returned" status toggle.
- Handles soft delete and emits the appropriate navigation state.
- Handles restore from soft delete.
- Tracks which fields the user has edited (for conflict resolution tier tracking).

**AddReceiptBloc:**
- Manages the multi-step capture flow: image selection, preprocessing, OCR extraction, field editing, save.
- Emits capturing state when the camera or gallery is invoked.
- Emits processing state during image crop, rotation, compression, and EXIF stripping.
- Emits extracting state during on-device OCR.
- Emits extracted state with parsed fields (store name, date, total, raw text).
- Emits saving state during local database write.
- Emits saved state with the new receipt ID.
- Emits error state if image capture fails, OCR fails, or save fails.
- Handles the "Fast Save" flow (minimal editing, quick save).
- Queues cloud LLM refinement after save when online.

**SyncBloc:**
- Emits syncing state when a sync is triggered (manual, background, or on-resume).
- Emits synced state with a count of items synced.
- Emits conflict state when a conflict is detected (with details for UI display).
- Emits error state when sync fails (network error, server error).
- Emits partial sync state when a batch sync fails mid-batch.
- Handles cancellation of an in-progress sync.
- Correctly sequences: process sync queue (uploads), then pull delta changes (downloads).

**AuthBloc:**
- Emits authenticated state after successful sign-in (email/password, Google, Apple).
- Emits unauthenticated state after sign-out.
- Emits unauthenticated state when token refresh fails.
- Emits loading state during sign-in and sign-up flows.
- Emits error state with localized error messages for invalid credentials, network errors, and account-not-found.
- Handles the onboarding flow for new sign-ups.
- Handles account deletion confirmation and cascade.

**SettingsBloc:**
- Loads all settings from the settings repository on initialization.
- Emits updated state when any setting is changed.
- Handles storage mode change (cloud+device to device-only and vice versa) with appropriate confirmation and data handling.
- Handles language change (English to Greek and vice versa) with immediate UI update.
- Handles notification preference changes.
- Handles app lock enable/disable with biometric/PIN enrollment.
- Handles data export request and emits progress/completion states.
- Handles account deletion request with confirmation flow.

**CategoryBloc:**
- Loads default categories and user-created categories.
- Emits updated state when a new category is created.
- Emits updated state when a category is renamed or deleted.
- Validates category names (non-empty, non-duplicate, reasonable length).
- Handles the case where a deleted category is still referenced by existing receipts.

**SearchBloc:**
- Emits searching state when a search query is submitted.
- Emits results state with matching receipts from FTS5.
- Emits empty results state when no matches are found.
- Handles combined search with filters (search term + category + date range + warranty status).
- Debounces search input to avoid excessive database queries.
- Handles special characters in search queries without crashing.
- Handles Greek text search correctly.

**WarrantyBloc:**
- Loads receipts with active warranties, sorted by expiry date.
- Emits categorized state: expiring soon (within 30 days), active, expired.
- Handles warranty countdown calculation correctly (including leap years, timezone differences).
- Triggers local notification scheduling when warranty data changes.
- Handles the edge case of warranties expiring today.
- Handles receipts with no warranty information (excluded from warranty views).

### Repository Tests

Repository tests verify the layer that sits between BLoCs and data sources. The repository is where offline-first logic lives -- it decides whether to read from local or remote, whether to queue writes for sync, and how to resolve conflicts.

**ReceiptRepository:**
- When online: fetches from remote, updates local cache, returns merged data.
- When offline: returns data from local database only, with no error.
- When saving: always writes to local database first, then queues remote sync.
- When remote fetch fails: falls back to local data and emits a non-blocking warning.
- Caching behavior: returns local data immediately, then updates with remote data if available (optimistic local-first).
- Conflict resolution: when remote and local versions differ, applies the three-tier conflict resolution rules correctly.
- Soft delete: marks receipt as deleted locally, queues delete for remote sync.
- Restore: reverses soft delete locally, queues restore for remote sync.
- Image handling: associates image file paths with receipt records, queues image uploads.

**CategoryRepository:**
- Returns merged list of default categories and user-created categories.
- Creates new categories locally and queues for remote sync.
- Deletes categories locally and queues for remote sync.
- Handles the case where a category exists locally but not remotely (and vice versa).

**AuthRepository:**
- Wraps Amplify Cognito calls and translates exceptions into domain-specific errors.
- Caches authentication state for offline access.
- Handles token refresh failures gracefully.

**SyncRepository:**
- Manages the sync queue: enqueue, dequeue, peek, batch operations.
- Implements delta sync logic: sends local changes since last sync, receives server changes since last sync.
- Implements full reconciliation: compares all local items with all server items, resolves discrepancies.
- Handles image upload queue separately from metadata sync.
- Tracks sync state: last sync timestamp, items pending, sync in progress.

**Conflict Resolution Tests (Critical):**
These tests deserve special attention because incorrect conflict resolution leads to data loss.

- **Tier 1 (Server/LLM wins):** When the server has updated extracted_merchant_name, extracted_date, extracted_total, ocr_raw_text, or llm_confidence, the server version always wins, regardless of local changes to these fields. Test that local values are overwritten.
- **Tier 2 (Client/User wins):** When the client has updated user_notes, user_tags, or is_favorite, the client version always wins, regardless of server changes to these fields. Test that server values are ignored for these fields.
- **Tier 3 (Client override with tracking):** For display_name, category, and warranty_months, the client wins only if the field name is present in the userEditedFields array (meaning the user explicitly edited this field). If the field is not in userEditedFields, the server version wins. Test both paths for each Tier 3 field.
- **Edge case -- both sides edited the same Tier 3 field:** Client wins because the user's explicit edit takes precedence. Test this scenario.
- **Edge case -- server has updates to Tier 1 fields AND client has updates to Tier 2 fields:** Both are applied. Test that the merge produces a record with server values for Tier 1 and client values for Tier 2.
- **Edge case -- no conflicts:** Both sides have the same version. Test that no merge is attempted and the record is unchanged.
- **Edge case -- client has a receipt that does not exist on the server:** This is a new receipt created offline. Test that it is uploaded as a new item.
- **Edge case -- server has a receipt that does not exist locally:** This is a new receipt from another device or a server-side operation. Test that it is created locally.
- **Edge case -- receipt deleted on server but modified locally:** Server delete wins. Test that the local copy is soft-deleted.
- **Edge case -- receipt deleted locally but modified on server:** Local delete wins (user intent). Test that the server copy is deleted on next sync.

### Data Source Tests

**Drift Database (Local Data Source):**
- CRUD operations: create a receipt, read it back, update fields, delete it. Verify data integrity at each step.
- FTS5 search: insert receipts with various text content, search by keyword, verify correct results are returned. Test partial matches, Greek text matches, and multi-word queries.
- Schema migrations: test that upgrading from schema version N to version N+1 preserves all existing data and applies new columns/tables correctly. This is critical for app updates in production.
- Encryption: verify that the database file is unreadable without the SQLCipher key. Attempt to open the database file with a standard SQLite reader and confirm it fails.
- Bulk operations: insert 100+ receipts in a transaction, verify all are persisted and queryable.
- Edge cases: very long strings (store names, notes), null optional fields, Unicode characters (Greek, emoji, CJK).
- Sync queue table: enqueue items, dequeue in FIFO order, mark as completed, handle failed items with retry count.

**API Client (Remote Data Source, Dio):**
- Mock HTTP responses for every API endpoint using a Dio interceptor or a mock adapter.
- Test successful responses: verify JSON is parsed correctly into model objects.
- Test error responses: HTTP 400 (bad request), 401 (unauthorized), 403 (forbidden), 404 (not found), 409 (conflict), 429 (rate limited), 500 (server error). Verify that each produces the correct exception type.
- Test retry logic: simulate a 503 response followed by a 200 response, verify the retry interceptor retries and succeeds.
- Test auth token injection: verify that the Authorization header is attached to every request with the current access token.
- Test token refresh: simulate a 401 response, verify that the auth interceptor refreshes the token and retries the original request.
- Test timeout handling: simulate a request that exceeds the timeout, verify that a timeout exception is raised.
- Test pre-signed URL upload: mock the URL generation response, then mock the S3 PUT response, verify the full upload flow.

### Model Tests

Every data model class must have serialization and validation tests.

**JSON serialization and deserialization:**
- For each model (Receipt, Category, SyncItem, UserSettings, WarrantyInfo, etc.), create an instance with all fields populated, serialize to JSON, deserialize back, and verify the round-trip produces an identical object.
- Test with minimal fields (only required fields set, all optional fields null).
- Test with all fields set to boundary values (empty strings, zero amounts, maximum-length strings).

**Validation logic:**
- Required fields: verify that creating a model without required fields throws a validation error or produces a well-defined default.
- Format validation: dates must be valid ISO 8601, amounts must be non-negative, currency codes must be recognized.
- Edge cases for specific fields:
  - Store name: empty string, whitespace only, very long name (200+ characters), Unicode characters including Greek (e.g., "AB Bacilopoulos" / "AB Vassilopoulos"), special characters (ampersands, apostrophes).
  - Purchase date: today, far past (1990), far future (accidental), leap day (February 29).
  - Total amount: zero, very small (0.01), very large (999999.99), negative (should be rejected).
  - Warranty months: zero (no warranty), 1, 12, 24, 60, 120 (10 years), negative (should be rejected).
  - User notes: empty, very long (5000+ characters), contains newlines, contains HTML/script tags (must be stored as plain text, never interpreted).

### Utility Tests

**Date formatting and parsing:**
- Parse ISO 8601 strings ("2026-02-08T14:30:00Z") into DateTime objects and verify correctness.
- Format DateTime objects back to ISO 8601 strings and verify round-trip fidelity.
- Handle timezone offsets correctly ("+02:00" for Greece, "Z" for UTC).
- Handle dates without time components ("2026-02-08").
- Handle malformed date strings gracefully (return null or throw a specific error, never crash).

**Currency formatting:**
- Format amounts with Euro sign: 1234.56 displays as "1.234,56 EUR" in Greek locale and "EUR1,234.56" in English locale (or similar locale-appropriate format).
- Format amounts with Dollar sign, Pound sign, and other currency symbols.
- Handle zero amounts, very large amounts, and amounts with no decimal places.
- Handle locale-specific decimal separators (comma vs. period) and thousands separators.

**Image compression utility:**
- Verify that compressing a test image at 85% quality produces a file smaller than the original.
- Verify that the output is a valid JPEG file.
- Verify that the compressed image retains sufficient quality for OCR (visual inspection of test corpus images may be needed for initial calibration, but automated tests can verify file size and format).

**EXIF stripping utility:**
- Start with an image that has GPS EXIF data, run the stripping utility, verify that GPS data is removed.
- Verify that non-GPS EXIF data (orientation, camera model) is preserved.
- Handle images with no EXIF data (should not crash).
- Handle images with corrupted EXIF data (should not crash, should strip what it can).

**OCR text parsing (regex for dates and amounts):**
- Extract dates from OCR text: "08/02/2026", "2026-02-08", "08 Feb 2026", "08 Fevrouariou 2026" (Greek month name).
- Extract amounts from OCR text: "Total: 45.99", "SYNOLO: 45,99 EUR", "TOTAL 45.99 EUR", "$123.45".
- Handle ambiguous date formats: "02/03/2026" could be February 3 or March 2 depending on locale. Verify the parser uses the correct locale assumption.
- Handle OCR errors in amounts: "45,g9" (misread character), "4S.99" (S misread as 5). The parser should either reject these or apply common OCR error corrections.
- Handle multiple amounts in text (identify the largest as the total, or identify the line labeled "total" / "synolo").

---

## Widget Tests (Flutter)

Widget tests verify that UI components render correctly and respond to user interactions. They run in a simulated Flutter environment without a real device or emulator, making them fast and reliable.

### Key Widgets to Test

**ReceiptCard:**
- Renders correctly with all fields populated (thumbnail, store name, date, total, warranty badge).
- Renders correctly with missing optional fields (no thumbnail, no warranty, no total).
- Displays the correct warranty status badge color (green for active, amber for expiring soon, red for expired).
- Responds to tap by navigating to the receipt detail screen (verify callback is called with correct receipt ID).
- Responds to long press by showing the context menu (edit, delete, share, mark as returned).
- Displays the "Returned" indicator when the receipt is marked as returned.
- Displays the soft-deleted state if applicable (grayed out, with "Deleted" indicator and restore option).

**WarrantyBadge:**
- Displays "X days left" for active warranties with the correct count.
- Displays "Expiring Soon" with amber styling when within 30 days of expiry.
- Displays "Expired" with red styling when past the expiry date.
- Displays "No Warranty" or is hidden entirely when no warranty information exists.
- Updates dynamically when warranty data changes (e.g., after sync).

**CategoryChip:**
- Renders the category name with the correct icon and color.
- Responds to tap by applying the category filter.
- Responds to long press for category management (rename, delete) on user-created categories.
- Default categories cannot be deleted (verify the delete option is not shown or is disabled).

**SearchBar:**
- Renders with placeholder text ("Search receipts..." in English, appropriate Greek text in Greek).
- Accepts text input and dispatches search events.
- Displays a clear button when text is entered.
- Debounces input (does not fire a search event on every keystroke).
- Handles Greek text input correctly (keyboard, display, and search execution).

**FilterChips:**
- Renders all available filter options (category, store, date range, warranty status, returned status).
- Shows active filters with a distinct visual style (filled chip vs. outlined chip).
- Responds to tap to toggle filters on and off.
- Supports multiple simultaneous active filters.
- Displays the count of active filters when collapsed.

**WarrantyCountdown:**
- Displays a circular progress indicator showing the percentage of warranty elapsed.
- Displays the exact number of days remaining as a prominent number.
- Changes color from green to amber to red as the warranty approaches expiry.
- Handles edge cases: warranty expiring today (0 days left), warranty expired yesterday (-1 day, displayed as "Expired").

**StatsBar:**
- Displays "X receipts" with the correct count.
- Displays "Y in active warranties" with the correct Euro-formatted total.
- Updates when receipts are added, deleted, or have their warranty status changed.
- Handles zero state: "0 receipts" when the vault is empty.
- Handles large numbers gracefully (formatting, truncation if needed).

### Localization Testing

Every user-facing string in the application must be tested in both English and Greek. Widget tests should verify:

- All static text renders correctly in English when the locale is set to English.
- All static text renders correctly in Greek when the locale is set to Greek.
- Dynamic text (interpolated strings like "X days left" / "X meres apomenoun") renders correctly in both locales with various values (0, 1, many -- important for Greek pluralization rules).
- Date formatting follows locale conventions (day/month/year for Greek, month/day/year for English, or ISO format as configured).
- Currency formatting follows locale conventions (comma vs. period for decimal separator).
- No untranslated strings appear in either locale (use a test that scans all localization keys and verifies both .arb files have entries for every key).
- Right-to-left (RTL) layout is not required for English or Greek, but verify that no layout assumptions break if a future language requires RTL.

### Accessibility Testing

Widget tests should verify accessibility compliance:

- **Screen reader labels:** Every interactive element (button, card, input field, chip) has a Semantics label that accurately describes its function. Test that the semantics tree contains the expected labels.
- **Sufficient contrast:** Text and icons meet WCAG 2.1 AA contrast ratios against their background colors. The warm cream (#FAF7F2) background with forest green (#2D5A3D) text should be verified programmatically.
- **Touch targets:** All tappable elements have a minimum size of 48x48 logical pixels (Material Design accessibility guideline). Test that no button or interactive element is smaller than this minimum.
- **Font scaling:** The UI remains usable and does not overflow or clip when the system font size is set to the largest accessibility setting. Test with MediaQuery.textScaleFactor set to 2.0.
- **Focus order:** For keyboard and switch-access navigation, verify that the focus order follows a logical reading sequence (top to bottom, left to right).

---

## Integration Tests (Flutter)

Integration tests verify complete user flows end-to-end within the Flutter application. They use the flutter integration_test package and run on a real device or emulator. Unlike unit tests, integration tests exercise the full widget tree, BLoC event handling, repository logic, and local database interactions in concert.

### Key Flows to Test

**Flow 1: Sign Up, Onboarding, Bulk Import, Home Screen**
- User opens the app for the first time and sees the sign-up screen.
- User creates an account with email and password (or signs in with Google/Apple -- mocked for integration tests).
- User is presented with the onboarding flow: welcome screen, storage mode choice (cloud+device or device-only), app lock setup (biometric/PIN prompt -- optional), notification preferences.
- User is prompted for bulk import: the app scans the gallery for receipt-like images (mocked with test images in the integration test asset bundle).
- User selects images for import, confirms, and waits for OCR processing.
- User arrives at the home screen and sees the imported receipts in the vault list.
- Verify: receipts appear in the list with extracted store names and dates. Stats bar shows the correct count.

**Flow 2: Capture Receipt, OCR, Edit, Save, Appears in List**
- User taps the "+ Add" button on the bottom navigation bar.
- User captures a receipt image via the camera (mocked in integration tests) or selects from gallery.
- User crops and rotates the image if needed.
- On-device OCR extracts text and populates the store name, date, and total fields.
- User edits the extracted fields (corrects a misspelled store name, adjusts the date).
- User selects a category and optionally adds warranty information (duration in months).
- User taps "Save."
- The receipt appears in the vault list on the home screen with the corrected values.
- Verify: tapping the receipt opens the detail screen with all saved fields.

**Flow 3: Search, Filter, Open Detail, Edit, Save**
- User navigates to the Search tab.
- User types a search term (e.g., a store name) into the search bar.
- Results appear from FTS5 search.
- User applies a filter (e.g., category = "Electronics").
- Results narrow to match both the search term and the filter.
- User taps a result to open the receipt detail screen.
- User edits a field (e.g., adds a note).
- User saves the edit.
- Verify: returning to the search results, the edited receipt reflects the updated note.

**Flow 4: Offline Capture, Go Online, Sync, Verify Cloud Update**
- Device starts in airplane mode (simulated by disabling the mock network layer).
- User captures a receipt and saves it. The receipt is stored locally.
- User verifies the receipt appears in the vault list (offline, from local database).
- Network is re-enabled (simulated by enabling the mock network layer).
- Sync triggers automatically (or user pulls to refresh).
- Verify: the sync completes without errors. The receipt is now marked as synced. A mock verification confirms the receipt data was sent to the (mocked) API.

**Flow 5: Delete Receipt, Verify Soft Delete, Restore, Verify Restored**
- User opens a receipt detail screen.
- User taps "Delete" and confirms the deletion.
- The receipt disappears from the main vault list.
- User navigates to the "Recently Deleted" section (in Settings or via a filter).
- The deleted receipt appears in the recently deleted list with a "30 days remaining" indicator.
- User taps "Restore."
- The receipt reappears in the main vault list with all original data intact.
- Verify: all fields, including images, are fully restored.

**Flow 6: Change Storage Mode, Verify Behavior Change**
- User is currently in "Cloud + Device" mode.
- User navigates to Settings and changes storage mode to "Device Only."
- A confirmation dialog explains the implications (cloud sync will stop, data will remain on device, cloud copy will be retained but not updated).
- User confirms.
- Verify: sync operations no longer trigger. New receipts are saved locally only. The sync status indicator disappears from the UI.
- User switches back to "Cloud + Device" mode.
- Verify: a full sync is triggered to reconcile any changes made while in device-only mode.

**Flow 7: Mark as Returned, Verify Status Update**
- User opens a receipt detail screen.
- User taps "Mark as Returned."
- The receipt status changes to "Returned" with a visual indicator (badge, color change).
- The receipt remains in the vault list but is visually distinguished from active receipts.
- User filters by "Returned" status and sees only returned receipts.
- Verify: the returned status persists after closing and reopening the app.

**Flow 8: Export Receipt(s), Verify File Generated**
- User opens a receipt detail screen and taps "Share/Export."
- The app generates an export file (PDF or image with metadata).
- Verify: the export file is created in the expected location and contains the receipt image and metadata.
- User navigates to Settings and initiates a batch export by date range.
- User selects a date range that covers multiple receipts.
- The app generates a ZIP file containing all matching receipts.
- Verify: the ZIP file is created, contains the correct number of receipt files, and each file has the expected content.

---

## Backend Tests (Python / pytest)

### Lambda Unit Tests

All Lambda functions are tested using pytest with mocked AWS services. The **moto** library provides in-memory mock implementations of DynamoDB, S3, Cognito, SNS, and SQS, allowing Lambda handlers to be tested without any AWS infrastructure.

**receipt-crud Lambda:**
- **Create:** Test that a valid receipt payload creates a DynamoDB item with correct PK, SK, all attributes, and all GSI keys. Test that the createdAt and updatedAt timestamps are set to the current server time. Test that the receiptId is validated (must be a valid UUID). Test that the userId is extracted from the Cognito token context, not from the request body.
- **Read:** Test that reading a receipt by ID returns the correct item. Test that reading a receipt belonging to a different user returns HTTP 404 (not 403, to avoid leaking information about other users' receipts). Test that reading a non-existent receipt returns HTTP 404.
- **Update:** Test that updating a receipt modifies only the specified fields and increments the version number. Test that updatedAt is set to the current server time. Test that conditional updates (version check) prevent stale writes. Test that a stale version produces HTTP 409 (Conflict).
- **Delete:** Test that deleting a receipt sets the deletedAt timestamp and status to "DELETED" (soft delete). Test that the TTL attribute is set to 30 days from now. Test that deleting a receipt belonging to a different user returns HTTP 404.
- **Validation:** Test that missing required fields return HTTP 400 with a descriptive error message. Test that malformed dates, negative amounts, and oversized payloads are rejected. Test that all input fields are sanitized (no HTML, no script injection).
- **Authorization:** Test that every endpoint rejects requests without a Cognito token (HTTP 401). Test that the userId from the token context is used for all DynamoDB operations (never the request body).

**ocr-refine Lambda:**
- Test that the function sends the correct prompt to Bedrock with the OCR text and image reference.
- Test that the Bedrock response is parsed correctly into structured fields (store name, date, total, currency, items, warranty info, confidence score).
- Test the fallback logic: when Haiku returns a confidence score below 60, the function retries with Sonnet.
- Test that if both Haiku and Sonnet return low confidence, the receipt is marked as "needs manual review."
- Test that the refined fields are written back to DynamoDB with the correct conflict resolution metadata (server-owned fields updated, user-edited fields preserved).
- Test error handling: Bedrock timeout, Bedrock throttling, Bedrock model not available, malformed Bedrock response.
- Test that the function handles receipts with no image (OCR text only) and receipts with image but no OCR text (image-only refinement).

**sync-handler Lambda:**
- **Delta sync:** Test that the function returns all items updated after the client's lastSyncTimestamp, queried via GSI-6 (ByUpdatedAt). Test that the response includes created, updated, and deleted items. Test pagination for large result sets.
- **Full reconciliation:** Test that the function accepts a list of all local item IDs and versions, compares with server state, and returns: items the client is missing, items the client has that the server does not (for upload), and items with version mismatches (for conflict resolution).
- **Conflict resolution (all tiers):** Repeat the conflict resolution tests described in the Flutter repository tests section, but from the server's perspective. The server must apply the same three-tier rules when merging client-submitted changes with existing server state.
- **Edge cases:** Client sends changes for a receipt that has been hard-deleted on the server (past 30-day TTL). Client sends a lastSyncTimestamp of zero (first sync ever -- equivalent to full sync). Client sends an extremely large batch of changes (test batch size limits and pagination).

**thumbnail-generator Lambda:**
- Test that a valid JPEG image uploaded to the `originals/` prefix triggers thumbnail generation.
- Test that the generated thumbnail is 200x300 pixels, JPEG format, 70% quality.
- Test that the thumbnail is written to the `thumbnails/` prefix with the correct key structure.
- Test error handling for corrupt images: truncated JPEG, zero-byte file, non-image file with .jpg extension.
- Test error handling for unsupported formats (the system expects JPEG, but test PNG and HEIC gracefully).
- Test that very large images (20+ MB) are processed without timeout (within the 15-second Lambda timeout).

**warranty-checker Lambda:**
- Test that the function queries GSI-4 (ByWarrantyExpiry) for warranties expiring within 30 days.
- Test that it sends SNS notifications for warranties expiring at each configured interval (30 days, 7 days, 1 day, today).
- Test that it does not send duplicate notifications (tracks last notification sent per receipt).
- Test edge cases: warranty expiring today (should trigger "today" notification), warranty already expired (should not trigger a reminder, or should trigger a "your warranty has expired" notification depending on business logic), receipt with no warranty information (should be ignored).
- Test that it handles users with no device token registered (skip notification, do not crash).
- Test that it processes multiple users correctly (not just the first user).

**user-deletion Lambda:**
- Test the complete cascade: Cognito user deletion, DynamoDB item deletion (all items with the user's PK), S3 object deletion (all objects under the user's prefix, including all versions).
- Test the correct deletion order: DynamoDB and S3 first, Cognito last (so that if the process fails partway, the user can still authenticate to retry).
- Test that batch operations handle large numbers of items (a user with 500+ receipts and 500+ images).
- Test error handling: partial failure (S3 deletion succeeds but DynamoDB deletion fails -- verify the function retries or reports the partial failure).
- Test that the function completes within its 300-second timeout for a worst-case user (many items, many images).

**export-handler Lambda:**
- Test that the function queries all receipts for the authenticated user.
- Test that batch export by date range returns only receipts within the specified range.
- Test that the export includes both metadata (JSON or CSV) and image files.
- Test that the export is packaged as a ZIP file and a pre-signed download URL is returned.
- Test that the ZIP file structure is correct and all files are readable.
- Test that the function handles users with zero receipts (returns an empty export or a descriptive message).
- Test that the function completes within its 300-second timeout for a user with 500+ receipts.

### API Integration Tests

These tests run against a real staging environment with actual AWS services. They are not part of the developer's inner loop but are executed as part of the CI/CD pipeline before any production deployment.

**Endpoint validation:**
- Test every API endpoint (receipts CRUD, sync, refine, upload-url, categories, export, delete) with valid Cognito tokens obtained from the staging Cognito User Pool.
- Verify correct HTTP status codes, response schemas, and response times.

**Rate limiting:**
- Send 200+ requests per second to a single endpoint and verify that requests beyond the configured rate limit (100/s) receive HTTP 429 responses with a Retry-After header.

**CORS:**
- Verify that CORS headers are correctly configured (though the primary client is a mobile app, not a browser, CORS may matter for future web clients). Test that OPTIONS preflight requests return the correct Access-Control-Allow headers.

**Error responses:**
- Verify that all error responses follow a consistent JSON schema with error code, message, and request ID.
- Verify that no error response leaks internal implementation details (stack traces, AWS resource ARNs, internal IP addresses).
- Verify that error messages are generic enough to not aid an attacker (e.g., "Receipt not found" rather than "DynamoDB item with PK USER#abc and SK RECEIPT#xyz not found").

---

## OCR Accuracy Testing

### Test Corpus

A dedicated test corpus of annotated receipt images is the foundation of OCR accuracy testing. This corpus must be built before OCR accuracy can be meaningfully measured or improved.

**Corpus size target:** 50+ receipt images, growing over time as testers contribute real-world receipts.

**Greek receipts (minimum 25 images):**
- **Supermarkets:** Sklavenitis (Sklavenitees), AB Vassilopoulos (AB Bacilopoulos). These represent the most common Greek receipt format: thermal paper, Greek text, Euro amounts, Greek date format.
- **Electronics:** Kotsovolos (Kotsovoles), Public. These receipts often include warranty information, model numbers, and serial numbers.
- **General retail:** Jumbo, IKEA Greece, Leroy Merlin Greece, Praktiker. Mix of Greek and English text on the same receipt.
- **Small local businesses:** Bakeries, pharmacies, dry cleaners. Handwritten or poorly printed receipts that test OCR resilience.

**International receipts (minimum 15 images):**
- **IKEA** (English/multilingual receipt format).
- **Amazon** (digital receipt screenshots and printed invoices).
- **Samsung** (warranty card and receipt combined).
- **Apple** (digital receipt from email).
- **Generic UK/US retail** (Tesco, Walmart, Target, Best Buy).

**Quality variations (distributed across the corpus):**
- **Clear photos:** Well-lit, sharp focus, receipt laid flat on a contrasting surface. These represent the best-case scenario for OCR accuracy.
- **Blurry photos:** Slightly out of focus, simulating quick capture without stabilization.
- **Skewed photos:** Receipt photographed at an angle, not perfectly aligned.
- **Folded receipts:** Receipt creased or folded, with text partially obscured along the fold line.
- **Faded receipts:** Thermal paper that has partially faded over time, with reduced contrast.

**Format variations (distributed across the corpus):**
- **Thermal paper:** The most common physical receipt format. Narrow, long, variable print quality.
- **A4 printed invoices:** Larger format, typically higher quality, more structured layout.
- **Digital screenshots:** Screenshots of email receipts, online order confirmations, or in-app purchase records. These are high quality but have different visual layouts than physical receipts.

### Annotation

Each image in the test corpus must be annotated with the ground-truth values for:
- **Store name** (exactly as it should be extracted).
- **Purchase date** (in ISO 8601 format).
- **Total amount** (numeric value with currency).
- **Additional fields** (if visible): individual line items, warranty information, receipt number, tax amount.

Annotations are stored in a companion JSON file alongside each image, enabling automated accuracy measurement.

### Metrics to Track

**Field extraction accuracy (per image):**
- For each annotated field (store name, date, total), compare the OCR-extracted value to the ground truth.
- A field is "correct" if the extracted value matches the ground truth exactly (for dates and amounts) or with a normalized string comparison (for store names -- case-insensitive, whitespace-normalized).
- Report per-field accuracy as a percentage across the corpus.

**On-device accuracy vs. cloud accuracy:**
- Run each corpus image through the on-device pipeline only (ML Kit + Tesseract) and measure accuracy.
- Run each corpus image through the cloud pipeline (Bedrock Haiku 4.5) and measure accuracy.
- Compare the two, reporting the accuracy lift provided by cloud refinement.

**Greek text accuracy:**
- Report accuracy separately for Greek-language receipts vs. English-language receipts.
- Identify specific Greek characters or words that are consistently misread (e.g., similar-looking Latin and Greek characters like "P" vs. "Rho", "H" vs. "Eta").

**Processing time:**
- Measure end-to-end time for on-device OCR (from image input to structured text output).
- Measure end-to-end time for cloud refinement (from API call to response received).
- Report P50, P90, and P99 for both pathways.

### Acceptance Criteria

| Metric | Target | Notes |
|--------|--------|-------|
| On-device accuracy (clear receipts) | Greater than 85% | Across store name, date, and total fields |
| Cloud accuracy (clear receipts) | Greater than 95% | Across store name, date, and total fields |
| On-device accuracy (all receipts) | Greater than 70% | Including blurry, skewed, faded images |
| Cloud accuracy (all receipts) | Greater than 85% | Including blurry, skewed, faded images |
| Greek text accuracy (on-device) | Greater than 80% | Tesseract with Greek training data |
| Greek text accuracy (cloud) | Greater than 90% | Bedrock Haiku 4.5 with Greek text |
| On-device processing time | Under 5 seconds | P90, on a mid-range device |
| Cloud processing time | Under 10 seconds | P90, including network round-trip |

These thresholds are initial targets. They will be adjusted based on testing results during the development phase. If on-device Greek accuracy falls below 70%, Tesseract training data optimization will be prioritized.

---

## Sync Engine Testing

The sync engine is the **most critical test area** in the entire project. A bug in the sync engine can cause data loss, data duplication, or data corruption -- all of which are catastrophic for a personal receipt vault. The sync engine must be tested more thoroughly than any other component.

### Test Scenarios

**Scenario 1: Normal sync (online create and verify)**
- User creates a receipt while online.
- Sync triggers immediately (or on next sync cycle).
- Verify that the receipt exists in both the local database and the cloud (DynamoDB).
- Verify that all fields match exactly between local and cloud copies.
- Verify that the sync status is marked as "synced."

**Scenario 2: Offline create, then sync**
- Device is offline. User creates a receipt.
- Receipt is saved locally with a sync status of "pending."
- Device comes online. Sync triggers.
- Verify that the receipt is uploaded to the cloud.
- Verify that the sync status changes to "synced."
- Verify that the server-assigned timestamps are written back to the local copy.

**Scenario 3: Offline edit, then sync (no server changes)**
- User edits a receipt while offline (e.g., changes the store name).
- Device comes online. Sync triggers.
- The server has not been modified since the last sync.
- Verify that the client's edit is applied to the server.
- Verify that the version number is incremented.
- Verify that the local and cloud copies match after sync.

**Scenario 4: Offline edit, sync with server LLM update (Tier 1: server wins)**
- User captures a receipt and saves it. Sync uploads to cloud.
- While the user is offline, the Bedrock LLM refinement pipeline processes the receipt on the server side and updates extracted_merchant_name, extracted_date, and extracted_total (all Tier 1 fields).
- User comes back online and syncs.
- Verify that the Tier 1 fields in the local copy are overwritten with the server's LLM-refined values.
- Verify that any Tier 2 or Tier 3 fields the user edited offline are preserved (not overwritten).

**Scenario 5: Offline edit of userNotes, sync with server LLM update (Tier 2: client wins for notes)**
- User edits userNotes while offline.
- Server has updated Tier 1 fields via LLM refinement.
- User syncs.
- Verify that userNotes retains the client's version (Tier 2: client wins).
- Verify that Tier 1 fields are updated to the server's version.
- Verify that the merged record is consistent and no fields are lost.

**Scenario 6: Offline edit of storeName (Tier 3), sync with server LLM update**
- User manually edits the display store name (storeName / display_name) while offline.
- This edit causes "display_name" to be added to the userEditedFields array.
- Server has updated extracted_merchant_name (Tier 1) via LLM refinement.
- User syncs.
- Verify that display_name retains the client's version because it is in userEditedFields (Tier 3: client wins when user has edited).
- Verify that extracted_merchant_name is updated to the server's version (Tier 1: server always wins for extracted fields).

**Scenario 7: Offline edit on two devices, both sync**
- User has the app on two devices (e.g., phone and tablet).
- Device A goes offline and edits the store name.
- Device B goes offline and edits the user notes.
- Device A comes online and syncs first.
- Device B comes online and syncs second.
- Verify that the final state on both devices and the server contains Device A's store name edit and Device B's notes edit (no data is lost from either device).
- Verify that the version number reflects both edits.

**Scenario 8: Large offline queue (100+ items)**
- User goes offline and creates 100+ receipts (or edits 100+ existing receipts).
- Device comes online. Sync triggers.
- Verify that the sync processes all items in batches (not all at once, to avoid timeout).
- Verify that all 100+ items are eventually synced.
- Verify that the sync progress is reported accurately (e.g., "Syncing 23/107...").
- Verify that the sync does not consume excessive memory or battery.

**Scenario 9: Sync failure mid-batch**
- User has 50 items in the sync queue.
- Sync starts and processes the first 20 items successfully.
- A network error occurs, interrupting the sync.
- Verify that the 20 successfully synced items are marked as "synced" and are not re-sent on the next sync.
- Verify that the remaining 30 items are still in the queue and will be processed on the next sync attempt.
- Verify that the partial sync did not corrupt any data (no half-written records, no duplicate records).

**Scenario 10: Full reconciliation**
- After a period of normal delta sync, trigger a full reconciliation (scheduled every 7 days).
- Intentionally introduce a discrepancy (e.g., manually delete a local record that exists on the server, or modify a server record directly in DynamoDB).
- Run the full reconciliation.
- Verify that the discrepancy is detected and resolved (the missing local record is re-downloaded, the modified server record is reconciled according to conflict rules).
- Verify that all items match between local and cloud after reconciliation.

**Scenario 11: Clock skew simulation**
- Set the device clock 5 minutes ahead of actual time.
- Create a receipt. The local createdAt timestamp will be 5 minutes ahead.
- Sync the receipt to the server. The server sets its own createdAt/updatedAt using server time.
- Verify that the sync engine uses the server's timestamps (not the client's) as the authoritative time for all sync decisions.
- Verify that subsequent delta syncs use the server-issued timestamp as the lastSyncTimestamp, not the client's wall clock.

**Scenario 12: Image upload failure, retry, success**
- User captures a receipt with an image while online.
- The image upload to S3 fails (simulated network error or pre-signed URL expiry).
- Verify that the receipt metadata is synced successfully (text data is not blocked by image failure).
- Verify that the image is queued for retry.
- The retry succeeds on the next sync cycle.
- Verify that the receipt's imageKeys are updated to reflect the successful upload.
- Verify that the thumbnail is generated (server-side Lambda trigger) and available via CloudFront.

---

## Security Testing

### Authentication

- Verify that every API endpoint (except the health check) rejects requests without a Cognito access token. Expected response: HTTP 401 Unauthorized.
- Verify that every API endpoint rejects requests with an expired Cognito access token. Expected response: HTTP 401 Unauthorized.
- Verify that every API endpoint rejects requests with a malformed or tampered Cognito access token. Expected response: HTTP 401 Unauthorized.
- Verify that the userId used for all data access is extracted from the validated token claims, never from the request body or URL path.

### Authorization

- Verify that User A cannot read User B's receipts. Create a receipt as User A, attempt to read it using User B's token. Expected response: HTTP 404 (not 403, to prevent information leakage).
- Verify that User A cannot update or delete User B's receipts. Attempt update and delete operations on User B's receipt using User A's token. Expected response: HTTP 404.
- Verify that User A cannot list User B's receipts. The list endpoint should only return receipts where PK matches the authenticated user's ID.
- Verify that User A cannot access User B's images via pre-signed URLs. Pre-signed URLs should be scoped to the authenticated user's S3 prefix.

### Input Validation

- **Cross-site scripting (XSS):** Submit receipt fields containing HTML and JavaScript (e.g., `<script>alert('xss')</script>` in the store name). Verify that the input is stored as plain text and never interpreted as HTML by any consumer of the data.
- **Injection attacks:** Although DynamoDB is not susceptible to SQL injection, test that API inputs with special characters (single quotes, double quotes, backslashes, null bytes) do not cause errors or unexpected behavior in DynamoDB queries.
- **Oversized payloads:** Send requests with payloads exceeding the 10 MB API Gateway limit. Verify that the request is rejected with HTTP 413 (Payload Too Large) and does not crash the Lambda function.
- **Malformed JSON:** Send requests with syntactically invalid JSON. Verify that the API returns HTTP 400 (Bad Request) with a descriptive error message.
- **Excessive field lengths:** Submit a store name of 10,000 characters, a note of 100,000 characters. Verify that the API enforces reasonable length limits and rejects oversized fields.

### Pre-Signed URL Security

- Verify that pre-signed URLs expire after 10 minutes. Generate a URL, wait 11 minutes, attempt to use it. Expected: HTTP 403 Forbidden from S3.
- Verify that pre-signed URLs enforce the content-type constraint. Attempt to upload a file with a content-type other than image/jpeg using the pre-signed URL. Expected: upload rejected by S3.
- Verify that pre-signed URLs are scoped to the correct S3 key (user's prefix). A pre-signed URL generated for User A cannot be used to upload to User B's prefix.

### App Lock

- Verify that when app lock is enabled, the app requires biometric or PIN authentication before displaying any receipt data.
- Verify that app lock works offline (does not require network to authenticate).
- Verify that after multiple failed biometric/PIN attempts, the app enforces a cooldown period.
- Verify that app lock state persists across app restarts.

### SQLCipher Encryption

- Verify that the Drift database file on disk is encrypted and cannot be read by a standard SQLite reader (e.g., DB Browser for SQLite) without the encryption key.
- Verify that the encryption key is stored in flutter_secure_storage (Keychain on iOS, EncryptedSharedPreferences on Android) and is not accessible to other applications.
- Verify that changing or deleting the encryption key makes the database inaccessible (crypto-shredding).

---

## Performance Testing

### App Startup Time

| Metric | Target | Measurement |
|--------|--------|-------------|
| Cold start (first launch after install) | Under 3 seconds | From app icon tap to interactive home screen with receipt list visible |
| Warm start (app in background, resume) | Under 1 second | From app switch to interactive home screen |
| Start with app lock | Under 4 seconds | Cold start including biometric/PIN prompt |

Measure on both a low-end Android device and a current-generation iPhone to establish the performance range.

### Receipt Capture Performance

| Metric | Target | Measurement |
|--------|--------|-------------|
| Camera to OCR result | Under 5 seconds | From image captured to extracted fields displayed (on-device OCR only) |
| Full capture flow | Under 20 seconds | From tapping "+ Add" to receipt saved with extracted data |
| Image compression | Under 2 seconds | Time to compress a 5 MB camera image to 1-2 MB JPEG 85% |
| EXIF stripping | Under 500 milliseconds | Time to read and remove GPS EXIF metadata |

### List Scrolling Performance

- Load the vault with 500+ receipts (use test data generation to create realistic receipt records with thumbnails).
- Scroll through the entire list rapidly.
- Measure frame rate: target is 60 frames per second (16.67 ms per frame) with no dropped frames.
- Monitor memory usage during scrolling: should remain stable (no unbounded growth from image loading).
- Test with both thumbnail images loaded and placeholder images (for receipts not yet downloaded).

### Search Performance

| Metric | Target | Measurement |
|--------|--------|-------------|
| FTS5 keyword search | Under 500 milliseconds | Time from query submission to results displayed, with 1000+ receipts in the database |
| Filter application | Under 200 milliseconds | Time from filter tap to filtered results displayed |
| Combined search + filter | Under 700 milliseconds | Time from search submission with active filters to results displayed |

### Sync Performance

| Metric | Target | Measurement |
|--------|--------|-------------|
| Delta sync (100 items changed) | Under 10 seconds | Total time for metadata sync (excludes image uploads) |
| Full reconciliation (1000 items) | Under 30 seconds | Total time for full compare and resolve |
| Image upload (single, 2 MB) | Under 5 seconds | Over Wi-Fi, including pre-signed URL generation |
| Image upload (single, 2 MB) | Under 15 seconds | Over cellular (4G), including pre-signed URL generation |
| Batch image upload (10 images) | Under 30 seconds | Over Wi-Fi, sequential uploads |

### Memory Usage

- Monitor peak memory usage during bulk import of 100+ images from gallery.
- Target: peak memory should not exceed 300 MB on a device with 4 GB RAM.
- Verify that memory returns to baseline after the bulk import completes (no memory leaks from image processing).
- Monitor memory during extended use (30+ minutes of browsing, searching, and editing). Verify no gradual memory growth that would indicate a leak.

---

## Device Testing

### Android Device Matrix

| Category | Example Devices | Purpose |
|----------|----------------|---------|
| Low-end | Samsung Galaxy A14, Xiaomi Redmi 10 | Test performance floors: slow CPU, limited RAM (3-4 GB), lower-resolution camera |
| Mid-range | Samsung Galaxy A54, Google Pixel 7a | Test the most common user experience: adequate performance, good camera, typical RAM (6-8 GB) |
| Flagship | Samsung Galaxy S24, Google Pixel 8 Pro | Test best-case performance and verify no issues with high-resolution cameras, high refresh rate displays |

Minimum 3 Android devices spanning these categories. Test on the oldest supported Android version (to be determined during implementation, targeting 95% device coverage).

### iOS Device Matrix

| Category | Example Devices | Purpose |
|----------|----------------|---------|
| Older iPhone | iPhone 12, iPhone SE (3rd gen) | Test performance with older hardware and smaller screens |
| Current iPhone | iPhone 15, iPhone 15 Pro | Test best-case experience, Face ID, latest iOS features |

Minimum 2 iOS devices. Test on the oldest supported iOS version (to be determined during implementation, targeting 95% device coverage).

### Orientation Testing

- Test all screens in **portrait** orientation (the primary and preferred orientation).
- Test all screens in **landscape** orientation to verify no layout breakage, even if the app is designed portrait-first. Users may accidentally rotate their device; the app should handle it gracefully (either by rotating the layout or by locking to portrait with a smooth experience).
- Specifically test the camera capture flow in landscape, as users may hold their phone horizontally to photograph a wide receipt.

### Accessibility Font Size Testing

- Set the device system font size to the **largest** available setting.
- Navigate through every screen in the app.
- Verify that no text is clipped, truncated, or overflows its container.
- Verify that all interactive elements remain tappable (touch targets do not shrink or overlap).
- Verify that the layout remains usable (scrollable if needed, no overlapping elements).

### Network Condition Testing

- **No network:** Airplane mode. Verify all offline-first features work correctly.
- **Slow network:** Use Android's network throttling (Developer Options) or iOS Network Link Conditioner to simulate 2G/3G speeds (100-500 Kbps). Verify that the app remains responsive, shows loading indicators, and does not time out prematurely.
- **Unreliable network:** Use network throttling tools to simulate packet loss (10-30%). Verify that retry logic handles dropped requests gracefully, sync completes eventually, and no data is corrupted.
- **Network transition:** Start on Wi-Fi, switch to cellular mid-operation (e.g., during a sync or image upload). Verify that the operation completes or fails gracefully and is retried.

---

## Test Data Management

### Seed Data Scripts

Automated scripts generate realistic test data for development and testing environments.

**Local seed data (Flutter):**
- A Dart script or test fixture that populates the local Drift database with a configurable number of receipts (default: 50).
- Each receipt has realistic values: randomly selected store names from a predefined list (including Greek stores), randomized dates within the past year, randomized amounts (ranging from small grocery purchases to large electronics), randomly assigned categories, and a subset with warranty information (varying durations from 6 months to 5 years).
- A subset of receipts have different sync statuses: synced, pending, conflicted.
- A subset of receipts are soft-deleted (within the 30-day recovery window).
- A subset of receipts are marked as returned.
- The script is idempotent: running it multiple times does not create duplicate data.

**Server seed data (Python):**
- A pytest fixture or standalone script that populates the staging DynamoDB table and S3 bucket with test data matching the local seed data.
- Ensures that sync testing has a known starting state on both client and server.

### Sample Receipts for OCR Testing

The test corpus (described in the OCR Accuracy Testing section) serves as the ground truth for OCR accuracy measurement. In addition:

- A **small, fast-running subset** of 5-10 receipts is designated for CI/CD pipeline OCR smoke tests. These are high-quality images with known correct values, designed to catch OCR regressions quickly without running the full 50+ image corpus.
- Each sample receipt has an accompanying JSON annotation file with the expected extraction results.
- The sample receipt images are stored in the repository under `test/fixtures/receipts/` (or a similar path), version-controlled alongside the code.

### Factory Methods for Test Receipts

Dart factory methods and Python factory functions generate test receipt objects with various states, eliminating the need to manually construct complex objects in every test.

**Dart factory examples:**
- `ReceiptFactory.create()` -- returns a receipt with all required fields populated with realistic default values.
- `ReceiptFactory.withWarranty(months: 24)` -- returns a receipt with a 24-month warranty starting from today.
- `ReceiptFactory.expiringSoon(daysLeft: 7)` -- returns a receipt with a warranty expiring in 7 days.
- `ReceiptFactory.expired()` -- returns a receipt with a warranty that expired yesterday.
- `ReceiptFactory.softDeleted()` -- returns a receipt in soft-deleted state with a deletedAt timestamp.
- `ReceiptFactory.returned()` -- returns a receipt marked as returned.
- `ReceiptFactory.pendingSync()` -- returns a receipt with sync status "pending."
- `ReceiptFactory.withConflict()` -- returns a receipt with a sync conflict (local and server versions differ).
- `ReceiptFactory.greekReceipt()` -- returns a receipt with Greek store name, Greek OCR text, and Euro amounts.
- `ReceiptFactory.batch(count: 100)` -- returns a list of 100 receipts with varied attributes for bulk testing.

**Python factory examples:**
- `create_test_receipt()` -- returns a DynamoDB item dict with all required attributes.
- `create_test_receipt(warranty_months=24)` -- includes warranty attributes.
- `create_test_receipt(status="DELETED", deleted_at=...)` -- soft-deleted receipt.
- `create_test_user()` -- returns a Cognito user dict for moto-mocked Cognito operations.

These factories are maintained alongside the test code and updated whenever the data model changes, ensuring that tests always use the current schema.

---

*This document defines the testing strategy for Receipt & Warranty Vault. For technical architecture details, see [05 - Technical Architecture](./05-technical-architecture.md). For sync engine design, see [10 - Offline & Sync Architecture](./10-offline-sync-architecture.md). For API endpoint specifications that inform integration tests, see [07 - API Design](./07-api-design.md).*
