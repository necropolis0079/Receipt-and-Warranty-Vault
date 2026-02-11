# Session State — Receipt & Warranty Vault

> **This file is updated by Claude before compaction and at key milestones.**
> **After compaction, read this FIRST to restore context.**

## Last Updated
- **Timestamp**: 2026-02-11
- **Phase**: Feature #15 — Home Screen Widget COMPLETE

## Current Status
- Flutter project at `app/` with clean architecture (core + 5 feature modules)
- AWS infrastructure **DESTROYED** (2026-02-11) — app is offline-only
- Cloud/sync layer removed from codebase (Sprint simplification)
- All features through #15 implemented, analyze clean, 387 tests passing

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
- CDK stack: DynamoDB, KMS, S3, Cognito, Lambda, API Gateway, CloudFront, SNS, EventBridge, CloudWatch
- **NOTE**: All AWS resources DESTROYED on 2026-02-11

### Completed Features (Sprint 9-10 — Sync Engine)
- Network layer, remote data sources, sync engine, Amplify auth
- **NOTE**: Cloud/sync code removed on 2026-02-11 (offline-only simplification)

### Completed: Offline-Only Simplification (2026-02-11)
- Removed all cloud/sync code, reverted to MockAuthRepository
- Removed dependencies: dio, amplify_flutter, amplify_auth_cognito, workmanager, connectivity_plus, internet_connection_checker_plus

### Completed: Real Services + Theme System + Settings
- Wired real services into DI, added theme system (ThemeCubit), completed settings screen

### Completed: Bulk Import from Gallery (Feature #14)
- Scan gallery for receipt-like images, select, and batch-process

### Completed: Home Screen Widget — Feature #15 (2026-02-11)
- `home_widget: ^0.7.0` package added
- `HomeWidgetService` — injectable wrapper for home_widget package (initialize, updateStats, consumePendingUri, widgetClickStream)
- `WidgetClickHandler` — parses `warrantyvault://capture?source=camera|gallery|files` deep links, navigates to AddReceiptScreen
- Android native widget: Kotlin provider + XML layout + drawables + widget info XML
- iOS WidgetKit placeholder (requires Xcode on Mac)
- `AppShell` wired: BlocListener for stats updates, widget click stream subscription, pending URI consumption
- Deep link intent filters added to AndroidManifest.xml and Info.plist
- 15 new tests (6 widget_click_handler + 2 home_widget_service + 7 recovered existing)
- All 387 tests passing, 0 analyze issues

## Test Suite: 387 PASSED, 0 FAILED
- `flutter analyze`: 0 issues
- `flutter test`: 387 passed

## Key Reminders
- Read CLAUDE.md for ALL project decisions
- Read docs/devlog.md for what happened and why
- AWS is **DESTROYED** — app is fully offline-only
- Auth: MockAuthRepository (offline mock) — real auth deferred to v1.5
- Capture strategy: mock-first for ImagePipelineService and OcrService
- Notification strategy: mock-first for NotificationService
- Export strategy: mock-first for ExportService

## v1 Feature Priority Remaining
Features 1-15 are implemented. Remaining from the v1 list:
16. Stats display on home screen — partially done (widget has stats, home screen TBD)
17. English + Greek localization — done (104+ keys in both ARBs)
18. Batch export by date range — export service exists, batch UI TBD
