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

## 2026-02-10 — Sprint 9-10: Sync Engine + Cloud Integration

### Session: Connect Flutter to AWS Backend

**What was done:**

#### Step 1: pubspec.yaml updates
- Added missing packages: `dio`, `connectivity_plus`, `internet_connection_checker_plus`, `workmanager`

#### Step 2: Network Foundation (8 files)
- `core/network/api_config.dart` — API base URL, timeouts, endpoint constants
- `core/network/api_client.dart` — Dio-based HTTP client with interceptor chain
- `core/network/api_exceptions.dart` — Typed exception hierarchy (Offline, AuthExpired, Conflict, NotFound, Validation, Server)
- `core/network/interceptors/auth_interceptor.dart` — Cognito JWT Bearer token injection + 401 refresh
- `core/network/interceptors/connectivity_interceptor.dart` — Pre-flight offline check
- `core/network/interceptors/retry_interceptor.dart` — Exponential backoff for idempotent methods on 5xx
- `core/network/interceptors/logging_interceptor.dart` — Debug-mode request/response logging
- `core/services/connectivity_service.dart` — Two-layer detection (connectivity_plus + DNS probe)

#### Step 3: Remote Data Sources (4 files)
- `features/receipt/data/datasources/receipt_remote_source.dart` — Receipt CRUD + LLM refinement trigger
- `features/receipt/data/datasources/sync_remote_source.dart` — Delta pull, batch push, full reconciliation
- `features/receipt/data/datasources/image_remote_source.dart` — S3 presigned URL workflow
- `features/settings/data/datasources/settings_remote_source.dart` — Categories, profile, settings, export

#### Step 4: Sync Engine (4 files)
- `core/sync/sync_config.dart` — Tuneable constants (15min delta, 7-day full reconciliation, batch size 20)
- `core/sync/conflict_resolver.dart` — 3-tier field-level merge (Server/LLM wins, Client/User wins, Conditional)
- `core/sync/sync_service.dart` — Orchestrator: deltaPull, batchPush, fullReconciliation
- `core/sync/image_sync_service.dart` — S3 upload/download via presigned URLs

#### Step 5: Auth + Config (2 files)
- `features/auth/data/repositories/amplify_auth_repository.dart` — Full production implementation (12 methods)
- `core/config/amplify_config.dart` — Manual Amplify configuration for CDK-deployed Cognito

#### Step 6: SyncBloc + Integration (4 files)
- `features/receipt/presentation/bloc/sync_bloc.dart` — Sync state management
- `features/receipt/presentation/bloc/sync_event.dart` + `sync_state.dart` — Event/state definitions
- `features/receipt/data/repositories/sync_aware_receipt_repository.dart` — Wraps LocalReceiptRepository + SyncService

#### Step 7: DI + Wiring
- `core/di/injection.dart` — Registered all new services, data sources, and factory-param BLoCs
- `core/router/auth_gate.dart` — User-dependent BLoC creation via GetIt (SearchBloc, TrashCubit, SyncBloc)
- `app.dart` — Removed hardcoded userId, moved SearchBloc to AuthGate
- `main.dart` — Added configureAmplify() + initializeBackgroundSync()

#### Step 8: CDK Stack Deployed
- CDK stack deployed to eu-west-1 via `cdk deploy`
- Real outputs captured and wired into config:
  - UserPoolId: `eu-west-1_8vZ07CiUc`
  - AppClientId: `3mlh4a83p6c9c3e1bcftf3obbd`
  - ApiUrl: `https://q1e4rkyf7e.execute-api.eu-west-1.amazonaws.com/prod/`
  - CloudFrontDomain: `d2q7chjw0pm3p3.cloudfront.net`

#### Step 9: Tests (82 new tests)
- `test/core/sync/conflict_resolver_test.dart` — 45 tests (all 3 tiers, version merge, field union, null fallbacks)
- `test/features/receipt/presentation/bloc/sync_bloc_test.dart` — 10 tests (all events, online/offline, auto-sync)
- `test/core/network/api_exceptions_test.dart` — 19 tests (exception hierarchy)
- `test/core/network/connectivity_interceptor_test.dart` — 3 tests (online/offline/limited)
- `test/core/network/retry_interceptor_test.dart` — 5 tests (retry logic, max retries, non-idempotent skip)

### Bugs Fixed During Sprint
| Bug | Fix | File |
|-----|-----|------|
| Cognito exceptions not found in `amplify_flutter` | Import from `amplify_auth_cognito` with alias | amplify_auth_repository.dart |
| `NotAuthorizedException` class name wrong | Use `NotAuthorizedServiceException` | amplify_auth_repository.dart |
| `CodeExpiredException` class name wrong | Use `ExpiredCodeException` | amplify_auth_repository.dart |
| `sealed class SyncEvent` can't be extended outside library | Changed to `abstract class` | sync_event.dart |
| `.catchError` on `Future<SyncStats>` requires return type | Use `.then((_) {}, onError: ...)` pattern | sync_aware_receipt_repository.dart |
| auth_gate_test: GetIt not registered for user-dependent BLoCs | Register factoryParams for SearchBloc, TrashCubit, SyncBloc in setUp | auth_gate_test.dart |

### Final Status
- `flutter analyze`: 0 issues
- `flutter test`: 416 passed, 0 failed (+82 new tests)
- CDK stack: DEPLOYED and outputs wired into Flutter config
- All new code compiles, tests pass, ready for end-to-end testing

---

## 2026-02-11 — Feature #15: Home Screen Widget (Quick Capture)

### What Was Built

