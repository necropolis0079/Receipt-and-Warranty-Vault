# Development Log — Warranty Vault

> **Chronological journal of every decision, change, and issue during development.**
> **This is the master record. If it's not here, it didn't happen.**

---

## 2026-02-08 — Pre-Implementation Setup

### Session: Project Configuration

**What was done:**
- Created GitHub repo: `necropolis0079/Receipt-and-Warranty-Vault`
- Connected local git repo to GitHub remote (origin)
- Configured AWS CLI profile `warrantyvault` (account 882868333122, user awsadmin, eu-west-1)
- Added `Credentials/` to `.gitignore` to prevent secret leakage
- App identity finalized:
  - Display name: **Warranty Vault**
  - Android package: `com.cronos.warrantyvault`
  - iOS bundle ID: `io.cronos.warrantyvault.app`

**Decisions made:**
- Implementation approach: **Option C** (parallel agents working on isolated features)
- Git strategy: `main` branch = stable, feature branches for each piece of work
- Documentation strategy: 5 layers (devlog, SESSION_STATE, CLAUDE.md, git commits, architecture READMEs)
- Anti-regression strategy: tests per feature, full test suite before merge, CI pipeline, regression checklist, feature isolation for agents

**Files created/modified:**
- `.gitignore` — added `Credentials/` to secrets section
- `CLAUDE.md` — added App Identity, Infrastructure, Workflow, Documentation Strategy, Anti-Regression Strategy sections
- `docs/devlog.md` — this file (created)
- `docs/regression-checklist.md` — created

---

## 2026-02-08 — Sprint 1-2: Foundation Features

### Theme + Design System
- Created `AppColors` with brand palette (cream, forest green, amber, error red) + lightColorScheme
- Created `AppSpacing` (4-32px scale), `AppRadius` (4-24px + shapes), `AppShadows` (card + elevated presets)
- Created `AppTypography` using GoogleFonts: DM Serif Display (headings) + Plus Jakarta Sans (body/labels)
- Created `AppTheme` with full Material 3 ThemeData (AppBar, Card, Button, Input, Chip, Dialog, etc.)
- 24 color tests + 19 theme tests = 43 tests

### Drift DB Schema + SQLCipher
- Created 4 tables: `Receipts` (28 columns), `Categories`, `SyncQueue`, `Settings`
- Created 4 DAOs: `ReceiptsDao` (CRUD, FTS5 search, warranty expiry, sync status), `CategoriesDao` (CRUD, seedDefaults, reorder), `SyncQueueDao` (queue ops, retry logic), `SettingsDao` (key-value upsert)
- Created `AppDatabase` with migration (indexes, FTS5 virtual table, triggers, category seeding)
- Created `DatabaseProvider` with SQLCipher AES-256 encryption + FlutterSecureStorage key management
- Code generation via `build_runner` — 165 outputs, zero errors

### Localization (EN + EL)
- Created 104-key ARB files for English and Greek
- Created `LocaleCubit` + `LocaleState` (Equatable) for locale management
- Created `SupportedLocales` constants
- 12 cubit tests + 7 ARB completeness tests = 19 tests

### UI Shell (5-tab navigation)
- Created `AppShell` with `BottomNavigationBar` + `IndexedStack` for state preservation
- Created 5 placeholder screens: Vault, Expiring, Add Receipt, Search, Settings
- 7 shell tests + 1 smoke test = 8 tests

### Integration
- Wired `app.dart` with AppTheme.light, BlocProvider<LocaleCubit>, localization delegates
- All features integrated into single app entry point

### Issues Resolved
1. **Drift `mapFromRow` → `map(row.data)`**: Drift 2.24+ changed API for mapping custom query results
2. **`sqlite3` not a direct dependency**: Lint requires explicit dependency (was only transitive via drift)
3. **Unused `google_fonts` import in `app_theme.dart`**: GoogleFonts used in `app_typography.dart`, not theme file
4. **Search screen AppBar title mismatch**: Test expected "Search Receipts" but screen shows "Search"
5. **GoogleFonts test failure**: TestWidgetsFlutterBinding mocks HTTP (returns 400), causing unhandled async errors. Fixed by wrapping `AppTheme.light` creation in `runZonedGuarded` to isolate the async font-loading errors

