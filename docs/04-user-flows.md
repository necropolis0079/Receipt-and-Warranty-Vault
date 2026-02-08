# User Flows — Receipt & Warranty Vault v1.0

**Document Version**: 1.0
**Last Updated**: 2026-02-08
**Status**: Pre-Implementation (Documentation Phase)

---

## Table of Contents

1. [Introduction](#introduction)
2. [Flow Conventions](#flow-conventions)
3. [User Flows](#user-flows)
   - [UF-01: First-Time Onboarding](#uf-01-first-time-onboarding)
   - [UF-02: Quick Receipt Capture](#uf-02-quick-receipt-capture)
   - [UF-03: Fast Save Flow](#uf-03-fast-save-flow)
   - [UF-04: Import from Gallery](#uf-04-import-from-gallery)
   - [UF-05: Receipt Detail View](#uf-05-receipt-detail-view)
   - [UF-06: Edit Receipt](#uf-06-edit-receipt)
   - [UF-07: Search and Filter](#uf-07-search-and-filter)
   - [UF-08: Warranty Expiry Reminder Flow](#uf-08-warranty-expiry-reminder-flow)
   - [UF-09: Offline Capture and Sync](#uf-09-offline-capture-and-sync)
   - [UF-10: Mark as Returned](#uf-10-mark-as-returned)
   - [UF-11: Delete Receipt](#uf-11-delete-receipt)
   - [UF-12: Export Flow](#uf-12-export-flow)
   - [UF-13: Settings — Change Storage Mode](#uf-13-settings--change-storage-mode)
   - [UF-14: Settings — Manage Categories](#uf-14-settings--manage-categories)
   - [UF-15: Account Deletion](#uf-15-account-deletion)

---

## Introduction

This document describes every critical user flow in Receipt & Warranty Vault v1.0. Each flow is documented as a step-by-step sequence of user actions, system responses, screen transitions, and decision points. Error states and edge cases are included inline at the points where they occur.

These flows reference features from the Feature Specification (03-feature-specification.md) using their feature IDs (F-001 through F-020).

---

## Flow Conventions

The following conventions are used throughout this document:

- **Screen**: A named screen or view in the app. Screens are written in bold (e.g., **Home Screen**).
- **User Action**: Something the user does, written as an imperative (e.g., "User taps the + button").
- **System Response**: Something the app does in response, written in passive or descriptive form (e.g., "The app opens the camera viewfinder").
- **Decision Point**: A branch in the flow where the path depends on a condition, indicated with "IF... THEN... ELSE..."
- **Error State**: A scenario where something goes wrong, indicated with "ERROR:" prefix.
- **Navigation**: The app uses a bottom tab bar with five tabs: Vault (home), Expiring, +Add (center action), Search, and Settings.

---

## User Flows

---

### UF-01: First-Time Onboarding

**Related Features**: F-010, F-011, F-009, F-016, F-019

**Trigger**: User installs the app and opens it for the first time.

**Preconditions**: The app has just been installed. No user account exists on this device. The device has an internet connection (required for account creation).

---

**Step 1: App Launch and Language Detection**

The app launches and displays the splash screen (warm cream background with the Receipt & Warranty Vault logo in forest green). The system detects the device's language setting.

- IF the device language is Greek: The app sets the display language to Greek.
- IF the device language is English or any other language: The app sets the display language to English.

The splash screen transitions to the **Welcome Screen** after 2 seconds or when initialization completes, whichever is longer.

---

**Step 2: Welcome Screen**

The **Welcome Screen** displays three swipeable onboarding cards that introduce the app's core value:

- Card 1: "Capture Any Receipt" — illustration of a phone camera capturing a receipt, with a brief description of photo capture and OCR.
- Card 2: "Never Miss a Warranty" — illustration of a warranty countdown with an expiring-soon badge, describing the warranty tracking feature.
- Card 3: "Your Data, Your Choice" — illustration of a device and cloud, describing the storage mode options.

Each card has a dot indicator showing progress. The user can swipe through the cards or tap "Skip" to proceed directly. After the last card or after tapping "Skip," the user is taken to the **Sign Up / Sign In Screen**.

---

**Step 3: Sign Up / Sign In Screen**

The **Sign Up / Sign In Screen** presents three authentication options:

1. "Continue with Google" button (Google-branded, prominent).
2. "Continue with Apple" button (Apple-branded, prominent; displayed on iOS only).
3. "Sign up with Email" button (secondary style).
4. At the bottom: "Already have an account? Sign In" link.

**Path A — Google Sign-In:**

The user taps "Continue with Google." The system opens the Google Sign-In flow (Cognito hosted UI or native Google SDK). The user selects their Google account and grants permission. On success, the system creates a Cognito user linked to the Google identity and proceeds to Step 4.

- ERROR: Google Sign-In cancelled by user. The system returns to the Sign Up / Sign In Screen with no error message.
- ERROR: Google account already linked to a different Cognito user. The system displays: "This Google account is already associated with another account. Please sign in with your original method or contact support."
- ERROR: Network error during Google Sign-In. The system displays: "Unable to connect. Please check your internet connection and try again."

**Path B — Apple Sign-In (iOS only):**

The user taps "Continue with Apple." The system opens the Apple Sign-In sheet. The user authenticates with Face ID/Touch ID and chooses whether to share their email or use Apple's relay address. On success, the system creates a Cognito user linked to the Apple identity and proceeds to Step 4.

- ERROR: Apple Sign-In cancelled. Return to the Sign Up / Sign In Screen.
- ERROR: Apple Sign-In not available (device does not support it). This button is hidden on unsupported devices.

**Path C — Email Sign-Up:**

The user taps "Sign up with Email." The system navigates to the **Email Sign-Up Screen**.

The **Email Sign-Up Screen** presents a form with:
- Email address field.
- Password field (with show/hide toggle).
- Confirm password field.
- Password requirements displayed below the field: minimum 8 characters, one uppercase letter, one lowercase letter, one number, one special character.

The user fills in the fields and taps "Create Account."

- IF the password does not meet requirements: Inline validation errors are displayed immediately as the user types (e.g., "Must include at least one uppercase letter").
- IF the passwords do not match: Display "Passwords do not match."
- IF the email is already registered: Display "An account with this email already exists. Would you like to sign in instead?" with a link to the sign-in screen.
- ERROR: Network error. Display "Unable to create account. Please check your connection and try again."

On successful submission, the system creates a Cognito user (unverified) and navigates to the **Email Verification Screen**.

The **Email Verification Screen** displays: "We sent a verification code to [email]. Enter the code below." with a 6-digit code input field and a "Resend Code" link.

The user enters the code from their email and taps "Verify."

- IF the code is correct: The account is verified. Proceed to Step 4.
- IF the code is incorrect: Display "Invalid code. Please try again."
- IF the code has expired: Display "Code expired. Tap Resend to get a new code."
- IF the user taps "Resend Code": A new code is sent. Display "New code sent to [email]." Limit to 3 resends.

---

**Step 4: Storage Mode Selection**

The **Storage Mode Screen** presents two options with clear descriptions:

**Option 1: "Cloud + Device" (Recommended)**
- Description: "Your receipts are stored on this device and backed up to the cloud. Access your data across devices. If you lose your phone, your data is safe."
- Icon: Device + cloud illustration.

**Option 2: "Device Only"**
- Description: "Your receipts are stored only on this device. No data is sent to the cloud. If you lose your phone, your data cannot be recovered."
- Icon: Device-only illustration with a lock.
- A note below: "Some features are unavailable in Device Only mode: cloud backup, AI-enhanced extraction, and server notifications."

The user selects one option and taps "Continue."

- The system saves the storage mode preference locally.
- IF the user selects "Device Only": Cloud sync, cloud LLM refinement (F-003), and server notifications (F-006) are disabled.
- IF the user selects "Cloud + Device": All features are enabled. An initial sync handshake is performed in the background.

---

**Step 5: App Lock Prompt (Optional)**

The **App Lock Screen** presents the option to enable biometric/PIN protection:

- Heading: "Protect Your Receipts"
- Description: "Enable fingerprint or face recognition to keep your financial data private."
- "Enable App Lock" button (primary).
- "Skip for Now" link (secondary).

**Path A — Enable App Lock:**

The user taps "Enable App Lock." The system checks device capabilities:

- IF biometric authentication is available (fingerprint or face): The system triggers the native biometric enrollment confirmation. The user authenticates with their biometric. On success, app lock is enabled.
- IF biometrics are not available but a device PIN/passcode is set: The system informs the user that device PIN will be used for app lock. The user confirms.
- IF no device security is configured: The system displays: "To enable App Lock, you need to set up a screen lock on your device. You can enable App Lock later in Settings." The user is taken to Step 6.

**Path B — Skip:**

The user taps "Skip for Now." App lock is not enabled. The user can enable it later in Settings. Proceed to Step 6.

---

**Step 6: Bulk Import Prompt**

The **Bulk Import Screen** asks the user if they want to import existing receipt photos:

- Heading: "Import Existing Receipts"
- Description: "We can scan your photo gallery to find receipt-like images. This helps you start with a complete collection."
- "Scan My Photos" button (primary).
- "Skip" link (secondary).

**Path A — Scan Photos:**

The user taps "Scan My Photos."

- IF gallery permission is not yet granted: The system requests the gallery/photos read permission with the system dialog. The rationale is displayed: "Receipt & Warranty Vault needs access to your photos to find receipt images."
  - IF permission granted: Proceed with scanning.
  - IF permission denied: Display "Gallery access is required to import photos. You can try again later in Settings." Proceed to Step 7.

The system scans the user's photo gallery (limited to the most recent 6 months or 1000 images, whichever is smaller). A progress indicator is displayed: "Scanning your photos... (X of Y)".

When scanning is complete:

- IF receipt-like images are found: The **Import Review Screen** displays a grid of candidate images with checkboxes. All candidates are pre-selected. The user can deselect false positives or select additional images. A "Select All" / "Deselect All" toggle is available. The total count of selected images is shown. The user taps "Import Selected (N)" to confirm.
  - The system queues the selected images for import and OCR processing.
  - A progress indicator shows: "Importing receipts... (X of N)".
  - Processing runs in the background; the user is taken to Step 7 (the home screen) and can start using the app immediately while imports process.
- IF no receipt-like images are found: Display "No receipt-like photos found. You can capture receipts using the camera or import from your gallery at any time." The user taps "Continue" to proceed to Step 7.

**Path B — Skip:**

The user taps "Skip." No photos are scanned. Proceed to Step 7.

---

**Step 7: Home Screen (Onboarding Complete)**

The user arrives at the **Home Screen (Vault Tab)**. If this is their first time and they have no receipts (or imports are still processing), the screen shows an empty state:

- A friendly illustration (empty vault with an open door).
- Text: "Your vault is empty. Capture your first receipt!"
- A prominent "Capture Receipt" button that launches the capture flow (UF-02).
- The bottom tab bar is visible: Vault, Expiring, +Add, Search, Settings.

If bulk import is processing in the background, a subtle banner at the top shows: "Importing X receipts..." with a progress indicator. As receipts finish processing, they appear in the vault list in real time.

The stats bar (F-018) shows: "0 receipts" (or the current count if imports have completed).

Onboarding is complete. The user will not see these onboarding screens again unless they log out and create a new account.

---

### UF-02: Quick Receipt Capture

**Related Features**: F-001, F-002, F-003, F-004, F-005, F-020

**Trigger**: User wants to capture a receipt and review/edit the extracted information before saving.

**Preconditions**: The user is logged in and on any screen in the app. Camera permission may or may not have been granted previously.

---

**Step 1: Initiate Capture**

The user taps the "+" button in the center of the bottom tab bar. The system displays the **Capture Options Sheet** (a bottom sheet or modal) with three options:

1. "Take Photo" (camera icon).
2. "Import from Gallery" (gallery icon) — covered in UF-04.
3. "Import from Files" (file icon).

The user taps "Take Photo."

---

**Step 2: Camera Permission (First Time Only)**

- IF camera permission has not been granted: The system displays the permission rationale: "Receipt & Warranty Vault needs camera access to capture receipt photos." The native permission dialog appears.
  - IF permission granted: The camera opens. Proceed to Step 3.
  - IF permission denied: The system displays: "Camera access is required to take photos. You can enable it in your device settings." A "Open Settings" button is provided. The capture flow is cancelled, and the user returns to the previous screen.
- IF camera permission was previously granted: The camera opens immediately. Proceed to Step 3.

---

**Step 3: Camera Capture**

The **Camera Screen** opens with a full-screen viewfinder optimized for document capture. Available controls:

- A capture button (large, centered at the bottom).
- A flash toggle (auto/on/off) in the top bar.
- A close/cancel button (X) in the top-left corner.
- A thumbnail of the last captured image in the bottom-left corner (if multiple images have been taken in this session).
- A guide overlay showing a subtle rectangular outline suggesting the receipt placement area.

The user frames the receipt and taps the capture button. The system captures the image and displays a brief capture animation (shutter effect).

- IF the image appears blurry (detected via image analysis): The system shows a warning banner: "This image may be blurry. Consider retaking for better accuracy." The user can choose to keep the image or retake.

The captured image thumbnail appears in the bottom-left corner. A "Done" button appears to indicate the user can finish capturing.

**Multi-page receipt**: The user can continue tapping the capture button to take additional photos of the same receipt (e.g., a long receipt that requires two photos). Each additional capture adds to the session. A counter shows "1 photo," "2 photos," etc.

When the user is satisfied, they tap "Done" to proceed to Step 4.

- IF the user taps the close/cancel button (X): The system asks "Discard captured photos?" with "Discard" and "Keep Capturing" buttons. If the user discards, all captured images in this session are deleted and the user returns to the previous screen.

---

**Step 4: Image Preview and Crop**

The **Preview Screen** displays the captured image(s). For each image, the user can:

- Crop the image (drag handles to adjust the crop area).
- Rotate the image (90-degree rotation buttons).
- Retake (returns to the camera for that specific image).
- Delete (removes this image from the multi-image set, with confirmation if it is the only image).

If multiple images were captured, they are shown as a horizontal scrollable strip at the top, with the selected image displayed large below.

The user taps "Continue" when satisfied with the image(s).

---

**Step 5: OCR Processing**

The system transitions to the **Processing Screen** (or overlays a processing indicator on the preview). The following happens:

1. Image compression is applied: JPEG 85%, GPS EXIF stripped (F-020).
2. Compressed images are saved to the local database (F-008).
3. On-device OCR begins (F-002):
   - ML Kit processes Latin text and numbers.
   - Tesseract processes Greek text.
   - Results are merged and deduplicated.
4. The raw OCR text is parsed to extract structured fields: store name, purchase date, total amount, currency, and line items.

A progress indicator is shown: "Reading your receipt..." with a subtle animation.

Processing typically completes in 1-3 seconds.

- ERROR: OCR fails completely (both ML Kit and Tesseract). The system saves the image without extracted data and displays: "We could not read this receipt. You can enter the details manually." The user proceeds to Step 6 with all fields blank.
- ERROR: OCR returns partial results (e.g., date found but no store name). The system populates whatever fields were extracted and leaves the rest blank for manual entry.

---

**Step 6: Review Extracted Fields**

The **Review Screen** displays all extracted fields in an editable form:

- **Store/Merchant Name**: Text field, pre-filled with extracted value (or blank if not detected).
- **Purchase Date**: Date field with date picker, pre-filled with extracted date (or today's date if not detected).
- **Total Amount**: Numeric field with currency selector, pre-filled with extracted total (or blank).
- **Category**: Dropdown showing default and custom categories, pre-selected if the LLM or a heuristic suggested one (or "Other" by default).
- **Line Items**: List of extracted items with quantity and price (if available). The user can add, edit, or remove items.
- **Notes**: Free-text field for user annotations (blank by default).
- **Warranty Section** (see Step 7).

The receipt image(s) are shown as thumbnails at the top of the form. Tapping a thumbnail shows the full image for reference while editing.

Each field has a label and the auto-extracted value as the default. Fields that could not be extracted are visually distinct (lighter placeholder text or a "not detected" label).

The user reviews and modifies any fields as needed.

---

**Step 7: Set Warranty Information**

Within the **Review Screen**, a dedicated warranty section is presented:

- **Has Warranty**: Toggle switch (default: off, or on if the OCR/LLM detected warranty language).
- IF toggle is on:
  - **Warranty Duration**: Numeric field with unit selector (months or years). Pre-filled if detected by OCR.
  - **Warranty Expiry Date**: Automatically calculated as purchase date + duration. Displayed as read-only for reference.
  - The warranty status badge is previewed: "Active" (green), "Expiring Soon" (amber), or "Expired" (red), based on the calculated expiry.

The user sets the warranty information as needed.

---

**Step 8: Save**

The user taps the "Save" button at the bottom of the Review Screen.

The system:
1. Validates all fields (date is valid, amount is non-negative, at least one image exists).
   - IF validation fails: Inline errors are displayed on the offending fields. The save is blocked until errors are resolved.
2. Saves the receipt record to the local database (F-008).
3. Records any user-edited fields in the `user_edited_fields` array.
4. Generates a local thumbnail (200x300) for the list view.
5. Schedules local warranty reminder notifications if a warranty was set (F-006).
6. IF the device is online AND the storage mode is Cloud+Device: Queues the receipt for cloud sync (image upload to S3 via pre-signed URL, record to DynamoDB) and cloud LLM refinement (F-003).

A success confirmation is displayed: a brief toast or banner saying "Receipt saved!" with the store name.

The user is taken to the **Receipt Detail View** (UF-05) for the newly saved receipt, or back to the **Home Screen** (user preference, with "Home" as default).

---

**Step 9: Background Cloud LLM Refinement (Asynchronous)**

If the device is online and cloud mode is enabled, the cloud LLM refinement process runs in the background after save:

1. The raw OCR text (and optionally the image) is sent to the backend via API Gateway.
2. The backend invokes Bedrock Claude Haiku 4.5.
3. The LLM returns refined structured data: corrected store name, formatted date, accurate total, category suggestion, and warranty detection.
4. IF Haiku returns an error or low confidence: The backend automatically retries with Sonnet 4.5.
5. The refined data is returned to the client and merged into the local receipt record, respecting the conflict resolution tiers (user-edited fields are not overwritten).
6. The user receives a subtle in-app notification (badge or toast) if the LLM refinement changed any visible fields: "Receipt updated: [Store Name] details refined."

This step is entirely transparent to the user. They do not need to wait for it or take any action.

---

### UF-03: Fast Save Flow

**Related Features**: F-001, F-002, F-004, F-020

**Trigger**: User wants to capture a receipt as quickly as possible and edit the details later.

**Preconditions**: Same as UF-02.

---

**Steps 1-5: Identical to UF-02 (Steps 1-5)**

The user initiates capture, takes a photo, previews/crops, and OCR processes the image. All steps are the same as Quick Receipt Capture through the OCR processing step.

---

**Step 6: Fast Save**

After OCR processing completes, the **Review Screen** appears (same as UF-02 Step 6). However, instead of reviewing every field, the user taps the "Fast Save" button prominently displayed in the top-right corner or as a secondary action button.

The system:
1. Saves the receipt immediately with all auto-extracted data, without requiring the user to review or edit any field.
2. Assigns the auto-detected category (or "Other" if none was detected).
3. If warranty information was detected by OCR, it is saved. If not, the warranty is set to "No Warranty."
4. All validation is skipped except the minimum requirement (at least one image).
5. The receipt is marked internally as "auto-saved, not yet reviewed" (this marker is informational and does not affect functionality).
6. Saves to local database, generates thumbnail, and queues for cloud sync/LLM refinement as in UF-02 Step 8.

A success confirmation is displayed: "Receipt saved! You can edit the details anytime."

The user is returned to the **Home Screen** or the previous screen, having completed the entire capture in under 10 seconds.

---

**Step 7: Edit Later**

The receipt appears in the vault with whatever data was auto-extracted. The user can tap the receipt at any time to view details (UF-05) and tap "Edit" to correct or add information (UF-06).

When cloud LLM refinement completes (if applicable), the receipt's data is updated with higher-quality extractions. The user may find that the data needs less manual correction thanks to the LLM.

---

### UF-04: Import from Gallery

**Related Features**: F-001, F-002, F-003, F-004, F-020

**Trigger**: User wants to import one or more receipt photos already in their device gallery.

**Preconditions**: User is logged in. Gallery/photos permission may or may not be granted.

---

**Step 1: Initiate Import**

The user taps the "+" button in the bottom tab bar. The **Capture Options Sheet** appears. The user taps "Import from Gallery."

---

**Step 2: Gallery Permission (First Time Only)**

- IF gallery read permission has not been granted: The system requests permission with rationale: "Receipt & Warranty Vault needs access to your photos to import receipt images."
  - IF permission granted: The gallery picker opens. Proceed to Step 3.
  - IF permission denied: Display "Photo access is required to import images. You can enable it in Settings." A "Open Settings" button is provided. The flow is cancelled.
- IF permission was previously granted: The gallery picker opens immediately.

---

**Step 3: Select Images**

The system opens the native image picker (or a custom gallery grid within the app) allowing the user to select one or more images.

- The user can select multiple images by tapping thumbnails (each selected image shows a checkmark and a number indicating selection order).
- A counter shows the number of selected images.
- A "Done" or "Import" button confirms the selection.

The user selects the desired images and taps "Done."

- IF the user selects no images and taps "Done": Return to the previous screen with no action.
- IF the user cancels: Return to the previous screen with no action.

---

**Step 4: Import Confirmation for Multiple Images**

- IF the user selected exactly one image: Proceed directly to Step 5 (single receipt flow).
- IF the user selected multiple images: The system asks: "Create separate receipts for each image, or combine as one receipt?"
  - "Separate receipts" — each image becomes its own receipt, each processed independently.
  - "One receipt (multi-page)" — all images are combined as a single multi-page receipt.

  The user selects their preference and taps "Continue."

---

**Step 5: Processing and Review**

**For a single receipt (one image or multi-page combined):**

The flow proceeds identically to UF-02 Steps 4-8: preview/crop, OCR processing, review extracted fields, set warranty, and save. The "Fast Save" option (UF-03) is also available.

**For multiple separate receipts:**

The system processes each image in sequence:
1. Image compression is applied to all images (F-020).
2. OCR runs on each image.
3. The **Batch Review Screen** displays a list of the imported receipts with auto-extracted summaries (store name, date, total) for each.
4. The user can tap any receipt in the list to open its individual review/edit form (UF-02 Step 6).
5. A "Save All" button saves all receipts with their current (auto-extracted or user-edited) data.
6. A "Fast Save All" button saves all receipts immediately with auto-extracted data.

- ERROR: One image fails to process (corrupted file): That image is flagged with an error indicator. The user can remove it or save it without extracted data. Other images continue processing normally.

After saving, the user is returned to the **Home Screen** where the new receipts appear in the vault.

---

### UF-05: Receipt Detail View

**Related Features**: F-001, F-004, F-005, F-012, F-014, F-015

**Trigger**: User taps a receipt card in the vault list, search results, or expiring tab.

**Preconditions**: The receipt exists in the local database.

---

**Step 1: Navigation to Detail**

The user taps a receipt card. The system navigates to the **Receipt Detail Screen** with a slide-in transition from the right.

---

**Step 2: Detail Screen Layout**

The **Receipt Detail Screen** displays the following sections from top to bottom:

**Header Section:**
- Back button (top-left, returns to the previous screen).
- Action menu (top-right, three-dot or overflow menu with: Edit, Share, Mark as Returned, Delete).
- Store/merchant name (large heading text).
- Category badge (colored chip showing the category name).
- Status badges: "Returned" (if applicable), warranty status badge (Active/Expiring Soon/Expired/No Warranty).

**Image Section:**
- The receipt image(s) displayed in a horizontally swipeable carousel.
- IF multiple images: Dot indicators show the current position. The user swipes left/right to view different images.
- Tapping an image opens a full-screen zoomable view. The user can pinch to zoom and pan. A close button returns to the detail view.

**Information Section:**
- Purchase date (formatted per locale).
- Total amount with currency symbol.
- Line items (if available), listed with names and individual prices.

**Warranty Section (if warranty exists):**
- Warranty duration (e.g., "24 months").
- Warranty expiry date (e.g., "15 March 2028").
- Progress bar showing the percentage of warranty elapsed. Color: green (Active), amber (Expiring Soon), red (Expired).
- Countdown text: "X days remaining" (if active/expiring) or "Expired X days ago" (if expired).
- Reminder settings: shows the configured notification timing (e.g., "Reminders: 30 days, 7 days before expiry").

**Notes Section:**
- User notes displayed as plain text. Shows "No notes" in grey if empty.

**Metadata Section (collapsible):**
- Date added.
- Last modified date.
- Sync status: "Synced" (green checkmark), "Pending sync" (grey clock icon), or "Device only."
- LLM refinement status: "AI-refined" (if cloud refinement was applied) or "Device OCR only."

---

**Step 3: Available Actions**

From the detail screen, the user can perform the following actions via the action menu or dedicated buttons:

1. **Edit** — navigates to the edit flow (UF-06).
2. **Share** — opens the share flow (UF-12, single receipt).
3. **Mark as Returned** — triggers the mark as returned flow (UF-10).
4. **Delete** — triggers the delete flow (UF-11).

---

**Step 4: Back Navigation**

The user taps the back button or uses the system back gesture. The system returns to the previous screen (vault list, search results, or expiring tab) with the list scrolled to the same position as before.

---

### UF-06: Edit Receipt

**Related Features**: F-004, F-005, F-008, F-013

**Trigger**: User taps "Edit" from the receipt detail view or from the action menu.

**Preconditions**: The user is viewing a receipt in the detail view.

---

**Step 1: Open Edit Mode**

The user taps "Edit" from the detail view action menu. The system transitions to the **Edit Receipt Screen**, which displays the same form as the capture review screen (UF-02 Step 6) but pre-populated with the receipt's current data.

---

**Step 2: Editable Fields**

The **Edit Receipt Screen** presents all fields in editable form:

- **Store/Merchant Name**: Text input, current value pre-filled.
- **Purchase Date**: Date picker, current date pre-selected.
- **Total Amount**: Numeric input with currency selector, current values pre-filled.
- **Category**: Dropdown with all categories (defaults + custom), current category pre-selected.
- **Line Items**: Editable list. User can:
  - Edit existing items (tap to modify name, quantity, price).
  - Add new items (tap "Add Item" button at the bottom of the list).
  - Remove items (swipe left to delete, with confirmation).
- **Warranty Toggle**: On/off, current state pre-set. Toggling on reveals the duration field.
- **Warranty Duration**: Numeric input with unit (months/years), current value pre-filled if warranty exists.
- **Notes**: Multi-line text input, current notes pre-filled.

**Image Management:**
- The user can view existing images in a scrollable strip.
- The user can add new images (opens camera or gallery picker).
- The user can remove an existing image (long-press or tap X, with confirmation). The receipt must have at least one image.
- The user can crop or rotate an existing image.

---

**Step 3: Save Changes**

The user taps "Save" after making modifications.

The system:
1. Validates all fields (same rules as initial capture: valid dates, non-negative amounts).
   - IF validation fails: Inline errors appear. Save is blocked.
2. Compares each field to its previous value. Any changed fields are added to the `user_edited_fields` array if not already present.
3. Increments the record's version number.
4. Updates the `updatedAt` timestamp.
5. Saves the updated record to the local database.
6. IF warranty information changed: Reschedules all local notification reminders for this receipt (cancels old ones, schedules new ones based on updated expiry).
7. IF the device is online and in Cloud+Device mode: Queues the updated record for sync.

A confirmation is displayed: "Changes saved." The user is returned to the **Receipt Detail Screen**, which now reflects the updated data.

---

**Step 4: Cancel Edit**

If the user taps the back button or "Cancel" without saving:

- IF changes were made: The system displays a confirmation dialog: "Discard changes?" with "Discard" and "Keep Editing" buttons.
  - "Discard": All changes are lost. Return to the detail view with original data.
  - "Keep Editing": Return to the edit screen.
- IF no changes were made: Return to the detail view immediately with no confirmation.

---

**Step 5: Conflict Resolution (Offline Edit Sync)**

This step occurs asynchronously when the user edits a receipt while offline and later syncs:

1. The sync engine detects that the local record has a different version than the server record.
2. Field-level merge is applied:
   - Tier 1 fields (LLM-extracted: store name, date, total, OCR text, confidence): Server/LLM version wins, UNLESS the field is in the user's `user_edited_fields` array, in which case the user's version is preserved.
   - Tier 2 fields (user personal: notes, tags, is_favorite): Client/user version wins.
   - Tier 3 fields (shared: display name, category, warranty months): If the field is in `user_edited_fields`, the client version wins. Otherwise, the most recent edit (by timestamp) wins.
3. The merged record replaces both the local and server versions.
4. IF the merge changes any user-visible fields compared to what the user last saw: A subtle notification is displayed: "Receipt [Store Name] was updated during sync. Tap to review."

- ERROR: Merge conflict cannot be resolved automatically (e.g., both devices edited the same Tier 3 field at nearly the same time and both are in `user_edited_fields`): The most recent timestamp wins. No user intervention is required in v1.0.

---

### UF-07: Search and Filter

**Related Features**: F-007, F-005, F-013

**Trigger**: User taps the Search tab in the bottom navigation bar or wants to find a specific receipt.

**Preconditions**: User is logged in. The local database contains receipts (search works even with zero receipts but returns no results).

---

**Step 1: Open Search**

The user taps the "Search" tab in the bottom navigation bar. The **Search Screen** appears with:

- A search bar at the top with a text input field and a magnifying glass icon. The cursor is automatically placed in the search field and the keyboard appears.
- Below the search bar: a row of filter chips (initially inactive/grey).
- Below the filters: recent searches (last 10, shown as tappable chips) if the search bar is empty.
- The body of the screen shows "Search your receipts" placeholder text when no search has been performed.

---

**Step 2: Type a Search Query**

The user begins typing in the search bar. The system searches the FTS5 full-text index in real time, debounced at 300ms (the search executes 300ms after the user stops typing).

The search covers:
- Raw OCR text.
- Store/merchant name.
- Notes.
- Line item descriptions.
- Category name.

As results appear, the **Results List** populates below the filters. Each result is shown as a compact receipt card with: store name, date, total amount, category badge, and warranty status badge.

- Results are ranked by FTS5 relevance score.
- The matching text snippet is highlighted in the result card (e.g., the search term is bolded within the store name or OCR text excerpt).
- The total number of results is shown: "X results."

---

**Step 3: Apply Filters**

The user can tap filter chips to narrow results. Tapping a filter chip opens the relevant filter control:

**Category Filter:**
- Tapping the "Category" chip opens a multi-select list of all categories (defaults + custom).
- The user checks one or more categories and taps "Apply."
- The chip turns active (colored) and shows the count: "Category (3)."

**Store Filter:**
- Tapping the "Store" chip opens a multi-select list of all store names found in the user's receipts.
- The user selects one or more stores and taps "Apply."

**Date Range Filter:**
- Tapping the "Date" chip opens a date range picker with "From" and "To" fields.
- The user selects a start and end date and taps "Apply."
- The chip shows the range: "Jan 2025 - Mar 2025."

**Warranty Status Filter:**
- Tapping the "Warranty" chip opens a multi-select with options: Active, Expiring Soon, Expired, No Warranty, Returned.
- The user selects one or more statuses and taps "Apply."

**Amount Range Filter:**
- Tapping the "Amount" chip opens a range input with "Min" and "Max" numeric fields.
- The user enters values and taps "Apply."
- IF min is greater than max: Display "Minimum must be less than maximum."

Filters combine with the search query using logical AND (results must match the search text AND all active filters). Within a multi-select filter, options use logical OR (e.g., selecting "Electronics" and "Clothing" shows receipts in either category).

Active filters are shown as colored chips with an "X" to remove individual filters. A "Clear All" link removes all filters.

---

**Step 4: View a Result**

The user taps a result card. The system navigates to the **Receipt Detail Screen** (UF-05) for the selected receipt.

When the user returns from the detail view (back navigation), the search screen is restored with the same query, filters, and scroll position.

---

**Step 5: No Results**

If the search and/or filters return no matching receipts:

- The results area shows: "No receipts found."
- Suggestions are displayed below: "Try a different keyword," "Check your spelling," or "Adjust your filters."
- IF filters are active: A "Clear Filters" button is displayed.

---

### UF-08: Warranty Expiry Reminder Flow

**Related Features**: F-006, F-005

**Trigger**: A scheduled warranty reminder time is reached (either local notification timer or server-side EventBridge check).

**Preconditions**: The user has receipts with active warranties and notification reminders are configured and permissions are granted.

---

**Step 1: System Warranty Check**

**Local Notifications Path:**
- At the time the receipt was saved (or warranty was last edited), local notifications were scheduled using `flutter_local_notifications`.
- The notification fires at the scheduled time (e.g., 30 days before expiry, 7 days before expiry).
- This works even if the device is offline.

**Server-Side Notifications Path:**
- An EventBridge rule triggers a Lambda function daily (e.g., at 09:00 UTC).
- The Lambda scans the DynamoDB ByWarrantyExpiry GSI (GSI-4) for warranties expiring within any user's configured reminder windows.
- For each matching warranty, the Lambda sends an SNS notification routed through FCM to the user's device.

---

**Step 2: Notification Displayed**

The device displays a push notification with:

- **Title**: "Warranty Expiring Soon" (or "Warranty Expires Tomorrow" / "Warranty Expires in 7 Days" depending on timing).
- **Body**: "[Store Name] - [Item description if available]. Warranty expires in X days (on [date])."
- **Icon**: The app icon.
- **Sound**: Default notification sound (respects device Do Not Disturb settings).

The notification appears in the device notification tray. On iOS, it also appears on the lock screen. On Android, it appears as a heads-up notification if the app is not in the foreground.

---

**Step 3: User Taps Notification**

The user taps the notification. The system:

1. Opens the app (or brings it to the foreground if already running).
2. IF app lock is enabled (F-011): The **Lock Screen** appears. The user authenticates with biometric or PIN. On success, proceed. On failure, the app remains on the lock screen.
3. The app navigates directly to the **Receipt Detail Screen** (UF-05) for the receipt referenced in the notification.
4. The warranty section is prominently displayed, showing the countdown and progress bar.

The user can now view the receipt details, check warranty information, and take action (e.g., initiate a warranty claim by exporting/sharing the receipt, or mark it as returned if they returned the item).

---

**Step 4: User Does Not Tap Notification**

If the user does not tap the notification, it remains in the notification tray. The notification is not repeated for the same reminder interval (e.g., the 30-day reminder fires once). The next scheduled reminder (e.g., the 7-day reminder) will fire at its configured time.

If the user dismisses the notification without tapping it, no further action is taken for that specific reminder.

---

**Edge Cases:**

- Notification arrives while the app is open: Display an in-app banner/toast instead of a system notification. The banner is tappable and navigates to the receipt detail.
- Multiple notifications arrive simultaneously (e.g., several warranties expiring on the same day): Each notification is displayed separately. On Android, they may be grouped under a summary notification: "X warranties expiring soon."
- Warranty was extended or receipt was deleted between scheduling and delivery: The notification may still fire (for local notifications). When the user taps it, the app checks the current state:
  - IF the receipt was soft-deleted: Display "This receipt was deleted" and offer to restore it.
  - IF the warranty was extended: Show the updated warranty information. The notification content may be slightly outdated, but the detail view shows the correct state.
- User has notifications disabled: No notification is delivered. The app continues to function normally. The "Expiring" tab still shows upcoming expirations.

---

### UF-09: Offline Capture and Sync

**Related Features**: F-001, F-002, F-003, F-008

**Trigger**: User captures a receipt while the device has no internet connection. Later, connectivity is restored and the data syncs.

**Preconditions**: User is logged in with Cloud+Device storage mode. The device is currently offline.

---

**Step 1: Offline Capture**

The user is in a store with no internet signal. They tap the "+" button and capture a receipt (following UF-02 or UF-03).

Everything works normally:
- Camera opens and captures the image.
- Image is compressed and saved locally (F-020, F-008).
- On-device OCR runs and extracts fields (F-002).
- The user reviews/edits fields and saves (or uses Fast Save).
- The receipt is saved to the local Drift/SQLCipher database.
- Local warranty notifications are scheduled if applicable.

The only differences from an online capture:
- Cloud LLM refinement (F-003) does not occur. The receipt is queued for refinement but the request is not sent.
- Cloud sync does not occur. The receipt is marked as "pending sync" in the local database.
- The receipt detail view shows sync status: "Pending sync" with a grey clock icon.

The user continues using the app normally. They can capture more receipts, search, view warranty status, etc. All functionality works offline.

---

**Step 2: Connectivity Restored**

Sometime later, the device regains internet connectivity. The sync engine detects this through one of three mechanisms:

1. **App resume**: When the app comes to the foreground, it checks connectivity and triggers sync if changes are pending.
2. **Silent push notification**: The server sends a periodic silent push to wake the app for sync (if FCM token is registered).
3. **WorkManager background task**: A periodic background task (every 15 minutes on Android, background app refresh on iOS) checks for pending sync items.

---

**Step 3: Background Sync**

The sync engine processes all pending items:

1. **Image upload**: Each pending receipt image is uploaded to S3 via a pre-signed URL.
   - The client requests a pre-signed URL from the API Gateway (authenticated via Cognito token).
   - The server generates a pre-signed URL (10-minute expiry, restricted to the expected content type and size).
   - The client uploads the image directly to S3.
   - On successful upload, a Lambda trigger generates the server-side thumbnail (200x300, JPEG 70%).

2. **Record sync**: Receipt metadata is pushed to DynamoDB via the API.
   - Each record includes its version number and updatedAt timestamp.
   - The server checks for conflicts (records modified on the server since the client's last sync).
   - Conflict resolution is applied per the field-level merge strategy.

3. **Cloud LLM refinement**: For each newly synced receipt that has not been LLM-refined:
   - The raw OCR text (and optionally the image URL) is sent to Bedrock Claude Haiku 4.5.
   - The LLM returns refined fields.
   - Refined data is merged into the receipt record (respecting user_edited_fields).
   - The updated record is pushed back to the client via the sync response.

A subtle sync indicator is shown in the app bar during active sync (e.g., a small spinning icon). The user does not need to take any action.

---

**Step 4: Sync Completion and Notification**

When sync completes:

1. The sync indicator in the app bar disappears or changes to a checkmark.
2. Receipt detail views now show sync status: "Synced" with a green checkmark.
3. IF cloud LLM refinement changed any fields:
   - The receipt record is updated locally with the refined data.
   - A subtle notification or in-app message appears: "AI has improved the details for X receipt(s). Tap to review."
   - The user can tap the notification to see the updated receipt(s) in the detail view.
4. IF sync encountered errors:
   - Failed items remain in the pending queue and are retried on the next sync cycle.
   - After 3 consecutive failures for a specific record, a warning is shown: "Some receipts could not be synced. We will keep trying."
   - No data is lost; the local database retains all data.

---

**Edge Cases:**

- User edits a receipt while it is being synced: The sync engine detects the concurrent modification and reschedules the sync for that record with the latest local data.
- Upload of a large image fails due to timeout: The sync engine retries the upload. If the pre-signed URL expired (took longer than 10 minutes), a new URL is requested.
- Server returns a version conflict: Field-level merge is applied. The merged result is written to both local and server databases.
- Many receipts pending sync (e.g., 50): The sync engine processes them in batches (e.g., 5 at a time) to avoid overwhelming the API. Progress is tracked per-record.
- User switches to Device-Only mode while sync is pending: Pending sync items are cancelled. The cloud deletion request is sent (or queued). Local data is preserved.
- Sync runs in the background and the app is killed by the OS: WorkManager (Android) or background task (iOS) ensures sync resumes. Partially uploaded images are detected via S3 multipart upload status or simply re-uploaded.

---

### UF-10: Mark as Returned

**Related Features**: F-014, F-005, F-018

**Trigger**: User has returned a purchased item and wants to update the receipt's status.

**Preconditions**: The user is viewing a receipt in the detail view. The receipt is not already marked as returned.

---

**Step 1: Initiate Mark as Returned**

The user opens the receipt detail view (UF-05) and taps the action menu (three-dot menu in the top-right). From the menu, the user selects "Mark as Returned."

---

**Step 2: Confirmation Dialog**

The system displays a confirmation dialog:

- **Title**: "Mark as Returned?"
- **Body**: "This receipt will be marked as returned. It will be excluded from warranty tracking and active warranty stats. You can undo this at any time."
- **Buttons**: "Mark as Returned" (primary action, amber or neutral color) and "Cancel."

The user taps "Mark as Returned."

- IF the user taps "Cancel": The dialog is dismissed. No changes are made.

---

**Step 3: Apply Returned Status**

The system:

1. Sets the receipt's status to "Returned" in the local database.
2. Records the return date as the current date.
3. Increments the record version number and updates the `updatedAt` timestamp.
4. Cancels any pending warranty reminder notifications for this receipt (since the warranty is no longer relevant).
5. Updates the home screen stats (F-018): the returned receipt's amount is subtracted from the active warranty total.
6. Queues the update for cloud sync if in Cloud+Device mode.

---

**Step 4: Visual Update**

The **Receipt Detail Screen** updates to reflect the new status:

- A "Returned" badge appears in the header section (distinct from the warranty badge).
- The warranty section is still visible but visually muted (greyed out) with a note: "Warranty tracking paused (item returned)."
- The action menu now shows "Unmark as Returned" instead of "Mark as Returned."

A brief toast confirms: "Marked as returned."

---

**Step 5: Unmark as Returned (Undo)**

If the user later changes their mind:

1. Open the receipt detail view.
2. Tap the action menu.
3. Select "Unmark as Returned."
4. A confirmation dialog appears: "Remove returned status? Warranty tracking will resume." with "Confirm" and "Cancel."
5. On confirmation: The "Returned" badge is removed, warranty tracking resumes with the original dates, notifications are rescheduled, and stats are updated.

---

### UF-11: Delete Receipt

**Related Features**: F-015

**Trigger**: User wants to delete a receipt from their vault.

**Preconditions**: The user is viewing a receipt in the detail view.

---

**Step 1: Initiate Delete**

The user opens the receipt detail view (UF-05) and taps the action menu. From the menu, the user selects "Delete."

---

**Step 2: Confirmation Dialog**

The system displays a confirmation dialog:

- **Title**: "Delete Receipt?"
- **Body**: "This receipt will be moved to Recently Deleted and permanently removed after 30 days. You can recover it during that time."
- **Buttons**: "Delete" (red/destructive color) and "Cancel."

The user taps "Delete."

- IF the user taps "Cancel": The dialog is dismissed. No changes are made.

---

**Step 3: Soft Delete**

The system:

1. Sets the receipt's status to "soft_deleted" in the local database.
2. Records the deletion timestamp (the 30-day countdown starts from this moment).
3. Cancels any pending warranty reminder notifications for this receipt.
4. Removes the receipt from all regular views (vault list, search results, expiring tab, stats).
5. The receipt now appears only in the "Recently Deleted" section (accessible from Settings).
6. Queues the soft delete status change for cloud sync.
7. For cloud users: the S3 image is not immediately deleted; S3 Versioning marks it as a noncurrent version, which will be automatically cleaned up after 30 days by the NoncurrentVersionExpiration lifecycle rule.
8. For cloud users: the DynamoDB record is updated with a TTL set to 30 days from the deletion timestamp.

A brief toast confirms: "Receipt deleted. You can recover it within 30 days."

The user is returned to the previous screen (vault list, search, or expiring tab). The deleted receipt is no longer visible.

---

**Step 4: View Recently Deleted (Recovery)**

To recover a deleted receipt:

1. The user navigates to Settings > Recently Deleted.
2. The **Recently Deleted Screen** displays all soft-deleted receipts with:
   - Store name and date.
   - Days remaining before permanent deletion (e.g., "23 days left to recover").
   - A progress bar showing how much of the 30-day recovery period has elapsed.
3. The user taps a deleted receipt.
4. A dialog appears: "Recover this receipt?" with "Recover" and "Cancel" buttons.
5. On "Recover": The receipt's status is restored to its previous state (active, returned, etc.). It reappears in all regular views. Warranty notifications are rescheduled if applicable. Cloud sync is queued.
6. On "Cancel": No change.

---

**Step 5: Permanent Deletion (Automatic)**

After 30 days from the soft delete timestamp:

- **Local database**: A background cleanup task detects expired soft-deleted records and permanently removes them from the Drift database, including all associated images from local storage.
- **DynamoDB**: The TTL attribute causes automatic deletion of the record.
- **S3**: The NoncurrentVersionExpiration lifecycle rule permanently deletes the noncurrent image versions.

No user action is required. The permanent deletion happens silently.

---

**Edge Cases:**

- User soft-deletes a receipt while offline: The deletion is recorded locally. On sync, the cloud record is also soft-deleted. The 30-day timer starts from the original local deletion timestamp, not the sync time.
- User recovers a receipt on device A, but it is still showing as deleted on device B: On sync, the recovery (restore) takes precedence over the deletion. The receipt reappears on device B.
- User attempts to recover a receipt that has already been permanently deleted on the server (edge case with timing): The recovery fails. The user is informed: "This receipt can no longer be recovered."

---

### UF-12: Export Flow

**Related Features**: F-012, F-008

**Trigger**: User wants to share a single receipt or export a batch of receipts.

**Preconditions**: User is logged in. At least one receipt exists in the vault.

---

**Path A: Share Single Receipt**

**Step 1**: The user is on the **Receipt Detail Screen** (UF-05). They tap the action menu and select "Share," or tap a dedicated "Share" button.

**Step 2**: The system presents format options:

- "Share as Image" — generates a single annotated image with the receipt photo and metadata overlay (store name, date, total, warranty status).
- "Share as PDF" — generates a PDF document with the receipt image(s) on one page and a metadata summary on the next page.

The user selects a format.

**Step 3**: The system generates the export file:

- A progress indicator is shown briefly: "Preparing receipt..."
- The generated file is saved to a temporary location.
- The native share sheet opens, allowing the user to choose a destination (messaging app, email, AirDrop, save to files, etc.).

**Step 4**: The user selects a share destination and completes the share action (or cancels).

- IF the user cancels the share sheet: The temporary file is cleaned up. No data is shared.
- ERROR: File generation fails (e.g., image corrupted): Display "Unable to generate export. Please try again."

---

**Path B: Batch Export by Date Range**

**Step 1**: The user navigates to Settings > Export Receipts (or accesses batch export from a dedicated menu).

**Step 2**: The **Export Screen** presents options:

- **Date Range**: Start date and end date pickers. Default: last 30 days.
- **Preview**: After selecting a date range, the system shows a summary: "X receipts found in this range. Estimated file size: Y MB."
- **Format**: "ZIP (PDFs + CSV summary)" is the primary format.

The user sets the date range and reviews the preview.

- IF no receipts exist in the selected range: Display "No receipts found in this date range. Try adjusting the dates."

**Step 3**: The user taps "Export."

The system generates the export:

1. A progress indicator shows: "Exporting receipts... (X of Y)."
2. For each receipt in the range: A PDF is generated with the receipt image(s) and metadata.
3. A CSV summary file is generated with one row per receipt: store name, date, total, currency, category, warranty status, warranty expiry date.
4. All PDFs and the CSV are bundled into a ZIP file.

**Step 4**: Export complete. The system offers:

- "Save to Files" — saves the ZIP to the device's downloads/files directory.
- "Share" — opens the native share sheet with the ZIP file.

The user selects their preferred option.

- ERROR: Export interrupted (app killed): The partial export file is cleaned up. The user must restart the export.
- ERROR: Insufficient storage: Display "Not enough storage to complete export. Free up X MB and try again."

---

### UF-13: Settings -- Change Storage Mode

**Related Features**: F-009, F-008, F-003, F-006

**Trigger**: User wants to change their storage mode (Cloud+Device to Device-Only or vice versa).

**Preconditions**: User is logged in and on the Settings screen.

---

**Step 1: Navigate to Storage Mode**

The user taps the "Settings" tab in the bottom navigation. On the **Settings Screen**, the user taps "Storage Mode." The current mode is displayed next to the menu item (e.g., "Cloud + Device").

---

**Step 2: Storage Mode Screen**

The **Storage Mode Screen** displays the two options with the current selection highlighted:

1. **Cloud + Device** (current, if applicable): Description and benefits listed.
2. **Device Only**: Description, limitations noted (no cloud backup, no AI refinement, no server notifications).

The user taps the option they want to switch to.

---

**Path A: Switching from Cloud+Device to Device-Only**

**Step 3A**: The system displays a warning dialog:

- **Title**: "Switch to Device Only?"
- **Body**: "Your receipts will remain on this device, but all cloud data will be permanently deleted. This includes:
  - Cloud backup of all receipt data
  - Receipt images stored in the cloud
  - AI-enhanced extraction data

  Server-side notifications will be disabled. Local reminders will continue to work.

  If you lose this device, your data cannot be recovered.

  This action cannot be undone without re-uploading all data."
- **Buttons**: "Switch to Device Only" (red/destructive) and "Cancel."

**Step 4A**: The user taps "Switch to Device Only."

The system:

1. IF a sync is currently in progress: Waits for it to complete (displays "Finishing current sync...").
2. Disables the sync engine.
3. Disables cloud LLM refinement (F-003).
4. Disables server-side notifications. Local notifications remain active.
5. Sends a cloud data deletion request to the backend:
   - The backend Lambda deletes all DynamoDB records for this user.
   - The backend Lambda deletes all S3 objects (images and thumbnails) for this user.
   - This runs asynchronously; the user does not need to wait.
6. Updates the local storage mode preference.
7. Displays confirmation: "Storage mode changed to Device Only. Your cloud data is being deleted."

The user is returned to the Settings Screen. The Storage Mode now shows "Device Only."

- ERROR: Cloud deletion request fails (no internet): The request is queued and will execute when connectivity is restored. The storage mode is changed locally immediately. A note is shown: "Cloud data deletion is pending and will complete when you are back online."

---

**Path B: Switching from Device-Only to Cloud+Device**

**Step 3B**: The system displays an information dialog:

- **Title**: "Enable Cloud Sync?"
- **Body**: "Your receipts will begin syncing to the cloud. This enables:
  - Cloud backup (protect against device loss)
  - AI-enhanced receipt extraction
  - Server-side warranty reminders

  An initial sync will upload all your existing receipts. This may take a few minutes depending on the number of receipts and your connection speed."
- **Buttons**: "Enable Cloud Sync" (primary) and "Cancel."

**Step 4B**: The user taps "Enable Cloud Sync."

The system:

1. Checks that the user has an active internet connection.
   - IF no internet: Display "An internet connection is required to enable cloud sync. Please try again when you are online." Return to the Storage Mode Screen.
2. Enables the sync engine.
3. Enables cloud LLM refinement.
4. Enables server-side notifications (registers the FCM device token with the backend).
5. Triggers a full initial sync: all local receipts are queued for upload to DynamoDB and S3.
6. A progress indicator is shown: "Syncing your receipts... (X of Y)." The user can navigate away; sync continues in the background.
7. For each synced receipt that has not been LLM-refined: Cloud LLM refinement is queued.
8. Updates the local storage mode preference.
9. Displays confirmation: "Cloud sync enabled. Your receipts are being uploaded."

The user is returned to the Settings Screen. The Storage Mode now shows "Cloud + Device."

---

### UF-14: Settings -- Manage Categories

**Related Features**: F-013

**Trigger**: User wants to add, edit, or delete custom categories.

**Preconditions**: User is logged in and on the Settings screen.

---

**Step 1: Navigate to Categories**

The user taps "Settings" in the bottom navigation. On the **Settings Screen**, the user taps "Manage Categories."

---

**Step 2: Categories Screen**

The **Manage Categories Screen** displays two sections:

**Default Categories** (non-editable):
- A list of the 10 default categories, each with its name and icon.
- A lock icon or "Default" label indicates these cannot be modified.
- Each default category shows the count of receipts assigned to it.

**Custom Categories** (editable):
- A list of user-created categories (or "No custom categories yet" if none exist).
- Each custom category shows: name, icon/color (if set), and receipt count.
- Each custom category has an edit button (pencil icon) and a delete button (trash icon).
- At the bottom of the list: an "Add Category" button.

---

**Path A: Add a New Custom Category**

**Step 3A**: The user taps "Add Category." A dialog or bottom sheet appears with:

- **Category Name**: Text input field (required).
- **Color**: A color picker or preset color palette (optional, defaults to a neutral color).
- **Buttons**: "Create" and "Cancel."

The user enters a name (e.g., "Pet Supplies") and optionally selects a color.

- IF the name matches an existing category (default or custom, case-insensitive): Display "A category with this name already exists."
- IF the name exceeds 30 characters: Display "Category name must be 30 characters or fewer."
- IF the name is empty: The "Create" button is disabled.

The user taps "Create."

The system:
1. Creates the new category in the local database.
2. Queues the update for cloud sync (the category list is stored under the META#CATEGORIES sort key in DynamoDB).
3. The new category appears in the custom categories list.

A confirmation is shown: "Category created."

---

**Path B: Edit a Custom Category**

**Step 3B**: The user taps the edit button (pencil icon) on a custom category. An edit dialog appears with the current name and color pre-filled.

The user modifies the name and/or color and taps "Save."

- The same validation rules apply (no duplicates, max 30 characters).

The system:
1. Updates the category name in the local database.
2. Updates all receipts that reference this category to use the new name.
3. Queues the update for cloud sync.

A confirmation is shown: "Category updated."

---

**Path C: Delete a Custom Category**

**Step 3C**: The user taps the delete button (trash icon) on a custom category.

- IF the category has zero receipts: A simple confirmation dialog appears: "Delete '[Category Name]'?" with "Delete" and "Cancel."
- IF the category has receipts assigned to it: A dialog appears: "Delete '[Category Name]'? X receipts in this category will be moved to 'Other'." with "Delete" and "Cancel."

The user taps "Delete."

The system:
1. Deletes the category from the local database.
2. Reassigns all receipts in this category to "Other" (the default catch-all category).
3. Queues the update for cloud sync.

A confirmation is shown: "Category deleted. X receipts moved to 'Other'."

---

**Edge Cases:**

- User tries to delete a default category: The delete button is not shown for default categories. This action is not possible.
- User creates a category offline and the same name is created on another device: On sync, the category merger detects the duplicate and keeps one instance. Receipts from both devices are assigned to the merged category.
- Maximum categories reached (50 custom): The "Add Category" button is disabled with a note: "Maximum of 50 custom categories reached."

---

### UF-15: Account Deletion

**Related Features**: F-015, F-010, F-008

**Trigger**: User wants to permanently delete their account and all associated data.

**Preconditions**: User is logged in. An internet connection is available (required to delete cloud data and Cognito account).

---

**Step 1: Navigate to Account Deletion**

The user taps "Settings" in the bottom navigation. On the **Settings Screen**, the user scrolls to the bottom and taps "Delete Account" (displayed in red text).

---

**Step 2: First Confirmation**

The **Account Deletion Screen** displays a detailed explanation:

- **Heading**: "Delete Your Account"
- **Body**: "Deleting your account will permanently remove ALL of your data. This action CANNOT be undone."
- **What will be deleted** (bulleted list):
  - Your user account and login credentials
  - All receipt records and metadata
  - All receipt images
  - All warranty tracking data
  - All notification settings and schedules
  - All custom categories
- **Data deletion scope**:
  - "Cloud data: Will be permanently deleted from our servers."
  - "Device data: Will be permanently removed from this device."
  - "Other devices: Data will be removed from all synced devices on their next connection."
- **Note**: "If you only want to remove cloud data, consider switching to Device Only mode instead (Settings > Storage Mode)."

A "Continue to Delete Account" button (red) and a "Cancel" link are displayed.

The user taps "Continue to Delete Account."

---

**Step 3: Re-Authentication**

For security, the system requires the user to re-authenticate before proceeding with account deletion.

- IF the user signed in with email/password: A password entry field is displayed. The user enters their password and taps "Confirm."
  - IF the password is incorrect: Display "Incorrect password. Please try again."
- IF the user signed in with Google: The Google Sign-In flow is triggered for re-verification.
- IF the user signed in with Apple: The Apple Sign-In flow is triggered for re-verification.

On successful re-authentication, proceed to Step 4.

---

**Step 4: Final Confirmation**

A final confirmation dialog appears. This is deliberately aggressive to prevent accidental deletion:

- **Title**: "This is permanent"
- **Body**: "Type DELETE to confirm account deletion. All receipts, images, and account data will be permanently destroyed."
- **Text input field**: The user must type "DELETE" (case-sensitive).
- **Buttons**: "Delete My Account" (red, disabled until the user types "DELETE") and "Cancel."

The user types "DELETE" and taps "Delete My Account."

- IF the user types anything other than "DELETE": The delete button remains disabled.
- IF the user taps "Cancel" at any point: Return to the Settings Screen. No data is deleted.

---

**Step 5: Deletion Cascade**

The system executes the deletion cascade:

1. **Display a processing screen**: "Deleting your account..." with a progress indicator. The user cannot navigate away during this process.

2. **Cancel all local notifications**: All scheduled warranty reminders are cancelled immediately.

3. **Delete local database**: The Drift/SQLCipher database is wiped entirely — all receipt records, categories, images, thumbnails, search index, and sync state.

4. **Clear secure storage**: All stored tokens, encryption keys, and preferences are removed from flutter_secure_storage.

5. **Send cloud deletion request to the backend**: The API call triggers a Lambda cascade:
   - **Step 5a — Cognito deletion**: The user's Cognito account is deleted (User Pool record removed). This invalidates all sessions across all devices.
   - **Step 5b — DynamoDB deletion**: All items with PK = `USER#<userId>` are scanned and deleted in batches (receipts, categories, sync metadata).
   - **Step 5c — S3 deletion**: All objects in the user's S3 prefix are deleted, including all versions (current and noncurrent) and delete markers. This is a permanent, irrecoverable wipe.
   - **Step 5d — SNS cleanup**: The user's device token and notification subscriptions are removed.

6. **Sign out locally**: The Amplify session is cleared.

---

**Step 6: Completion**

When the deletion cascade completes:

- The processing screen transitions to a farewell screen: "Your account has been deleted. All data has been permanently removed."
- A "Close" button is displayed.
- The user taps "Close." The app navigates to the **Welcome Screen** (first screen of the onboarding flow). The app is now in a clean state as if freshly installed.

---

**Error Handling:**

- **Network error during deletion**: This is a critical scenario. The system handles it as follows:
  1. Local data is deleted regardless (the user initiated deletion, so local wipe proceeds).
  2. The cloud deletion request is queued with a high-priority retry flag.
  3. A local flag is set: "pending_cloud_deletion = true."
  4. The user is shown: "Your account has been deleted from this device. Cloud data deletion is in progress and will complete shortly."
  5. If the user opens the app again before the cloud deletion completes: They are shown the Welcome Screen (cannot log in because local data is wiped). The background task continues attempting cloud deletion.
  6. As a safety net: A server-side cron job (EventBridge + Lambda) checks for stale Cognito accounts with pending deletion flags and completes the cascade.

- **Partial cascade failure** (e.g., Cognito deleted but DynamoDB deletion fails):
  1. The Lambda cascade logs the failure with full details to CloudWatch.
  2. An alarm is triggered for manual investigation.
  3. The Lambda retries the failed step up to 3 times with exponential backoff.
  4. If all retries fail: The item is added to a Dead Letter Queue for manual remediation. This is an operational concern, not a user-facing issue.

- **User on multiple devices**: When the Cognito account is deleted, the refresh token is invalidated. On the next app open on other devices:
  1. The session refresh fails (401 Unauthorized).
  2. The app detects the deleted account and displays: "Your account has been deleted. All local data will now be removed."
  3. The local database on that device is wiped.
  4. The app navigates to the Welcome Screen.

- **Device-only mode user deletes account**: Only the Cognito account and local data are deleted. There is no cloud data to clean up. The deletion is simpler and faster.

---

*End of User Flows*
