# Regression Checklist — Warranty Vault

> **This checklist grows with each feature. Before any merge to `main`, ALL items must pass.**
> **If a new feature breaks an old check, the merge is BLOCKED until fixed.**

---

## How to Use
1. Run `flutter analyze` — must have zero errors
2. Run `flutter test` — all tests must pass
3. Walk through each section below — all items must be verified
4. If anything fails: fix it, add a specific test for the failure, then re-check

---

## Build & Analyze
- [ ] `flutter analyze` — zero errors, zero warnings
- [ ] `flutter test` — all 387+ tests pass
- [ ] `flutter build apk --debug` — builds successfully
- [ ] App launches without crash on Android emulator or device

---

## Navigation (Sprint 1-2)
- [ ] Bottom navigation bar renders with 5 tabs (Vault, Expiring, Add, Search, Settings)
- [ ] Tapping each tab switches to correct screen
- [ ] IndexedStack preserves tab state across switches
- [ ] Add tab opens CaptureOptionSheet (camera, gallery, files)

## Theme (Sprint 1-2)
- [ ] Brand colors render correctly (cream background, forest green accent)
- [ ] Typography uses DM Serif Display (headings) + Plus Jakarta Sans (body)
- [ ] Light theme applies consistently across all screens

## Database (Sprint 1-2)
- [ ] Drift DB initializes with SQLCipher encryption
- [ ] FTS5 full-text search index works
- [ ] 10 default categories seeded on first launch
- [ ] Settings DAO key-value storage works

## Localization (Sprint 1-2)
- [ ] English locale renders correctly
- [ ] Greek locale renders correctly
- [ ] LocaleCubit switches locale at runtime

## Auth (Sprint 1-2)
- [ ] MockAuthRepository simulates sign in/up/out lifecycle
- [ ] AuthGate routes to welcome screen when unauthenticated
- [ ] AuthGate routes to AppShell when authenticated
- [ ] Lock screen overlay appears when app lock is enabled + locked

## Core Capture (Sprint 3-4)
- [ ] Camera capture flow opens and returns image
- [ ] Gallery import flow opens and returns image
- [ ] File import flow opens and returns file
- [ ] OCR extraction runs on captured image (mock returns placeholder data)
- [ ] Receipt fields are editable after OCR
- [ ] Save persists receipt to Drift DB
- [ ] Receipt appears in Vault list after save

## Search, Notifications, Export (Sprint 5-6)
- [ ] Search with text query returns matching receipts
- [ ] Search filters (category, date, warranty) work correctly
- [ ] Export single receipt as text works
- [ ] Batch CSV export works
- [ ] Trash screen shows soft-deleted receipts
- [ ] Restore from trash works
- [ ] Warranty reminder scheduling works (mock)

## Home Screen Widget (Feature #15)
- [ ] `HomeWidgetService` registered in GetIt DI container
- [ ] `HomeWidgetService.initialize()` called in main.dart
- [ ] Widget click stream subscription active in AppShell
- [ ] Pending URI consumed on cold start in AppShell.initState()
- [ ] `warrantyvault://capture?source=camera` deep link opens AddReceiptScreen with camera
- [ ] `warrantyvault://capture?source=gallery` deep link opens AddReceiptScreen with gallery
- [ ] `warrantyvault://capture?source=files` deep link opens AddReceiptScreen with files
- [ ] Unknown/missing source defaults to camera
- [ ] Non-capture URIs (e.g. `warrantyvault://settings`) are ignored (no navigation)
- [ ] Stats update sent to native widget when VaultBloc emits VaultLoaded
- [ ] Stats update sent to native widget when VaultBloc emits VaultEmpty
- [ ] AndroidManifest.xml has deep link intent-filter for `warrantyvault` scheme
- [ ] AndroidManifest.xml has widget receiver with provider meta-data
- [ ] Info.plist has `CFBundleURLTypes` with `warrantyvault` URL scheme
- [ ] Android widget layout renders (title, stats, camera button)
- [ ] Tests: widget_click_handler_test.dart — 6 tests pass
- [ ] Tests: home_widget_service_test.dart — 3 tests pass
- [ ] Tests: Existing app_shell_test, auth_gate_test, widget_test still pass with mock HomeWidgetService

---

*Last updated: 2026-02-11*