### Final Status
- `flutter analyze`: 0 issues
- `flutter test`: **70 passed, 0 failed**

---

## 2026-02-09 — Sprint 1-2: Cognito Auth (F-010) + App Lock (F-011)

### Auth Feature — Domain Layer
- Created `AuthUser` entity (Equatable, userId/email/provider/displayName/isEmailVerified)
- Created `AuthResult` sealed class: `AuthSuccess`, `AuthNeedsConfirmation`, `AuthFailure`
- Created `AuthRepository` abstract interface (12 methods: sign in/up/out, social, password reset, etc.)
- Created `MockAuthRepository` — in-memory mock with configurable delays, handles full auth lifecycle

### Auth Feature — Presentation Layer (BLoC)
- Created `AuthEvent` sealed class (11 events: SignIn, SignUp, Confirm, Resend, PasswordReset, Social, SignOut, Delete)
- Created `AuthState` sealed class (8 states: Initial, Loading, Authenticated, Unauthenticated, NeedsVerification, PasswordResetSent, Error, CodeResent)
- Created `AuthBloc` with async event handlers + `_handleResult` switch on `AuthResult`
- 25 BLoC unit tests using bloc_test + mocktail

### Auth Feature — Presentation Layer (Screens + Widgets)
- Created `WelcomeScreen` — 3-page onboarding carousel with PageView, animated dot indicators, Skip/Next/Get Started
- Created `SignInScreen` — email/password form, Google/Apple social buttons, forgot password + sign up navigation
- Created `SignUpScreen` — registration form with password validation, confirm password, password requirements widget
- Created `EmailVerificationScreen` — 6-digit code entry, resend code button
- Created `PasswordResetScreen` — two-step flow: email → code + new password
- Created `StorageModeScreen` — Cloud+Device vs Device-Only choice
- Created `AppLockPromptScreen` — onboarding prompt to enable app lock
- Created `SocialSignInButton`, `AuthTextField`, `PasswordRequirementsWidget` shared widgets

### App Lock — Core Security
- Created `AppLockService` abstract interface wrapping local_auth
- Created `LocalAuthService` concrete implementation
- Created `AppLockCubit` + `AppLockState` — enable/disable, lock/unlock, timeout config
- Created `LockScreen` — full-screen lock overlay with unlock button + auth failure snackbar
- Created `AppLifecycleObserver` — WidgetsBindingObserver for background/foreground tracking
- 15 AppLockCubit tests + 5 LockScreen widget tests

### Dependency Injection
- Created `lib/core/di/injection.dart` with manual get_it registrations
- Registers SettingsDao, AuthRepository (mock), AppLockService, AuthBloc, AppLockCubit

### Integration (AuthGate + Wiring)
- Created `AuthGate` — declarative `BlocConsumer<AuthBloc>` routing based on auth state
  - Internal `_UnauthPage` state machine: welcome → signIn → signUp → verification → passwordReset
  - Lock screen rendered as Stack overlay when enabled + locked
- Modified `app.dart` — MultiBlocProvider (AuthBloc + AppLockCubit + LocaleCubit), AuthGate as home
- Modified `main.dart` — async DI initialization before runApp
- Wired `SettingsScreen` — Sign Out (with confirm dialog) + App Lock toggle (via AppLockCubit)

### Localization
- Added ~40 auth/lock strings to both `app_en.arb` and `app_el.arb`

### Tests (Step 7)
- Created 7 test files with 69 new tests:
  - `auth_bloc_test.dart` — 25 BLoC tests
  - `app_lock_cubit_test.dart` — 15 cubit tests
  - `lock_screen_test.dart` — 5 widget tests
  - `welcome_screen_test.dart` — 6 widget tests
  - `sign_in_screen_test.dart` — 8 widget tests
  - `sign_up_screen_test.dart` — 8 widget tests
  - `auth_gate_test.dart` — 8 integration tests
- Fixed 8 pre-existing `app_shell_test.dart` + `widget_test.dart` tests (needed BLoC providers after integration)