**Flutter Service Layer (2 files):**
- `core/services/home_widget_service.dart` — Injectable service wrapping `home_widget` package:
  - `initialize()` — sets iOS App Group ID
  - `updateStats(statsText)` — saves pre-formatted stats to shared preferences + triggers native widget refresh
  - `checkAndStoreInitialLaunch()` — checks if app was cold-launched from widget, stores URI
  - `consumePendingUri()` — returns stored URI once then clears it
  - `widgetClickStream` — forwards `HomeWidget.widgetClicked` stream for warm-start taps
- `core/services/widget_click_handler.dart` — Static `handle(Uri, BuildContext)` method:
  - Parses `warrantyvault://capture?source=camera|gallery|files`
  - Maps source param to `CaptureOption` enum (reuses existing from `capture_option_sheet.dart`)
  - Pushes `AddReceiptScreen(initialOption: ...)` directly (bypasses CaptureOptionSheet)
  - Unknown/missing source defaults to camera; wrong host (not `capture`) is a no-op

**Android Native (6 files):**
- `WarrantyVaultWidgetProvider.kt` — `AppWidgetProvider` subclass reading stats from `SharedPreferences("HomeWidgetPreferences")`, sets `PendingIntent` on capture button → URI `warrantyvault://capture?source=camera`
- `widget_warranty_vault.xml` — Layout: title (14sp, bold, #2D5A3D), stats text (12sp, #374151), 44dp camera button
- `widget_background.xml` — Rounded rectangle (#FAF7F2 fill, 16dp corners, #E5E7EB border)
- `widget_button_background.xml` — Oval shape, solid #2D5A3D fill
- `ic_widget_camera.xml` — Material camera_alt vector drawable, white fill
- `widget_warranty_vault_info.xml` — `<appwidget-provider>`: 180dp × 110dp min, 3×2 cells, 24h fallback update

**iOS Placeholder (1 file):**
- `WarrantyVaultWidget.swift` — WidgetKit `TimelineProvider` + SwiftUI view, `.systemSmall`/`.systemMedium` families, reads from `UserDefaults(suiteName: "group.io.cronos.warrantyvault")`, `Link` with `warrantyvault://capture?source=camera` URL. Requires Xcode project integration on Mac.

**Tests (2 files):**
- `home_widget_service_test.dart` — Tests `consumePendingUri()` null behavior, `widgetClickStream` accessor
- `widget_click_handler_test.dart` — 6 tests using `NavigatorObserver` pattern: camera/gallery/files source pushes route, unknown/missing defaults to camera, wrong host doesn't push

### Files Modified (6 + 3 test files)
1. `pubspec.yaml` — Added `home_widget: ^0.7.0`
2. `core/di/injection.dart` — Registered `HomeWidgetService` as lazySingleton
3. `main.dart` — Added `HomeWidgetService.initialize()` + `checkAndStoreInitialLaunch()` after DI setup
4. `core/widgets/app_shell.dart` — Major changes:
   - Added `BlocListener<VaultBloc, VaultState>` for reactive stats updates
   - Computes `warrantyCount` from `receipts.where((r) => r.isWarrantyActive).length`
   - Formats stats text using l10n: `"${l10n.receiptsCount(N)} · ${l10n.activeWarrantiesCount(M)}"`
   - Calls `HomeWidgetService.updateStats()` on every vault state change
   - Consumes pending URI in `initState()` via `addPostFrameCallback`
   - Subscribes to `widgetClickStream` for warm-start taps
5. `AndroidManifest.xml` — Added deep link `<intent-filter>` (scheme: `warrantyvault`) + widget `<receiver>` with provider meta-data
6. `ios/Runner/Info.plist` — Added `CFBundleURLTypes` with `warrantyvault` URL scheme
7. `test/core/widgets/app_shell_test.dart` — Added `MockHomeWidgetService` registration in GetIt
8. `test/core/router/auth_gate_test.dart` — Added `MockHomeWidgetService` registration in GetIt
9. `test/widget_test.dart` — Added `MockHomeWidgetService` registration in GetIt

### Key Data Flows
- **Stats update**: `VaultBloc → BlocListener in AppShell → HomeWidgetService.updateStats() → native SharedPreferences → widget onUpdate()`
- **Cold start tap**: Widget PendingIntent → MainActivity with URI → `checkAndStoreInitialLaunch()` stores URI → AppShell.initState → `consumePendingUri()` → `WidgetClickHandler.handle()` → Navigator.push(AddReceiptScreen)
- **Warm start tap**: `HomeWidget.widgetClicked` stream → AppShell subscription → `WidgetClickHandler.handle()` → Navigator.push(AddReceiptScreen)

### Issues Resolved
1. **15 test failures after initial implementation**: AppShell now uses `GetIt.I<HomeWidgetService>()` — every test rendering AppShell (directly or via AuthGate) needed a mock registered. Fixed in 3 test files.
2. **widget_click_handler_test.dart design**: Initial approach tried to render `AddReceiptScreen` (which has deep GetIt dependencies). Redesigned using `NavigatorObserver` to count pushed routes without needing to render destination widget.
3. **Unused variable warning**: `bool navigated = false` leftover from initial test design. Removed.

### Key Decisions
- **`home_widget` package as bridge** — Unified Flutter ↔ native API for shared storage, widget refresh, and click detection
- **Pre-formatted stats text** — Flutter formats the string (with l10n), native widget just displays it. Avoids duplicating formatting logic in Kotlin/Swift.
- **NavigatorObserver test pattern** — For testing navigation targets that have complex dependencies, count pushes instead of rendering the destination widget

### Final Status
- `flutter analyze`: **0 issues**
- `flutter test`: **387 passed, 0 failed**
- 11 new files created, 9 files modified (6 source + 3 test)

---
