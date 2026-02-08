# Core Module

Shared code used across all features. Nothing in `core/` depends on any `feature/`.

## Directories

| Directory | Contents |
|-----------|----------|
| `constants/` | App-wide constants: API URLs, storage keys, default values |
| `theme/` | ThemeData, AppColors, AppTypography, AppSpacing |
| `l10n/` | Localization: .arb files for EN/EL, generated AppLocalizations |
| `database/` | Drift DB: schema, tables, DAOs, encryption setup, migrations |
| `network/` | Dio HTTP client with interceptors (auth, retry, connectivity) |
| `services/` | Platform services: camera, file picker, notifications, secure storage |
| `utils/` | Pure utility functions and Dart extensions |
| `widgets/` | Reusable UI widgets: AppCard, AppButton, LoadingIndicator, etc. |
| `di/` | Dependency injection setup using get_it |