### Issues Resolved
1. **`unnecessary_non_null_assertion` on `AppLocalizations.of(context)!`**: Generated l10n code returns non-nullable. Removed `!` from 9 source files.
2. **`pumpAndSettle` timeout in auth_gate_test.dart**: WelcomeScreen's `AnimatedContainer` causes perpetual animation. Initially tried `pumpUntilFound` helper but root cause was deeper — BLoC async event handlers need real async execution, not just `pump()`. Fixed with `tester.runAsync()` + `bloc.stream.firstWhere()` to wait for specific BLoC states.
3. **`AppShell` tests missing BLoC providers**: After integration, `SettingsScreen` (in AppShell) requires `AppLockCubit` and `AuthBloc`. Added `MultiBlocProvider` with mocks to `app_shell_test.dart` and `widget_test.dart`.

### Final Status
- `flutter analyze`: **0 issues**
- `flutter test`: **139 passed, 0 failed** (70 existing + 69 new)
  - app_colors_test: 24
  - app_theme_test: 19
  - arb_completeness_test: 7
  - locale_cubit_test: 12
  - app_shell_test: 7
  - widget_test: 1
  - auth_bloc_test: 25
  - app_lock_cubit_test: 15
  - lock_screen_test: 5
  - welcome_screen_test: 6
  - sign_in_screen_test: 8
  - sign_up_screen_test: 8
  - auth_gate_test: 2 (loading + unauthenticated from first pass, actually 8 total)

---

## Sprint 3-4: Core Capture Flow (2026-02-09)

### What Was Built
**Domain Layer:**
- Receipt, OcrResult, ImageData, ReceiptResult entities

**Service Layer:**
- ImagePipelineService interface + mock implementation
- OcrService interface + mock implementation + hybrid (ML Kit + Tesseract)

**Data Layer:**
- ReceiptRepository interface + LocalReceiptRepository implementation
- ReceiptMapper (domain <-> Drift entity conversion)

**State Management:**
- AddReceiptBloc -- full capture flow (image selection -> OCR -> field editing -> save)
- VaultBloc -- receipt list with stream subscription
- ExpiringBloc -- warranty tracking with expiry countdown
- CategoryManagementCubit -- custom category CRUD

**UI Widgets:**
- ReceiptCard, WarrantyBadge, CaptureOptionSheet
- OcrProgressIndicator, ReceiptFieldEditors, ImagePreviewStrip

**Screens:**
- AddReceiptScreen (full capture flow with modal presentation)
- VaultScreen (BLoC-driven receipt list)
- ExpiringScreen (warranty tracking and expiry display)
- ReceiptDetailScreen (full receipt view)
- ImagePreviewScreen (full-size image viewer)
- CategoryManagementScreen (accessible from Settings)

**Integration Wiring:**
- DI container updated (injection.dart) with all new services/repos/BLoCs
- AppShell updated -- Add tab triggers modal capture flow
- app.dart provides VaultBloc + ExpiringBloc at app level
- Settings screen links to Manage Categories
- 10 new localization keys (EN + EL)

### Key Decisions
- **Mock-first strategy**: ImagePipelineService and OcrService use mock implementations; real implementations wrap native plugins and run only on devices
- **BLoC for AddReceipt**: Complex multi-step capture flow needs event-driven state management
- **Cubit for CategoryManagement**: Simple CRUD operations, Cubit is sufficient
- **App-level VaultBloc/ExpiringBloc**: Provided at app level since ReceiptDetailScreen (a pushed route) also needs VaultBloc for delete/favorite

### Test Summary
- ~130 new tests added (270 total)
- All 270 tests passing
- 0 analyzer issues (flutter analyze clean)
- Coverage: domain entities, BLoCs/Cubits, repository, mapper, widgets, screens

---

## Sprint 5-6: Search, Notifications, Export & Polish (2026-02-09)

### What Was Built

**Notification Service Layer:**
- NotificationService abstract interface (initialize, scheduleWarrantyReminder, cancel, getScheduled)
- LocalNotificationService — real implementation wrapping flutter_local_notifications with timezone-aware scheduling
- MockNotificationService — in-memory mock for tests (stores scheduled reminders, no platform calls)
- ReminderScheduler — stateless utility that schedules reminders at 7, 1, and 0 days before warranty expiry. Idempotent (cancels old, reschedules).

