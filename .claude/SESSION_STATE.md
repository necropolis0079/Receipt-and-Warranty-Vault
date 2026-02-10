# Session State — Receipt & Warranty Vault

> **This file is updated by Claude before compaction and at key milestones.**
> **After compaction, read this FIRST to restore context.**

## Last Updated
- **Timestamp**: 2026-02-10
- **Phase**: Sprint 9-10 — Sync Engine + Cloud Integration IN PROGRESS

## Current Status
- Flutter project at `app/` with clean architecture (core + 5 feature modules)
- AWS CDK project at `infra/` with single `ReceiptVaultStack` — DEPLOYED to eu-west-1
- CDK outputs captured and wired into app config
- All Sprint 1-10 code written, analyze clean, 334 tests passing

### CDK Deployment Outputs (LIVE)
| Output | Value |
|--------|-------|
| ApiUrl | `https://q1e4rkyf7e.execute-api.eu-west-1.amazonaws.com/prod/` |
| UserPoolId | `eu-west-1_8vZ07CiUc` |
| AppClientId | `3mlh4a83p6c9c3e1bcftf3obbd` |
| DynamoTableName | `ReceiptVault` |
| ImageBucketName | `receiptvault-images-prod-eu-west-1` |
| ExportBucketName | `receiptvault-exports-prod-eu-west-1` |
| CloudFrontDomain | `d2q7chjw0pm3p3.cloudfront.net` |

### Completed Features (Sprint 1-2)
- Theme + design system, Drift DB schema + SQLCipher, Localization (EN + EL), UI shell (5-tab navigation)
- Auth feature (F-010): Domain + BLoC + 7 screens + 3 widgets
- App Lock (F-011): AppLockService, AppLockCubit, LockScreen
- DI: Manual get_it (injection.dart), AuthGate: Declarative BlocConsumer router

### Completed Features (Sprint 3-4 — Core Capture)
- Domain entities, Service interfaces, Data layer, State management
- UI widgets + Screens for receipt capture and viewing

### Completed Features (Sprint 5-6 — Search, Notifications, Export & Polish)
- Notification service, Search BLoC + UI, Export/Share, Trash/Recovery

### Completed Features (Sprint 7-8 — AWS Infrastructure CDK)
- CDK stack (~1042 lines): DynamoDB, KMS, S3, Cognito, Lambda, API Gateway, CloudFront, SNS, EventBridge, CloudWatch
- 10 Lambda handlers, Shared Lambda layer

### Sprint 9-10 — Sync Engine + Cloud Integration (IN PROGRESS)
**Completed:**
1. pubspec.yaml updated with missing packages (dio, connectivity_plus, internet_connection_checker_plus, workmanager)
2. Network foundation: ApiConfig, ApiClient (Dio), ApiExceptions, 4 interceptors (auth, connectivity, retry, logging)
3. Remote data sources: ReceiptRemoteSource, SyncRemoteSource, ImageRemoteSource, SettingsRemoteSource
4. Sync engine: SyncConfig, ConflictResolver (3-tier), SyncService (pull/push/reconciliation), ImageSyncService
5. AmplifyAuthRepository (full production impl with correct Cognito exception imports), AmplifyConfig
6. SyncBloc, SyncAwareReceiptRepository, DI wiring (injection.dart), integration (auth_gate.dart, app.dart, main.dart)
7. All analyze errors fixed: Cognito exceptions from `amplify_auth_cognito`, sealed→abstract for SyncEvent, catchError pattern, auth_gate_test GetIt registration
8. amplify_config.dart + api_config.dart updated with real CDK outputs

**Key fixes applied during Sprint 9-10:**
- `amplify_auth_repository.dart`: Cognito-specific exceptions must be imported from `amplify_auth_cognito` (not `amplify_flutter`). Class names: `NotAuthorizedServiceException` (not NotAuthorizedException), `ExpiredCodeException` (not CodeExpiredException)
- `sync_event.dart`: Changed `sealed` to `abstract` (private events extend from different file)
- `sync_aware_receipt_repository.dart`: `.catchError` on `Future<T>` requires returning T → use `.then((_) {}, onError: ...)` pattern
- `auth_gate_test.dart`: Register GetIt factoryParams for SearchBloc, TrashCubit, SyncBloc (AuthGate resolves them via getIt)

9. Tests written: 82 new tests (ConflictResolver 45, SyncBloc 10, ApiExceptions 19, ConnectivityInterceptor 3, RetryInterceptor 5)
10. devlog.md updated with Sprint 9-10 section

**Remaining:**
- Git commit of all Sprint 9-10 work

### Test Suite: 416 PASSED, 0 FAILED (Flutter)
- `flutter analyze`: 0 issues
- `flutter test`: 416 passed (+82 new tests from Sprint 9-10)

## Key Reminders
- Read CLAUDE.md for ALL project decisions
- Read docs/devlog.md for what happened and why
- AWS profile is `warrantyvault`, account 882868333122, region eu-west-1
- CDK stack IS deployed — outputs captured above
- Auth: AmplifyAuthRepository is production-ready, uses `amplify_auth_cognito` for Cognito exceptions
- Capture strategy: mock-first for ImagePipelineService and OcrService
- Notification strategy: mock-first for NotificationService
- Export strategy: mock-first for ExportService
- GSI attribute convention: UPPERCASE (GSI1PK, GSI1SK, etc.)
