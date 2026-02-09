# Session State — Receipt & Warranty Vault

> **This file is updated by Claude before compaction and at key milestones.**
> **After compaction, read this FIRST to restore context.**

## Last Updated
- **Timestamp**: 2026-02-09
- **Phase**: Sprint 1-2 — Foundation COMPLETE (Auth + App Lock done)

## Current Status
- Flutter project at `app/` with clean architecture (core + 5 feature modules)
- 18 dependencies in pubspec.yaml
- GitHub Actions CI pipeline (.github/workflows/ci.yml)
- All Sprint 1-2 features implemented and tested

### Completed Features (Sprint 1-2)
- **Theme + design system**: AppColors, AppSpacing, AppRadius, AppShadows, AppTypography, AppTheme — 43 tests
- **Drift DB schema + SQLCipher**: 4 tables, 4 DAOs, FTS5, AES-256 encryption
- **Localization (EN + EL)**: ~145 keys in both ARB files, LocaleCubit — 19 tests
- **UI shell (5-tab navigation)**: AppShell + BottomNavigationBar + IndexedStack + 5 screens — 8 tests
- **Auth feature (F-010)**: Domain (entities + repository interface + mock), BLoC (11 events, 8 states), 7 screens, 3 widgets — 25 BLoC + 22 screen tests
- **App Lock (F-011)**: AppLockService, AppLockCubit, LockScreen, AppLifecycleObserver — 20 tests
- **DI**: Manual get_it (injection.dart)
- **AuthGate**: Declarative BlocConsumer router with lock screen overlay — 8 integration tests
- **Integration**: app.dart wired with MultiBlocProvider, main.dart with async DI init

### Test Suite: 139 PASSED, 0 FAILED
- `flutter analyze`: 0 issues
- `flutter test`: 139 passed

## Files Created (Sprint 1-2 Auth + App Lock)

### Auth Domain
- `lib/features/auth/domain/entities/auth_user.dart`
- `lib/features/auth/domain/entities/auth_result.dart`
- `lib/features/auth/domain/repositories/auth_repository.dart`
- `lib/features/auth/data/repositories/mock_auth_repository.dart`
- `lib/features/auth/data/repositories/amplify_auth_repository.dart` (stub)

### Auth BLoC
- `lib/features/auth/presentation/bloc/auth_bloc.dart`
- `lib/features/auth/presentation/bloc/auth_event.dart`
- `lib/features/auth/presentation/bloc/auth_state.dart`

### Auth Screens + Widgets
- `lib/features/auth/presentation/screens/welcome_screen.dart`
- `lib/features/auth/presentation/screens/sign_in_screen.dart`
- `lib/features/auth/presentation/screens/sign_up_screen.dart`
- `lib/features/auth/presentation/screens/email_verification_screen.dart`
- `lib/features/auth/presentation/screens/password_reset_screen.dart`
- `lib/features/auth/presentation/screens/storage_mode_screen.dart`
- `lib/features/auth/presentation/screens/app_lock_prompt_screen.dart`
- `lib/features/auth/presentation/widgets/social_sign_in_button.dart`
- `lib/features/auth/presentation/widgets/auth_text_field.dart`
- `lib/features/auth/presentation/widgets/password_requirements_widget.dart`

### App Lock
- `lib/core/security/app_lock_service.dart`
- `lib/core/security/local_auth_service.dart`
- `lib/core/security/app_lock_cubit.dart`
- `lib/core/security/app_lock_state.dart`
- `lib/core/security/lock_screen.dart`
- `lib/core/security/app_lifecycle_observer.dart`

### Routing + DI
- `lib/core/router/auth_gate.dart`
- `lib/core/di/injection.dart`

### Tests
- `test/features/auth/presentation/bloc/auth_bloc_test.dart` — 25 tests
- `test/features/auth/presentation/screens/welcome_screen_test.dart` — 6 tests
- `test/features/auth/presentation/screens/sign_in_screen_test.dart` — 8 tests
- `test/features/auth/presentation/screens/sign_up_screen_test.dart` — 8 tests
- `test/core/security/app_lock_cubit_test.dart` — 15 tests
- `test/core/security/lock_screen_test.dart` — 5 tests
- `test/core/router/auth_gate_test.dart` — 8 tests

### Modified Files
- `lib/app.dart` — MultiBlocProvider (AuthBloc + AppLockCubit + LocaleCubit), AuthGate as home
- `lib/main.dart` — async DI initialization
- `lib/features/settings/presentation/screens/settings_screen.dart` — Sign Out + App Lock wiring
- `lib/core/l10n/arb/app_en.arb` — ~40 new auth/lock strings
- `lib/core/l10n/arb/app_el.arb` — ~40 new auth/lock strings
- `test/core/widgets/app_shell_test.dart` — added BLoC providers
- `test/widget_test.dart` — added BLoC providers

## What Comes Next
- Sprint 1-2 is COMPLETE
- **Commit and push** all auth + app lock work
- Next: Receipt capture + OCR pipeline (Sprint 3)
- See `docs/14-roadmap.md` for full sprint plan

## Key Reminders
- Read CLAUDE.md for ALL project decisions
- Read docs/devlog.md for what happened and why
- AWS profile is `warrantyvault`
- Auth strategy: mock-first, swap to AmplifyAuthRepository when Cognito deployed (Sprint 5-6)
- BLoC for auth (many events), Cubit for app lock (simple state)
- AuthGate uses `tester.runAsync()` pattern in tests (BLoC async handlers need real event loop)