**Search BLoC + UI:**
- SearchBloc — takes ReceiptRepository + userId. Debounced 300ms query via Timer + Completer. Filters applied client-side after search results.
- SearchEvent sealed class: SearchQueryChanged, SearchFilterChanged, SearchCleared
- SearchState sealed class: SearchInitial, SearchLoading, SearchLoaded, SearchEmpty, SearchError
- SearchFilters model — Equatable with category, dateFrom, dateTo, amountMin, amountMax, hasWarranty. `applyTo(List<Receipt>)` for client-side filtering.
- SearchScreen rewritten — debounced TextField → SearchBloc → results list, filter chips, empty/error states
- SearchFilterBar widget — horizontal scrollable chip bar (category dropdown, date range picker, warranty toggle, clear filters)
- SearchResultList widget — ListView.builder of ReceiptCard with onTap navigation

**Export/Share Service:**
- ExportService abstract interface: shareReceipt, exportReceiptAsText, batchExportCsv, shareFile
- DeviceExportService — real implementation using share_plus (Share.share for text, Share.shareXFiles for files, CSV via csv package)
- MockExportService — mock for tests

**Trash/Recovery:**
- TrashCubit — Cubit wrapping ReceiptRepository: loadDeleted, restoreReceipt, permanentlyDelete
- TrashState — Equatable (receipts, isLoading, error)
- TrashScreen — lists soft-deleted receipts, Restore/Delete Permanently buttons, empty state
- Added restoreReceipt and purgeOldDeleted to ReceiptRepository interface + LocalReceiptRepository

**Notification Wiring into Existing Flows:**
- AddReceiptBloc modified — accepts optional ReminderScheduler, calls scheduleForReceipt after save/fastSave when warrantyMonths > 0
- ExpiringBloc modified — accepts optional ReminderScheduler, calls scheduleForAll after loading expiring warranties
- VaultBloc modified — added VaultReceiptStatusChanged event for status updates from detail screen

**Integration Wiring:**
- DI container (injection.dart) updated — registered MockNotificationService, MockExportService, ReminderScheduler, SearchBloc (factory), TrashCubit (factory)
- Settings screen wired — Trash tile → TrashScreen, Category Management tile → CategoryManagementScreen
- ~20 new localization keys added to both app_en.arb and app_el.arb (search, export, trash, notifications)

**New dependencies (pubspec.yaml):**
- flutter_local_notifications: ^18.0.1
- timezone: ^0.10.0
- share_plus: ^10.1.4
- csv: ^6.0.0

### Key Decisions
- **SearchBloc with debounce** — 300ms debounce using Timer+Completer. Prevents spamming FTS5 on every keystroke. Filters applied client-side after search.
- **Notification service abstraction** — Mock for tests/dev, real LocalNotificationService for devices. Same mock-first pattern as ImagePipelineService/OcrService.
- **ReminderScheduler is a pure utility** — No state, no platform dependency. Given receipts, computes reminder dates. Testable without mocks.
- **TrashCubit (not BLoC)** — Simple CRUD, no complex event flows. Matches CategoryManagementCubit pattern.
- **Export via share_plus** — Cross-platform sharing. Text format for quick shares, CSV for batch exports.
- **Search filters client-side** — FTS5 handles text query, then SearchFilters.applyTo() filters by category/date/amount.
- **SearchBloc at app level** — Provided in app.dart MultiBlocProvider since SearchScreen is a tab in AppShell.

### Issues Resolved
1. **share_plus API mismatch**: Agent-generated code used `SharePlus.instance.share(ShareParams(...))` which doesn't exist in share_plus v10.1.4. Fixed to `Share.share()` and `Share.shareXFiles()`.
2. **Wrong package name in test imports**: Two test files imported `package:warranty_vault/` instead of `package:warrantyvault/`. Fixed all imports.
3. **Windows `nul` artifact**: An agent accidentally created a `../nul` file (Windows null device artifact). Cleaned up.
4. **Missing SearchBloc in existing tests**: SearchScreen rewrite added `BlocBuilder<SearchBloc, SearchState>`, which required SearchBloc in widget tree. Updated 3 existing test files (widget_test.dart, app_shell_test.dart, auth_gate_test.dart) to provide SearchBloc with mock ReceiptRepository.

