# Warranty Vault — Flutter App Architecture

## Layer Structure (Clean Architecture + BLoC)

```
lib/
├── main.dart                    ← App entry point
├── app.dart                     ← MaterialApp configuration
├── core/                        ← Shared code used across all features
│   ├── constants/               ← App-wide constants (colors, spacing, strings)
│   ├── theme/                   ← ThemeData, color scheme, typography
│   ├── l10n/                    ← Localization (.arb files, generated code)
│   ├── database/                ← Drift DB (schema, DAOs, encryption)
│   │   ├── tables/              ← Table definitions
│   │   └── daos/                ← Data Access Objects
│   ├── network/                 ← Dio client, base config
│   │   └── interceptors/        ← Auth, connectivity, retry, logging
│   ├── services/                ← Platform services (camera, notifications, etc.)
│   ├── utils/                   ← Helper functions, extensions
│   ├── widgets/                 ← Reusable widgets (cards, buttons, loaders)
│   └── di/                      ← Dependency injection (get_it setup)
│
├── features/                    ← Feature modules (each self-contained)
│   ├── auth/                    ← Authentication (Cognito + app lock)
│   ├── receipt/                 ← Receipt CRUD, capture, OCR
│   ├── warranty/                ← Warranty tracking, expiry, reminders
│   ├── search/                  ← Search + filters
│   └── settings/                ← Settings, export, account management
```

## Each Feature Module Structure

```
feature_name/
├── data/
│   ├── datasources/             ← Local (Drift) and Remote (Dio) data sources
│   ├── models/                  ← Data transfer objects, JSON serialization
│   └── repositories/            ← Repository implementations
├── domain/
│   ├── entities/                ← Business entities (pure Dart, no Flutter)
│   └── repositories/            ← Repository interfaces (abstract classes)
└── presentation/
    ├── bloc/                    ← BLoCs and Cubits (state management)
    ├── screens/                 ← Full-page screens
    └── widgets/                 ← Feature-specific widgets
```

## Dependency Rules

- **Presentation** → depends on **Domain** only (via BLoC)
- **Domain** → depends on nothing (pure Dart)
- **Data** → implements **Domain** interfaces, depends on external packages
- **Core** → shared utilities, no feature dependencies
- Features NEVER import from other features directly (use core or DI)

## State Management

- **BLoC** for complex flows (receipt capture, sync, warranty tracking)
- **Cubit** for simple state (theme, locale, app lock)
- All business logic is in BLoCs/Cubits, NEVER in widgets
