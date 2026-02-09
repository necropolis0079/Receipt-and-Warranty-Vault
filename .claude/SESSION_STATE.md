# Session State — Receipt & Warranty Vault

> **This file is updated by Claude before compaction and at key milestones.**
> **After compaction, read this FIRST to restore context.**

## Last Updated
- **Timestamp**: 2026-02-09
- **Phase**: Sprint 7-8 — AWS Infrastructure (CDK) COMPLETE

## Current Status
- Flutter project at `app/` with clean architecture (core + 5 feature modules)
- AWS CDK project at `infra/` with single `ReceiptVaultStack` provisioning all 12 AWS services
- 22 Flutter dependencies in pubspec.yaml
- 2 CDK dependencies: aws-cdk-lib>=2.170.0, constructs>=10.0.0
- GitHub Actions CI pipeline (.github/workflows/ci.yml)
- All Sprints 1-8 features implemented and tested/reviewed

### Completed Features (Sprint 1-2)
- **Theme + design system**: AppColors, AppSpacing, AppRadius, AppShadows, AppTypography, AppTheme — 43 tests
- **Drift DB schema + SQLCipher**: 4 tables, 4 DAOs, FTS5, AES-256 encryption
- **Localization (EN + EL)**: ~175 keys in both ARB files, LocaleCubit — 19 tests
- **UI shell (5-tab navigation)**: AppShell + BottomNavigationBar + IndexedStack + 5 screens — 8 tests
- **Auth feature (F-010)**: Domain (entities + repository interface + mock), BLoC (11 events, 8 states), 7 screens, 3 widgets — 25 BLoC + 22 screen tests
- **App Lock (F-011)**: AppLockService, AppLockCubit, LockScreen, AppLifecycleObserver — 20 tests
- **DI**: Manual get_it (injection.dart)
- **AuthGate**: Declarative BlocConsumer router with lock screen overlay — 8 integration tests
- **Integration**: app.dart wired with MultiBlocProvider, main.dart with async DI init

### Completed Features (Sprint 3-4 — Core Capture)
- **Domain entities**: Receipt, OcrResult, ImageData, ReceiptResult
- **Service interfaces**: ImagePipelineService, OcrService (with mock + hybrid implementations)
- **Data layer**: ReceiptRepository interface, LocalReceiptRepository, ReceiptMapper
- **State management**: AddReceiptBloc, VaultBloc, ExpiringBloc, CategoryManagementCubit
- **UI widgets**: ReceiptCard, WarrantyBadge, CaptureOptionSheet, OcrProgressIndicator, ReceiptFieldEditors, ImagePreviewStrip
- **Screens**: AddReceiptScreen, VaultScreen, ExpiringScreen, ReceiptDetailScreen, ImagePreviewScreen, CategoryManagementScreen
- **Integration**: DI updated, AppShell capture flow, app-level BLoC providers, Settings -> Manage Categories, 10 new l10n keys

### Completed Features (Sprint 5-6 — Search, Notifications, Export & Polish)
- **Notification service**: NotificationService interface, LocalNotificationService, MockNotificationService, ReminderScheduler
- **Search BLoC + UI**: SearchBloc (debounced 300ms), SearchFilters, SearchScreen, SearchFilterBar, SearchResultList
- **Export/Share**: ExportService interface, DeviceExportService, MockExportService
- **Trash/Recovery**: TrashCubit, TrashScreen
- **Notification wiring**: AddReceiptBloc + ExpiringBloc schedule reminders
- **Integration**: DI updated, Settings wired to Trash + Category Management, ~20 new l10n keys

### Completed Features (Sprint 7-8 — AWS Infrastructure CDK)
- **CDK project**: `infra/` directory with app.py, cdk.json, requirements.txt
- **Shared Lambda layer**: 4 modules (response.py, dynamodb.py, auth.py, errors.py)
- **10 Lambda handlers**: receipt_crud, ocr_refine, sync_handler, thumbnail_generator, warranty_checker, weekly_summary, user_deletion, export_handler, category_handler, presigned_url_generator
- **CDK stack** (~1042 lines): DynamoDB (6 GSIs), KMS CMK, 3 S3 buckets, Cognito (User Pool + App Client), Lambda Layer, 10 Lambda functions, API Gateway (20 endpoints), CloudFront (OAC), 3 SNS topics, 2 EventBridge rules, 5 CloudWatch alarms, mandatory tags, 6 CfnOutputs
- **5 bug categories fixed**: error() arg order, GSI case mismatch, GSI-1 SK reference, missing GSI-4 PK write, SNS env var mismatch
- **21 files created** in `infra/` directory

### Test Suite: 334 PASSED, 0 FAILED (Flutter)
- `flutter analyze`: 0 issues
- `flutter test`: 334 passed
- CDK: `cdk synth` SUCCESS — 195 CloudFormation resources, 8 outputs, no errors

## What Comes Next
- Sprint 7-8 CDK is COMPLETE (code written, reviewed, bugs fixed)
- `cdk synth` PASSED — 195 resources, 8 outputs, template validates clean
- Pending: Git commit of all infra/ files
- Next: Sprint 9-10 — Sync Engine + Cloud Integration (connect Flutter app to AWS backend)
  - Amplify Flutter Gen 2 auth integration (swap MockAuthRepository for AmplifyAuthRepository)
  - Sync engine implementation (custom delta sync, field-level merge, conflict resolution)
  - API client layer (Dio + interceptors + presigned URLs)
  - Full Lambda business logic (replace TODO stubs)

## Key Reminders
- Read CLAUDE.md for ALL project decisions
- Read docs/devlog.md for what happened and why
- AWS profile is `warrantyvault`, account 882868333122, region eu-west-1
- CDK stack has NOT been deployed — only synthesized/validated
- Auth strategy: mock-first, swap to AmplifyAuthRepository when Cognito deployed
- Capture strategy: mock-first for ImagePipelineService and OcrService
- Notification strategy: mock-first for NotificationService
- Export strategy: mock-first for ExportService
- Lambda handlers are stubs with TODO markers — full logic in Sprint 9-10
- GSI attribute convention: UPPERCASE (GSI1PK, GSI1SK, etc.) throughout both CDK and handlers
- GSI-4 sort key is `warrantyExpiryDate` (not GSI4SK) — matches handler queries directly
- SNS env var is `SNS_TOPIC_ARN` (not SNS_PLATFORM_ARN) — uses TopicArn in publish calls