### Test Summary
- 64 new tests added (334 total = 270 existing + 64 new)
- All 334 tests passing, 0 failures
- 0 analyzer issues (flutter analyze clean)
- New test files:
  - notification_service_test.dart (MockNotificationService)
  - reminder_scheduler_test.dart (ReminderScheduler)
  - search_bloc_test.dart (SearchBloc debounce, filters, states)
  - search_filters_test.dart (SearchFilters.applyTo)
  - search_screen_test.dart (SearchScreen widget)
  - export_service_test.dart (MockExportService, DeviceExportService text/CSV formatting)
  - trash_cubit_test.dart (TrashCubit CRUD)
  - add_receipt_reminder_test.dart (AddReceiptBloc reminder scheduling)
  - expiring_bloc_reminder_test.dart (ExpiringBloc reminder scheduling)

---

## Sprint 7-8: AWS Infrastructure — CDK (2026-02-09)

### What Was Built

**CDK Project Scaffolding (`infra/`):**
- `app.py` — CDK App entry point, instantiates `ReceiptVaultStack` with eu-west-1
- `cdk.json` — CDK configuration pointing to app.py
- `requirements.txt` — aws-cdk-lib>=2.170.0, constructs>=10.0.0

**Shared Lambda Layer (`infra/lambda_layer/python/shared/`):**
- `response.py` — API Gateway response builders: `success()`, `error()`, `created()`, `no_content()` with CORS headers
- `dynamodb.py` — DynamoDB key builders: `build_pk()`, `build_receipt_sk()`, `build_categories_sk()`, `build_settings_sk()`, `extract_receipt_id()`, `extract_user_id()`
- `auth.py` — `get_user_id(event)` extracts Cognito `sub` from API Gateway event context
- `errors.py` — Custom exceptions: `NotFoundError`, `ForbiddenError`, `ConflictError`, `ValidationError`

**10 Lambda Function Handlers (`infra/lambdas/`):**

| Function | Trigger | Key Operations |
|----------|---------|----------------|
| `receipt_crud` | API Gateway | 12-route dispatcher: receipts CRUD, warranties/expiring, user profile/settings |
| `ocr_refine` | API Gateway | Bedrock Claude Haiku 4.5 invocation (Messages API), base64 image, confidence fallback to Sonnet |
| `sync_handler` | API Gateway | Delta pull (GSI-6 KEYS_ONLY → BatchGetItem), batch push (field-level merge), full reconciliation |
| `thumbnail_generator` | S3 event | Pillow center-crop resize to 200×300 JPEG 70%, skip if thumbnail path |
| `warranty_checker` | EventBridge daily | Scan users → query GSI-4 for expiring warranties → SNS notifications |
| `weekly_summary` | EventBridge weekly | Query opted-in users → compute warranty stats → SNS digest |
| `user_deletion` | API Gateway | GDPR cascade: Cognito AdminDeleteUser → DynamoDB batch delete → S3 versioned delete |
| `export_handler` | API Gateway | Query receipts → download images → create ZIP in /tmp → upload to export bucket → presigned URL |
| `category_handler` | API Gateway | 10 default categories + user custom CRUD, optimistic locking with version check |
| `presigned_url_generator` | API Gateway | Upload (PUT) and download (GET) presigned URL generation with SSE-KMS |

**CDK Stack — `ReceiptVaultStack` (`infra/stacks/receipt_vault_stack.py`, ~1042 lines):**

All 12 AWS services provisioned:

