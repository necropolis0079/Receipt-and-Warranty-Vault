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
