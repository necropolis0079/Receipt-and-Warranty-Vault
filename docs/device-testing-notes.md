# Device Testing Notes — Warranty Vault

> **Issues found during real device testing (Samsung Galaxy, 2026-02-12)**

---

## Critical Issues — ALL FIXED

### 1. ~~No category selection when adding/importing a receipt~~ FIXED
- **Fix**: Added `CategoryPickerField` widget to the Add Receipt form. Loads categories from database.

### 2. ~~OCR store name extraction is mostly wrong~~ IMPROVED
- **Fix**: Rewrote store name heuristic — now skips dates, amounts, phone numbers, separators. Takes first text-like line from top of receipt.

### 3. ~~Total amount is empty after OCR~~ IMPROVED
- **Fix**: Rewrote total amount extraction with 3-pass strategy: keyword search, currency-symbol search, bare amount fallback.

### 4. ~~Edit button not implemented~~ FIXED
- **Fix**: Created `EditReceiptScreen` with all editable fields pre-populated. Saves via `VaultReceiptUpdated` event.

---

## Working Features (confirmed on device)
- Date extraction: OK
- App launches and navigates correctly
- Camera capture works
- Gallery import works

---

## Fixed During Testing

### Category picker added (2026-02-12)
- **Fix**: Added category dropdown to Add Receipt form between currency and warranty fields

### Edit receipt implemented (2026-02-12)
- **Fix**: New `edit_receipt_screen.dart` — pre-populates all fields, saves updates via VaultBloc

### OCR improvements (2026-02-12)
- **Fix**: Rewrote store name + total amount extraction in `hybrid_ocr_service.dart`

### Add Category button (2026-02-12)
- **Fix**: Added FAB to category management screen with dialog for creating custom categories

### SQLCipher crash on startup (2026-02-12)
- **Issue**: App stuck on logo screen — `NativeDatabase.createInBackground` spawned a new isolate where the SQLCipher library override wasn't applied
- **Fix**: Changed to `NativeDatabase` (same isolate) in `database_provider.dart`

### R8 missing ML Kit classes (2026-02-12)
- **Issue**: Release build failed — R8 shrinker couldn't find optional ML Kit language modules (Chinese, Japanese, Korean, Devanagari)
- **Fix**: Added `proguard-rules.pro` with `-dontwarn` rules

---

*Last updated: 2026-02-12*