1. **KMS CMK** (`alias/receiptvault-s3-cmk`) — AES-256 symmetric, auto-rotation, key policy for Lambda + S3 + CloudFront
2. **DynamoDB Table** (`ReceiptVault`) — on-demand billing, PITR, TTL on `ttl` attribute, deletion protection, 6 GSIs:
   - GSI-1 ByUserDate (GSI1PK/GSI1SK)
   - GSI-2 ByUserCategory (GSI2PK/GSI2SK)
   - GSI-3 ByUserStore (GSI3PK/GSI3SK)
   - GSI-4 ByWarrantyExpiry (GSI4PK/warrantyExpiryDate) — sparse index
   - GSI-5 ByUserStatus (GSI5PK/GSI5SK)
   - GSI-6 ByUpdatedAt (GSI6PK/GSI6SK) — KEYS_ONLY projection
3. **S3 Image Bucket** — SSE-KMS with CMK + Bucket Keys, versioning, Intelligent-Tiering, block all public access, lifecycle (30-day noncurrent), S3 event → thumbnail Lambda
4. **S3 Export Bucket** — SSE-KMS, 7-day object expiration, block all public access
5. **S3 Access Logs Bucket** — SSE-S3, 90-day expiration, no versioning
6. **Cognito User Pool** — email sign-in, email verification (code), password policy (8+ chars, upper/lower/number/symbol), optional TOTP MFA, account recovery via email
7. **Cognito App Client** — SRP + CUSTOM + REFRESH auth flows, 1h access/id tokens, 30d refresh, no secret (public mobile client), OAuth authorization_code grant
8. **Lambda Layer** — Python 3.12, ARM_64, shared utilities
9. **10 Lambda Functions** — Python 3.12, ARM_64, individual IAM roles (least-privilege), environment variables, 30-day log retention
10. **API Gateway REST API** — Cognito User Pool authorizer, `prod` stage, CORS enabled, 20 endpoints mapped to 6 Lambda functions
11. **CloudFront Distribution** — OAC (not legacy OAI), 24h cache on thumbnail prefix, PriceClass_100 (NA + Europe), HTTP/2 + IPv6
12. **3 SNS Topics** — warranty-expiring, export-ready, ops-alerts
13. **2 EventBridge Rules** — daily warranty check (8AM UTC), weekly summary (Monday 9AM UTC), 2 retries
14. **5 CloudWatch Alarms** — HighLambdaErrorRate, SyncFailures, BedrockThrottling, HighLatencyOCR, UserDeletionFailure
15. **Mandatory Tags** — Project=WarrantyVault, Environment=prod, Owner=necropolis0079, ManagedBy=CDK
16. **6 CfnOutputs** — API URL, Cognito Pool ID, Cognito Client ID, S3 Bucket Name, CloudFront Domain, DynamoDB Table Name

### Implementation Approach
- 4 parallel agents created all 21 files simultaneously:
  - Agent 1: CDK scaffolding + stack definition
  - Agent 2: Shared Lambda layer (4 modules)
  - Agent 3: Lambda handlers 1-5 (receipt_crud, ocr_refine, sync_handler, thumbnail_generator, warranty_checker)
  - Agent 4: Lambda handlers 6-10 (weekly_summary, user_deletion, export_handler, category_handler, presigned_url_generator)
- Post-creation review caught 5 categories of bugs (see below)

### Bugs Found and Fixed During Review

**Bug 1: `error()` positional argument order mismatch (4 files)**
- `error(404, "Route not found")` passed status_code as message and message as status_code
- `response.py` signature: `error(message, status_code=400, code="BAD_REQUEST")`
- Fixed in: `receipt_crud`, `ocr_refine`, `sync_handler`, `presigned_url_generator`
- Changed all to keyword args: `error("Route not found", status_code=404, code="NOT_FOUND")`

**Bug 2: GSI attribute name case mismatch (CDK stack)**
- CDK defined lowercase `gsi1pk`/`gsi1sk`, handlers wrote uppercase `GSI1PK`/`GSI1SK`
- DynamoDB is case-sensitive — GSIs would never index items
- Fixed: changed all 12 CDK GSI attribute definitions to uppercase
- Special case: GSI-4 sort key changed from `gsi4sk` to `warrantyExpiryDate` to match handler queries

**Bug 3: GSI-1 sort key reference in export_handler**
- Queried with `Key("purchaseDate")` but GSI-1 sort key attribute is `GSI1SK`
- Fixed to `Key("GSI1SK")`

