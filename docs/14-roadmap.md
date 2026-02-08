# 14 -- Roadmap

**Document**: Project Roadmap
**Version**: 1.0
**Status**: Pre-Implementation (Documentation Phase)
**Last Updated**: 2026-02-08

---

## Table of Contents

1. [Version History and Planning](#version-history-and-planning)
2. [Pre-Development Phase](#pre-development-phase-current--february-2026)
3. [v1.0 -- Core MVP](#v10--core-mvp-target-3-4-months-from-dev-start)
4. [v1.5 -- Polish and Smart Features](#v15--polish-and-smart-features-target-2-months-after-v10)
5. [v2.0 -- Growth](#v20--growth-target-4-months-after-v15)
6. [v3.0 -- Platform (Future Vision)](#v30--platform-future-vision)
7. [Risk Register](#risk-register)
8. [Success Metrics](#success-metrics)

---

## Version History and Planning

Receipt & Warranty Vault follows a deliberate, phased development approach. Each version has a clear scope, a defined audience, and explicit release criteria that must be met before moving forward. The philosophy is to build the smallest useful product first (v1.0 for 5 testers), validate it with real daily usage, and then expand scope based on evidence -- not assumptions.

The sprint structure assumes two-week sprints with a small development team. Sprint boundaries are approximate; the actual pace will be determined by implementation complexity and any unforeseen technical challenges. The priority is always quality over speed: no feature ships until it meets its acceptance criteria, and no version ships with known data loss risks.

---

## Pre-Development Phase (Current -- February 2026)

This phase is nearly complete. Its purpose is to make every meaningful product and technical decision before writing any application code, so that the implementation phase is focused and efficient.

- [x] **Concept definition and Devil's Advocate review.** The product concept was defined, challenged, and refined. Every feature was scrutinized for necessity, feasibility, and scope appropriateness. Features that did not pass the challenge (email forwarding, shared vault, natural language search, auto-archiving without user approval) were explicitly deferred to later versions.

- [x] **Technical architecture decisions (all researched).** Every major technical choice -- framework, database, cloud infrastructure, LLM, OCR, sync engine, authentication, encryption, image pipeline -- was individually researched, alternatives were compared, and a final decision was documented with rationale. No major technical decisions remain open for v1.

- [x] **Visual mockup created and approved.** A complete visual mockup of the app's primary screens was built and reviewed. The design direction (warm cream palette, forest green accents, card-based layout, DM Serif Display headings, Plus Jakarta Sans body text) was approved. The mockup serves as the visual reference for all implementation work.

- [x] **Full documentation suite created.** Fourteen documentation files covering every aspect of the project -- from project overview and user personas through feature specifications, data models, API design, AWS infrastructure, security, sync architecture, LLM integration, deployment strategy, testing strategy, and this roadmap -- have been written and reviewed.

- [ ] **Review documentation with team.** All documentation files must be read and discussed by the full development team. Questions, concerns, and suggestions are captured. Any changes require explicit approval (per the project's change control process documented in CLAUDE.md).

- [ ] **Set up development environment.** Install Flutter SDK, configure Android Studio and Xcode, set up AWS CLI with staging credentials, configure Amplify Gen 2 project, verify all toolchain dependencies (Dart, Python 3.12, CDK/SAM, Docker for local Lambda testing).

- [ ] **Create repository and project structure.** Initialize the Git repository with the agreed-upon branch strategy. Create the Flutter project with the clean architecture directory structure (presentation, business logic, repository, data source layers). Create the AWS infrastructure project (CDK or SAM). Configure .gitignore, linting rules, formatting rules, and code generation tooling.

- [ ] **Set up CI/CD pipeline skeleton.** Configure GitHub Actions workflows for: Flutter lint + test on PR, Flutter build (Android APK + iOS IPA) on merge to main, Lambda packaging + deployment to staging on merge to main. The pipeline does not need to do everything on day one, but the skeleton must exist so that CI/CD grows incrementally alongside the codebase.

---

## v1.0 -- Core MVP (Target: ~3-4 months from dev start)

v1.0 is the Minimum Viable Product -- the smallest version of Receipt & Warranty Vault that delivers the complete core promise (capture, organize, and retrieve receipts with warranty tracking) to 5 internal testers. Every feature in v1.0 has been explicitly prioritized and locked in the CLAUDE.md feature list.

### Sprint 1-2: Foundation

The first two sprints establish the project skeleton, core infrastructure, and the foundational systems that every subsequent feature depends on.

**Flutter project setup with clean architecture (BLoC pattern):**
- Create the directory structure for presentation, business logic, repository, and data source layers.
- Configure flutter_bloc as the state management solution.
- Set up dependency injection (using get_it or a similar service locator, or BlocProvider tree).
- Create placeholder screens for all five bottom navigation tabs (Vault, Expiring, + Add, Search, Settings).

**Drift database schema and SQLCipher encryption:**
- Define the Drift database schema matching the DynamoDB data model (receipts table, categories table, sync_queue table, settings table).
- Integrate sqlcipher_flutter_libs for AES-256 encryption.
- Generate the encryption key on first launch and store it in flutter_secure_storage.
- Implement and test schema migration system for future updates.
- Set up FTS5 virtual table for full-text search (store name, OCR text, notes, tags).

**Basic UI shell:**
- Implement bottom navigation bar with five tabs.
- Create screen scaffolding for each tab with placeholder content.
- Implement navigation transitions between screens.
- Set up the responsive layout foundation (safe areas, system UI overlays).

**Cognito authentication (email/password and social login via Amplify Gen 2):**
- Configure Amplify Gen 2 project with Cognito User Pool.
- Implement sign-up flow (email/password with verification).
- Implement sign-in flow (email/password).
- Implement Google Sign-In and Apple Sign-In via Cognito federation.
- Implement sign-out.
- Implement token management (access, ID, refresh) with automatic refresh.
- Build the AuthBloc/Cubit that manages authentication state.

**App lock (biometric/PIN):**
- Integrate local_auth package for biometric authentication (fingerprint, Face ID).
- Implement PIN fallback for devices without biometric hardware.
- Build the app lock screen that appears on app resume when enabled.
- Store the app lock preference securely.

**Theme setup:**
- Implement the approved color palette (warm cream #FAF7F2, forest green #2D5A3D, amber #D4920B, red #C0392B).
- Configure typography (DM Serif Display for headings, Plus Jakarta Sans for body).
- Build the design system: common widgets, spacing constants, shadow definitions, border radius values.
- Implement light theme (dark theme deferred unless requested).

**Localization framework (English and Greek):**
- Set up Flutter's intl/l10n framework with .arb files for English and Greek.
- Localize all static strings in the UI shell.
- Implement locale switching in settings.
- Verify Greek text rendering (correct font support, correct character display).

### Sprint 3-4: Core Capture

These sprints deliver the heart of the app: the ability to capture a receipt and extract useful data from it.

**Camera capture and gallery import:**
- Integrate image_picker for camera capture and gallery selection.
- Handle permissions (camera, photo library) with graceful prompts and fallbacks.
- Support importing images and PDFs from the device file system.
- Rasterize PDF pages to images for OCR processing.

**Image preprocessing:**
- Integrate image_cropper for user-guided crop and rotation.
- Integrate flutter_image_compress for JPEG 85% compression.
- Implement EXIF GPS stripping (remove location metadata, preserve orientation).
- Build the preprocessing pipeline: capture, crop, compress, strip, save.

**On-device OCR (ML Kit and Tesseract hybrid):**
- Integrate google_mlkit_text_recognition for Latin script and numbers.
- Integrate flutter_tesseract_ocr for Greek script.
- Implement the hybrid merge logic: run both engines in parallel, combine results using confidence-based selection.
- Parse the merged OCR text to extract structured fields: store name, purchase date, total amount.
- Display extracted fields to the user immediately (within 5 seconds of capture).

**Receipt creation flow:**
- Build the AddReceiptBloc with the multi-step capture pipeline.
- Build the receipt creation UI: image preview, extracted field editors (store name, date, total, currency), category selector, warranty toggle and duration input, notes field.
- Implement field validation (date format, amount format, required fields).
- Save the completed receipt to the local Drift database.

**Fast Save flow:**
- Implement a streamlined save path that skips optional fields and saves with whatever OCR extracted.
- The user taps "Fast Save" instead of reviewing every field. Missing or incorrect fields can be edited later.
- This flow is critical for the sub-20-second capture target when the user is standing at a checkout counter.

**Custom categories:**
- Implement 10 default categories (e.g., Groceries, Electronics, Clothing, Home, Health, Dining, Transport, Entertainment, Bills, Other).
- Implement user-created custom categories (create, rename, delete).
- Category selection during receipt creation and editing.
- Store categories in the local Drift database.

**Local storage:**
- Save all receipt data (metadata + image file path) to the encrypted Drift database.
- Implement the full CRUD cycle locally: create, read (list and detail), update, delete (soft).
- Implement the sync_queue table for tracking changes that need to be synced to the cloud.

### Sprint 5-6: AWS Backend

These sprints deploy the cloud infrastructure and connect the mobile app to it.

**CDK infrastructure deployment:**
- Write CDK (or SAM) templates for all AWS resources: Cognito User Pool, API Gateway (REST), Lambda functions, DynamoDB table with GSIs, S3 bucket with encryption and versioning, KMS CMK, CloudFront distribution, SNS platform application, EventBridge rules, SQS DLQ, CloudWatch alarms, IAM roles and policies.
- Deploy to the staging environment in eu-west-1.
- Verify all resources are created correctly and connected.

**Receipt CRUD Lambda functions:**
- Implement the receipt-crud Lambda (Python 3.12) with create, read, update, delete operations.
- Implement input validation using Pydantic.
- Implement authorization (userId from Cognito token context).
- Implement conditional updates (version check for optimistic concurrency).
- Implement soft delete with TTL.
- Write unit tests with moto-mocked DynamoDB.

**Pre-signed URL generation:**
- Implement the upload-url Lambda that generates S3 pre-signed PUT URLs.
- Enforce constraints: content-type image/jpeg, maximum size 10 MB, 10-minute expiry, scoped to user's S3 prefix.
- Write unit tests.

**S3 image upload and download:**
- Implement the client-side upload flow: request pre-signed URL, PUT image to S3, confirm upload.
- Implement the client-side download flow: request image via CloudFront URL.
- Handle upload failures with retry logic.

**Thumbnail generation:**
- Implement the thumbnail-gen Lambda triggered by S3 PUT events on the originals/ prefix.
- Generate 200x300 pixel JPEG thumbnails at 70% quality using Pillow.
- Write thumbnails to the thumbnails/ prefix.
- Write unit tests with moto-mocked S3.

**CloudFront setup:**
- Configure CloudFront distribution with OAC for secure S3 access.
- Set cache behavior (30-day TTL for immutable receipt images).
- Verify that direct S3 access is blocked.

### Sprint 7-8: Cloud Intelligence

These sprints integrate the LLM-powered OCR refinement that elevates receipt extraction from "adequate" to "excellent."

**Bedrock integration (Haiku 4.5 OCR refinement):**
- Implement the ocr-refine Lambda that sends OCR text and receipt images to Bedrock Claude Haiku 4.5.
- Design and optimize the extraction prompt: instruct the model to extract store name, purchase date, total amount, currency, itemized line items, and warranty information. Request structured JSON output with a confidence score.
- Parse the Bedrock response and validate against the expected schema.
- Write the refined fields back to DynamoDB.

**Sonnet 4.5 fallback logic:**
- Implement the fallback: if Haiku's confidence score is below 60, retry the same request with Sonnet 4.5.
- If Sonnet also returns low confidence, mark the receipt as "needs manual review."
- Log fallback events for monitoring (track how often Sonnet is invoked as a cost signal).

**LLM prompt optimization with test corpus:**
- Run the extraction prompt against the OCR test corpus (see testing strategy doc).
- Measure accuracy against ground-truth annotations.
- Iterate on the prompt to improve accuracy for edge cases: Greek receipts, multi-currency receipts, receipts with warranty information embedded in natural language.
- Document the final prompt version and its measured accuracy.

**Receipt refinement pipeline (upload, Bedrock, update):**
- Connect the client to the refinement endpoint: after a receipt is created and its image is uploaded, the client triggers refinement via the API.
- When the Bedrock response arrives, the client applies the refined fields to the local receipt record (respecting conflict resolution tiers).
- Display a subtle "Enhanced by AI" indicator on refined receipts.

### Sprint 9-10: Sync Engine

These sprints build the most complex component in the system: the custom sync engine.

**Custom sync engine (delta sync and full reconciliation):**
- Implement the sync-handler Lambda for server-side sync operations.
- Implement the client-side SyncBloc and SyncRepository.
- Delta sync: the client sends its lastSyncTimestamp, the server returns all items updated since that timestamp (via GSI-6 ByUpdatedAt). The client merges these items with local data.
- Full reconciliation: every 7 days, the client sends a manifest of all local item IDs and versions. The server compares with its state and returns discrepancies. Both sides reconcile.

**Conflict resolution (field-level merge, 3 tiers):**
- Implement the three-tier conflict resolution logic on both client and server:
  - Tier 1 (Server/LLM wins): extracted_merchant_name, extracted_date, extracted_total, ocr_raw_text, llm_confidence.
  - Tier 2 (Client/User wins): user_notes, user_tags, is_favorite.
  - Tier 3 (Client override precedence): display_name, category, warranty_months -- client wins only if the field is in userEditedFields.
- Implement the userEditedFields tracking: when the user edits a Tier 3 field, the field name is added to the userEditedFields array on the receipt record.

**Sync queue management:**
- Implement the sync queue in the local Drift database: enqueue pending changes (create, update, delete), dequeue for processing, mark as completed or failed, retry failed items with backoff.
- Implement batch processing: process up to N items per sync cycle to avoid timeouts.
- Implement priority ordering: deletes before updates before creates (to avoid conflicts from stale data).

**Background sync (WorkManager):**
- Integrate the workmanager package for periodic background sync (every 15 minutes when online).
- Implement constraints: require network connectivity, prefer unmetered network for image uploads.
- Implement the full reconciliation background task (weekly, requires charging).

**Network state detection:**
- Integrate connectivity_plus for network type detection (Wi-Fi, cellular, none).
- Integrate internet_connection_checker_plus for actual internet reachability verification.
- The SyncBloc reacts to network state changes: trigger sync when connectivity is restored, pause sync when connectivity is lost.

**Image sync:**
- Implement the image upload queue: queued separately from metadata sync because images are larger and may require different network conditions (Wi-Fi vs. cellular).
- Implement image download caching: download images from CloudFront on demand, cache locally with LRU eviction.
- Handle partial sync: receipt metadata can be synced even if the image upload fails. The image is retried later.

### Sprint 11-12: Warranties and Notifications

These sprints deliver the hero feature: warranty tracking with smart reminders.

**Warranty tracking UI:**
- Build the warranty countdown display: circular progress indicator showing elapsed percentage, prominent day count, color transitions (green to amber to red).
- Build the "Expiring" tab: list of warranties sorted by urgency (expiring soonest first), grouped by time horizon (expiring this week, this month, this quarter).
- Build warranty status badges on receipt cards: "Active" (green), "Expiring Soon" (amber), "Expired" (red), "No Warranty" (hidden).

**Expiring Soon screen:**
- Dedicated screen accessible from the "Expiring" tab.
- Shows all warranties expiring within 30 days, with countdown and receipt details.
- Tap navigates to the receipt detail screen.
- Empty state when no warranties are expiring soon.

**Local notification scheduling:**
- Integrate flutter_local_notifications.
- When a receipt with warranty information is created or updated, calculate the reminder dates based on user preferences (default: 30 days, 7 days, 1 day before expiry, and on expiry day).
- Schedule local notifications for each reminder date.
- Notifications work entirely offline.
- Handle notification permissions on both iOS (request at onboarding) and Android (post-notification permission on Android 13+).

**SNS push notifications (FCM/APNs):**
- Implement device token registration: when the user signs in, register the device token with the server via a /notifications/register endpoint.
- Implement the server-side notification endpoint that creates an SNS platform endpoint for the device.
- Push notifications serve as a backup to local notifications and cover edge cases (app reinstalled, local notifications cleared).

**EventBridge scheduled jobs:**
- Implement the daily warranty check: EventBridge triggers the warranty-checker Lambda at 08:00 UTC daily. The Lambda queries GSI-4 for warranties expiring within 30 days and sends SNS notifications.
- Implement the weekly summary: EventBridge triggers the weekly-summary Lambda at 09:00 UTC every Monday. The Lambda aggregates stats (total receipts, active warranties, spending this month) and sends a summary notification.

**Home screen widget:**
- Implement a home screen widget for quick receipt capture (tap to open the camera directly).
- Android: use the home_widget package with a standard Android widget.
- iOS: use WidgetKit via the home_widget package.
- The widget shows a "Tap to capture" button and optionally displays the count of expiring warranties.

### Sprint 13-14: Polish and Testing

These sprints complete all remaining v1 features and subject the app to rigorous testing.

**Search and filters:**
- Implement FTS5-powered keyword search across store names, OCR text, notes, and tags.
- Implement filter chips: by category, by store, by date range, by warranty status (active, expiring soon, expired, none), by returned status.
- Implement combined search + filters.
- Implement sort options: by date (newest/oldest), by amount (highest/lowest), by store name (alphabetical).

**Stats display on home screen:**
- Display "X receipts" and "Y in active warranties" on the home screen above the receipt list.
- Calculate stats from the local database for instant display.
- Update dynamically as receipts are added, deleted, or have warranty status changes.

**Export and share:**
- Single receipt export: generate a shareable format (PDF with receipt image and metadata, or image with metadata overlay) and open the system share sheet.
- Batch export by date range: user selects a start and end date, the app packages all matching receipts into a ZIP file (metadata as JSON or CSV, plus all receipt images), and provides the file for download or sharing.
- Integrate with the export-data Lambda for cloud-side batch export if the user is in cloud+device mode.

**Mark as returned:**
- Implement the "Mark as Returned" toggle on the receipt detail screen.
- Returned receipts remain in the vault but are visually distinguished (badge, reduced opacity, or moved to a "Returned" section).
- Filter by returned status in search.

**Soft delete with 30-day recovery:**
- Implement soft delete: when the user deletes a receipt, set status to DELETED and deletedAt to now. The receipt disappears from the main vault list.
- Implement the "Recently Deleted" view (accessible from Settings or a filter) showing soft-deleted receipts with a countdown to permanent deletion.
- Implement restore: user can restore a soft-deleted receipt within 30 days.
- Implement automatic hard delete: after 30 days, DynamoDB TTL removes the item. S3 lifecycle rules remove the image versions.

**Bulk import from gallery (onboarding):**
- During onboarding (or accessible later from Settings), the app scans the user's photo gallery for images that look like receipts (basic heuristic: aspect ratio, text density from a quick ML Kit scan).
- User reviews the suggested images and selects which to import.
- Selected images are processed through the OCR pipeline in batch.
- Progress indicator shows batch import progress.

**Account deletion cascade:**
- Implement the full account deletion flow: user confirms deletion in Settings, the client calls the /user/delete endpoint, the Lambda cascades deletion across Cognito (user account), DynamoDB (all items), and S3 (all objects including all versions).
- The client signs the user out and returns to the welcome screen.
- This is a GDPR requirement (right to erasure).

**Settings screen:**
- Account management: sign out, delete account, change password.
- Storage mode: cloud+device or device-only, with confirmation dialog.
- Language: English or Greek, with immediate UI update.
- Notifications: enable/disable, configure reminder intervals (30d, 7d, 1d, 0d).
- App lock: enable/disable biometric/PIN.
- Data management: export data, clear image cache, view storage usage.
- About: app version, privacy policy link, terms of service link, open-source licenses.

**OCR accuracy testing with receipt corpus:**
- Build the test corpus of 50+ annotated receipt images (as described in the testing strategy).
- Run the full OCR pipeline (on-device and cloud) against the corpus.
- Measure and record accuracy metrics.
- Iterate on Tesseract configuration and Bedrock prompts until accuracy targets are met.

**Sync engine stress testing:**
- Execute all 12 sync test scenarios described in the testing strategy document.
- Run the large offline queue test (100+ items).
- Run the mid-batch failure test.
- Run the full reconciliation test with intentional discrepancies.
- Run the clock skew simulation.
- Verify zero data loss across all scenarios.

**Security audit:**
- Execute all security tests described in the testing strategy document.
- Verify authentication on all endpoints.
- Verify authorization (user isolation).
- Verify input validation.
- Verify pre-signed URL constraints.
- Verify SQLCipher encryption.
- Verify EXIF stripping.

**Performance optimization:**
- Measure all performance targets described in the testing strategy document.
- Optimize any metrics that fail to meet targets.
- Profile and optimize list scrolling (60 fps with 500+ receipts).
- Profile and optimize app startup time (under 3 seconds cold).
- Optimize image loading and caching for smooth scrolling.

### Sprint 15: Beta Release

The final sprint before v1.0 release focuses on real-world validation with the testing team.

**Internal testing with 5 team members:**
- Distribute the app to 5 designated testers (mix of iOS and Android, mix of English and Greek).
- Each tester uses the app daily for real receipt capture and warranty tracking.
- Testers log issues, pain points, and feature requests in a shared tracker.
- Daily or weekly check-ins to discuss feedback.

**Bug fixes from tester feedback:**
- Prioritize and fix all critical and high-severity bugs identified during testing.
- Address UI/UX issues that cause confusion or friction.
- Adjust default settings based on tester preferences.

**Performance monitoring setup:**
- Verify CloudWatch alarms are functioning (Lambda errors, DLQ depth, API latency).
- Monitor AWS costs during the testing period and compare against projections.
- Monitor app crash rates and identify any device-specific issues.

**Privacy policy draft:**
- Draft the privacy policy covering: data collected, how it is processed (including LLM processing with no storage/training), where it is stored (eu-west-1), user rights (export, deletion, storage mode choice), cookie policy (N/A for mobile), contact information.
- Review the privacy policy for GDPR compliance.
- Host the privacy policy at a publicly accessible URL for app store submissions.

### v1.0 Release Criteria

All of the following must be true before v1.0 is declared ready for release:

**Feature completeness:**
- All 20 v1 features (listed in CLAUDE.md) are functional and tested.
- No feature is in a partial or degraded state.

**Quality gates:**
- OCR accuracy exceeds 85% on-device and 95% cloud for clear receipts (measured against the test corpus).
- Sync engine operates reliably with zero data loss across all 12 test scenarios.
- App lock (biometric/PIN) functions correctly on all test devices.
- Both English and Greek localizations are complete, with no untranslated strings, and all strings display correctly.
- All 5 testers have used the app daily for a minimum of 2 consecutive weeks without encountering any critical bugs (defined as: data loss, crash requiring reinstall, security vulnerability, or sync corruption).

**Compliance and legal:**
- Privacy policy is finalized and hosted at a public URL.
- App Store and Play Store listings are prepared (screenshots, description, keywords, age rating, privacy declarations).
- GDPR compliance has been verified (data export works, account deletion cascade works, storage mode choice works).

**Operational readiness:**
- CloudWatch alarms are active and verified.
- DLQ monitoring is in place.
- AWS cost tracking is active with budget alarms set.
- The team knows how to deploy hotfixes to both the mobile app and the backend.

---

## v1.5 -- Polish and Smart Features (Target: ~2 months after v1.0)

v1.5 is the refinement release that adds intelligence and polish based on real-world usage data from v1.0. It is the last version before public launch, so its focus is on making the app feel mature, delightful, and differentiated.

**LLM natural language search:**
- Integrate Bedrock for natural language search queries: "How much did I spend at IKEA last month?" or "Show me all electronics receipts over 100 euros."
- The LLM translates natural language into structured queries (date range, store filter, category filter, amount filter) and returns matching receipts.
- This is a premium feature that may be gated in future freemium tiers.

**Spending insights dashboard:**
- Monthly spending breakdown by category (bar chart or pie chart).
- Monthly spending trend over time (line chart).
- Top stores by spending.
- Average receipt value.
- The dashboard is calculated from local data (no server dependency for display).

**Additional languages:**
- Based on user demand from the testing phase, add one or two additional languages.
- The localization framework from v1 makes adding new languages a translation effort, not an engineering effort.

**Auto-archiving with user approval:**
- Configurable rules for archiving old receipts (e.g., "Archive receipts older than 1 year with no active warranty").
- Auto-archiving is proposed to the user (notification or in-app prompt), never applied silently.
- Archived receipts are moved to an "Archive" section, still searchable but not cluttering the main vault.

**Receipt line item extraction:**
- Extend the Bedrock extraction prompt to parse individual line items from receipts (product name, quantity, unit price).
- Display line items on the receipt detail screen.
- Line items are searchable ("find the receipt where I bought batteries").
- This feature depends on Bedrock accuracy for structured extraction; accuracy for line items will be lower than for top-level fields.

**Performance optimizations based on real usage data:**
- Analyze performance monitoring data from v1.0 usage to identify bottlenecks.
- Optimize the slowest operations (likely: bulk import, large list scrolling, image upload over cellular).
- Reduce cold start time if it exceeds the 3-second target on any test device.

**UI/UX refinements based on tester feedback:**
- Address usability issues surfaced during the v1.0 testing period.
- Refine animations and transitions for a more polished feel.
- Adjust layout and spacing based on how testers actually use the app (e.g., if nobody uses landscape mode, lock to portrait; if testers find the search hard to discover, make it more prominent).

---

## v2.0 -- Growth (Target: ~4 months after v1.5)

v2.0 is the public launch release. It adds features that support growth, multi-user use cases, and revenue generation.

**Email forwarding capture:**
- Each user receives a dedicated email address (e.g., user123@receipts.receiptvault.app).
- Users forward digital receipts (email confirmations, PDF invoices) to this address.
- An AWS SES inbound rule processes the email, extracts attachments, and runs them through the OCR/LLM pipeline.
- The extracted receipt appears in the user's vault automatically.
- This is a high-value feature for digital receipts from online shopping (Amazon, ASOS, etc.).

**Household shared vault:**
- Multi-user vault: a "household" with one owner and one or more members.
- Role-based access: owner has full control, members can add and view receipts but cannot delete or change settings.
- Shared receipts appear in all household members' vaults.
- Sync complexity increases significantly (multi-user conflict resolution, shared vs. personal receipts).
- This was explicitly deferred from v1 due to complexity.

**Return window tracking:**
- Separate from warranty tracking, return windows are shorter (typically 14-30 days) and have different implications.
- The app tracks the return deadline and sends reminders before the window closes.
- This is a natural extension of the warranty hero feature.

**Multi-region deployment:**
- Deploy a second AWS region (e.g., us-east-1 for North American users) to reduce latency.
- Implement data routing based on user's region preference.
- This is only necessary if user growth outside Europe justifies the infrastructure cost.

**Revenue model implementation:**
- Based on v1 learnings and user feedback, implement the chosen revenue model (freemium tiers, subscription, or one-time purchase).
- If freemium: define free tier limits (e.g., 50 receipts, on-device OCR only) and premium features (unlimited receipts, cloud OCR refinement, natural language search, email forwarding).
- Implement in-app purchase or subscription via App Store and Play Store billing APIs.

**Public marketing and launch:**
- Prepare marketing materials: website, app store screenshots, promotional video, social media presence.
- Submit to App Store and Play Store for review.
- Execute a launch plan targeting the initial market (Greece and English-speaking markets).
- Monitor app store reviews and respond to user feedback.

**App Store optimization (ASO):**
- Optimize app store listings: title, subtitle, keywords, description, screenshots, preview video.
- A/B test different screenshots and descriptions to maximize conversion.
- Monitor keyword rankings and adjust.

---

## v3.0 -- Platform (Future Vision)

v3.0 represents the long-term vision for Receipt & Warranty Vault as a comprehensive purchase lifecycle platform. These features are aspirational and will be prioritized based on market reception of v2.0.

**Web companion app:**
- A responsive web application that lets users view, search, and manage their receipt vault from a desktop browser.
- Built with Flutter Web or a separate frontend framework (React, Next.js) depending on performance and UX requirements.
- Read-only initially, with editing capabilities added later.
- Syncs with the same DynamoDB backend as the mobile app.

**Browser extension:**
- A Chrome/Firefox extension that detects receipt emails and online purchase confirmations.
- One-click capture: the extension extracts the receipt data and sends it to the user's vault.
- Particularly valuable for frequent online shoppers.

**Merchant API integration:**
- Partner with retailers to offer automatic receipt import.
- When a user makes a purchase at a partnered retailer (identified by loyalty card or payment method), the receipt is automatically added to the vault.
- This is the ultimate friction reduction: zero-effort capture.
- Requires business development and API partnerships.

**Insurance integration:**
- Connect warranty tracking to insurance providers.
- When a warranted item is damaged, the app can pre-fill a warranty claim form and submit it to the manufacturer or insurance provider.
- This transforms the app from a passive tracker into an active claims assistant.

**Tax assistant:**
- Categorize expenses for tax filing purposes.
- Generate tax-ready expense reports by category, date range, and deductibility.
- Export in formats compatible with local tax software.
- Particularly valuable for freelancers and small business owners.

**Smart budget suggestions:**
- Analyze spending patterns and suggest budgets by category.
- Alert users when they are approaching or exceeding their budget.
- This extends the app's value from "receipt storage" to "financial awareness."

---

## Risk Register

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| **Greek OCR accuracy too low** | Medium | High | Tesseract training data can be optimized with custom Greek receipt vocabulary lists. Bedrock Haiku 4.5 natively supports Greek and serves as a reliable cloud fallback. The user correction flow ensures that even poorly extracted receipts can be fixed manually. If on-device Greek accuracy remains below 70% after optimization, consider a heavier Tesseract model or an alternative on-device OCR engine. |
| **Sync engine data loss** | Low | Critical | The sync engine receives the most thorough testing of any component (12 dedicated test scenarios). Full reconciliation every 7 days serves as a safety net against delta sync drift. The local Drift database is the primary data store, so cloud sync issues never affect local data availability. All sync operations are idempotent, so retries cannot create duplicates. If a critical sync bug is discovered post-launch, sync can be temporarily disabled without affecting core app functionality. |
| **Bedrock not available in eu-west-1** | Medium | Medium | As of the documentation phase, Bedrock availability in eu-west-1 includes the required models. If availability changes, the ocr-refine Lambda can make a cross-region call to a region where Bedrock is available (e.g., us-east-1). The latency increase is acceptable because LLM refinement is asynchronous (the user does not wait for it). Data privacy is maintained because Bedrock does not store input/output data regardless of region. |
| **App Store rejection** | Low | Medium | The app follows all Apple and Google guidelines: no private API usage, proper permission explanations, privacy policy included, age-appropriate content, no misleading claims. Apple's Apple Sign-In requirement is satisfied (offered alongside Google Sign-In). The review process typically takes 1-3 days; budget a week for potential back-and-forth. |
| **User adoption too low** | Medium | High | The v1 strategy intentionally targets only 5 known testers, not the general public. This eliminates adoption risk for v1. The testers are personally invested and have a real need for receipt management. If adoption stalls at the v2 public launch, the product can pivot based on v1 learnings (e.g., focus on a specific niche like electronics warranty tracking rather than general receipt management). |
| **AWS costs exceed budget** | Low | Medium | Cost alarms are set in AWS Budgets. The Haiku-first strategy (Sonnet only as fallback for low-confidence extractions) keeps LLM costs low. DynamoDB on-demand capacity scales proportionally. S3 Intelligent-Tiering automatically reduces storage costs for infrequently accessed images. At 5 users, the total cost is approximately $2/month; at 1,000 users, approximately $88/month. The primary cost driver is Bedrock, which can be rate-limited or batched if costs spike unexpectedly. |
| **ML Kit or Tesseract package deprecation** | Low | Medium | The OCR layer is abstracted behind a Dart interface (OcrEngine) with separate implementations for ML Kit and Tesseract. If either package is deprecated, only the implementation needs to change; no BLoC, repository, or UI code is affected. Alternative OCR packages exist in the Flutter ecosystem, and Bedrock cloud OCR can cover the gap during a transition. |
| **GDPR complaint** | Low | High | GDPR compliance is designed in from the start, not bolted on later. User rights are fully implemented: data export, account deletion with full cascade, storage mode choice (device-only option), and encryption at every layer. Bedrock does not store or train on user data (confirmed by AWS policy). Data residency is eu-west-1 for all users. A privacy policy is drafted before public launch. If a complaint is received, the existing architecture supports full compliance response. |

---

## Success Metrics

### v1.0 (Internal Testing)

These metrics validate that the product works as intended and delivers real value to users.

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Active daily users | 5 out of 5 testers | All testers use the app at least once per day during the 2-week testing period |
| Receipts captured per user in first month | Greater than 50 | Total receipts in each tester's vault after 30 days |
| Average capture time | Under 20 seconds | Measured from tapping "+ Add" to receipt saved, averaged across all captures |
| Zero data loss incidents | 0 incidents | No receipts lost, corrupted, or duplicated during normal usage or sync |
| Warranty reminder acted upon | Greater than 50% of reminders | Tester self-reports that a warranty reminder was useful (led to a warranty claim, informed a purchase decision, or provided peace of mind) |
| On-device OCR accuracy | Greater than 85% for clear receipts | Measured against the test corpus ground truth |
| Cloud OCR accuracy | Greater than 95% for clear receipts | Measured against the test corpus ground truth |
| App crash rate | Below 1% of sessions | Crashes per session across all testers |
| Sync reliability | 100% consistency | No discrepancies between local and cloud data after full reconciliation |

### v1.5 (Pre-Public)

These metrics validate the polish and intelligence features before public launch.

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Natural language search usage | Greater than 60% of users use it at least once per week | Analytics tracking of search queries using the NL search pathway vs. keyword search |
| Spending insights viewed | Weekly by at least 3 of 5 testers | Analytics tracking of dashboard screen views |
| Sync conflict rate | Below 1% of sync operations | Server-side logging of conflict resolution events as a percentage of total sync operations |
| Line item extraction accuracy | Greater than 70% for clear receipts | Measured against annotated corpus with line-item ground truth |
| App stability | Below 0.5% crash rate | Maintained or improved from v1.0 |

### v2.0 (Public Launch)

These metrics validate market viability and operational sustainability.

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Monthly active users (MAU) | 100+ within 3 months of public launch | Cognito MAU count (free tier covers up to 10,000) |
| App store rating | 4.0+ stars (both App Store and Play Store) | Average user rating across both stores |
| Revenue model validated | Positive unit economics | Revenue per user exceeds cost per user (AWS cost approximately $0.09/user/month at 1,000 users) |
| AWS cost at 1,000 users | Under $100 per month | AWS Cost Explorer actual spend vs. projected $88/month |
| Email forwarding adoption | Greater than 30% of active users set up forwarding | Server-side tracking of users with registered forwarding addresses |
| Household vault adoption | Greater than 10% of active users create or join a household | Server-side tracking of household creation events |
| User retention (30-day) | Greater than 40% | Users who return to the app at least once in the 30 days after first use |
| Support volume | Fewer than 5 support requests per 100 MAU per month | Support ticket count (email, in-app feedback) |

---

*This document defines the development roadmap for Receipt & Warranty Vault. For the complete feature list, see [03 - Feature Specification](./03-feature-specification.md). For testing requirements referenced in the sprint plan, see [13 - Testing Strategy](./13-testing-strategy.md). For technical architecture that underpins all sprints, see [05 - Technical Architecture](./05-technical-architecture.md).*
