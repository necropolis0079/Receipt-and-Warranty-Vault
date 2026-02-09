# Session State — Receipt & Warranty Vault

> **This file is updated by Claude before compaction and at key milestones.**
> **After compaction, read this FIRST to restore context.**

## Last Updated
- **Timestamp**: 2026-02-09
- **Phase**: Sprint 3-4 — Core Capture COMPLETE

## Current Status
- Flutter project at `app/` with clean architecture (core + 5 feature modules)
- 18 dependencies in pubspec.yaml
- GitHub Actions CI pipeline (.github/workflows/ci.yml)
- All Sprint 1-2 and Sprint 3-4 features implemented and tested

### Completed Features (Sprint 1-2)
- **Theme + design system**: AppColors, AppSpacing, AppRadius, AppShadows, AppTypography, AppTheme — 43 tests
- **Drift DB schema + SQLCipher**: 4 tables, 4 DAOs, FTS5, AES-256 encryption
- **Localization (EN + EL)**: ~155 keys in both ARB files, LocaleCubit — 19 tests
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

### Test Suite: 270 PASSED, 0 FAILED
- `flutter analyze`: 0 issues
- `flutter test`: 270 passed (~130 new in Sprint 3-4)

## What Comes Next
- Sprint 3-4 is COMPLETE
- Next: Sprint 5-6 — Cloud infrastructure (AWS CDK, API Gateway, Lambda, DynamoDB, S3, Cognito deployment)
- See `docs/14-roadmap.md` for full sprint plan

## Key Reminders
- Read CLAUDE.md for ALL project decisions
- Read docs/devlog.md for what happened and why
- AWS profile is `warrantyvault`
- Auth strategy: mock-first, swap to AmplifyAuthRepository when Cognito deployed (Sprint 5-6)
- Capture strategy: mock-first for ImagePipelineService and OcrService; real implementations wrap native plugins
- BLoC for complex flows (Auth, AddReceipt, Vault, Expiring), Cubit for simple state (AppLock, Locale, CategoryManagement)
- VaultBloc and ExpiringBloc provided at app level (needed by pushed routes like ReceiptDetailScreen)