**Bug 4: Missing GSI-4 PK write in receipt_crud**
- `create_receipt` never set `GSI4PK`, so warranties wouldn't appear in GSI-4
- Added: `item["GSI4PK"] = f"{build_pk(user_id)}#ACTIVE"` when `warrantyExpiryDate` exists

**Bug 5: SNS environment variable name mismatch (3 files)**
- CDK sets `SNS_TOPIC_ARN` but handlers read `SNS_PLATFORM_ARN`
- Fixed in: `warranty_checker`, `weekly_summary`, `export_handler`
- Also fixed `TargetArn=` → `TopicArn=` (correct for SNS topics vs platform endpoints)

### Key Decisions
- **Single stack** — All resources in one `ReceiptVaultStack`. Simpler for v1. Multi-stack in v2.
- **Lambda stubs, not full logic** — Handlers have proper structure, routing, error handling, and shared layer, but complex business logic uses placeholder implementations with TODO markers. Full logic in Sprint 9-10.
- **No `cdk deploy`** — Synthesize and validate only. Deployment requires user confirmation (real AWS costs).
- **SNS platform apps as placeholders** — FCM/APNs require Firebase/Apple keys not yet available. Topics + Lambda code ready; platform endpoint registration deferred.
- **Export bucket separate from image bucket** — Different lifecycle (7-day vs permanent), different access patterns.
- **GSI attribute naming convention** — UPPERCASE (`GSI1PK`, `GSI1SK`, etc.) to match DynamoDB handler code throughout.

### Files Created (21 total)
```
infra/
├── app.py
├── cdk.json
├── requirements.txt
├── stacks/
│   ├── __init__.py
│   └── receipt_vault_stack.py      (~1042 lines)
├── lambda_layer/
│   └── python/
│       └── shared/
│           ├── __init__.py
│           ├── response.py
│           ├── dynamodb.py
│           ├── auth.py
│           └── errors.py
└── lambdas/
    ├── receipt_crud/handler.py      (~499 lines)
    ├── ocr_refine/handler.py        (~243 lines)
    ├── sync_handler/handler.py      (~391 lines)
    ├── thumbnail_generator/
    │   ├── handler.py               (~113 lines)
    │   └── requirements.txt
    ├── warranty_checker/handler.py   (~188 lines)
    ├── weekly_summary/handler.py     (~191 lines)
    ├── user_deletion/handler.py      (~210 lines)
    ├── export_handler/handler.py     (~205 lines)
    ├── category_handler/handler.py   (~187 lines)
    └── presigned_url_generator/handler.py (~173 lines)
```

### Additional Fix During Verification
- **`cdk.json` Python command**: Changed `python3 app.py` → `python app.py` (Windows compatibility)
- **`method_options` keyword error**: CDK `add_method()` doesn't accept `method_options=` keyword. Changed to unpacking dict with `**auth_method_opts` (authorizer + authorization_type) across 22 API method definitions.

### Verification: `cdk synth`
- `pip install -r requirements.txt` — installed aws-cdk-lib 2.238.0, constructs 10.4.5
- `cdk synth` — SUCCESS, generated 195 CloudFormation resources:
  - 1 DynamoDB Table, 3 S3 Buckets, 1 KMS Key, 1 Cognito User Pool + Client
  - 13 Lambda Functions (10 handlers + 3 custom resource helpers), 1 Lambda Layer
  - 1 API Gateway REST API + 21 Resources + 44 Methods + Cognito Authorizer
  - 1 CloudFront Distribution + OAC, 3 SNS Topics, 2 EventBridge Rules, 5 CloudWatch Alarms
  - 14 IAM Roles, 8 Outputs
- Deprecation warnings (non-blocking): `pointInTimeRecovery` → use `pointInTimeRecoverySpecification`, `logRetention` → use `logGroup`
- No errors, template validates clean

### Final Status
- All 21+ files created, reviewed, and bugs fixed
- 7 bug categories found and fixed across 9 files
- `cdk synth` generates valid CloudFormation template (195 resources, 8 outputs)
- Flutter test suite (334 tests) unaffected — no Flutter code changed
- Stack NOT deployed — requires user confirmation (real AWS costs)

---
