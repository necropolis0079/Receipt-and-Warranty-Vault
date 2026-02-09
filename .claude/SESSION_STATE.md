# Session State — Receipt & Warranty Vault

> **This file is updated by Claude before compaction and at key milestones.**
> **After compaction, read this FIRST to restore context.**

## Last Updated
- **Timestamp**: 2026-02-09
- **Phase**: Sprint 5-6 — Search, Notifications, Export & Polish COMPLETE

## Current Status
- Flutter project at `app/` with clean architecture (core + 5 feature modules)
- 22 dependencies in pubspec.yaml (added flutter_local_notifications, timezone, share_plus, csv)
- GitHub Actions CI pipeline (.github/workflows/ci.yml)
- All Sprints 1-6 features implemented and tested

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
- **Notification service**: NotificationService interface, LocalNotificationService, MockNotificationService, ReminderScheduler (7/1/0 days before expiry)
- **Search BLoC + UI**: SearchBloc (debounced 300ms, restartable), SearchFilters (client-side filtering by category/date/amount/warranty), SearchScreen rewrite, SearchFilterBar, SearchResultList
- **Export/Share**: ExportService interface, DeviceExportService (share_plus text+files, CSV batch), MockExportService
- **Trash/Recovery**: TrashCubit, TrashScreen (view, restore, permanently delete soft-deleted receipts)
- **Notification wiring**: AddReceiptBloc schedules reminders on save (warranty > 0), ExpiringBloc schedules reminders on load
- **Integration**: DI updated (NotificationService, ExportService, ReminderScheduler, SearchBloc, TrashCubit), Settings wired to Trash + Category Management, ~20 new l10n keys (EN + EL)

### Test Suite: 334 PASSED, 0 FAILED
- `flutter analyze`: 0 issues
- `flutter test`: 334 passed (270 existing + 64 new in Sprint 5-6)
- New test files: notification_service_test, reminder_scheduler_test, search_bloc_test, search_filters_test, search_screen_test, export_service_test, trash_cubit_test, add_receipt_reminder_test, expiring_bloc_reminder_test

## What Comes Next
- Sprint 5-6 is COMPLETE
- Next: Sprint 7-8 — AWS infrastructure deployment (CDK, API Gateway, Lambda, DynamoDB, S3, Cognito)
- OR: Sprint 7-8 — Sync engine + cloud integration
- See `docs/14-roadmap.md` for full sprint plan

## Key Reminders
- Read CLAUDE.md for ALL project decisions
- Read docs/devlog.md for what happened and why
- AWS profile is `warrantyvault`
- Auth strategy: mock-first, swap to AmplifyAuthRepository when Cognito deployed
- Capture strategy: mock-first for ImagePipelineService and OcrService; real implementations wrap native plugins
- Notification strategy: mock-first for NotificationService; LocalNotificationService wraps flutter_local_notifications on device
- Export strategy: mock-first for ExportService; DeviceExportService wraps share_plus on device
- BLoC for complex flows (Auth, AddReceipt, Vault, Expiring, Search), Cubit for simple state (AppLock, Locale, CategoryManagement, Trash)
- VaultBloc and ExpiringBloc provided at app level (needed by pushed routes like ReceiptDetailScreen)
- SearchBloc provided at app level (SearchScreen is a tab in AppShell)
