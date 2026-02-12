import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'core/database/app_database.dart';
import 'core/di/injection.dart';
import 'core/l10n/locale_cubit.dart';
import 'core/l10n/locale_state.dart';
import 'core/router/auth_gate.dart';
import 'core/security/app_lock_cubit.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/theme/theme_state.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/receipt/presentation/bloc/vault_bloc.dart';
import 'features/warranty/presentation/bloc/expiring_bloc.dart';

/// The root widget for the Warranty Vault application.
///
/// Provides [AuthBloc], [AppLockCubit], [LocaleCubit], [ThemeCubit],
/// [VaultBloc], and [ExpiringBloc] at the top of the widget tree.
/// User-dependent BLoCs ([SearchBloc], [TrashCubit]) are provided in
/// [AuthGate] after authentication succeeds.
class WarrantyVaultApp extends StatelessWidget {
  const WarrantyVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsDao = getIt<AppDatabase>().settingsDao;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) {
            final cubit = LocaleCubit();
            settingsDao.getValue('locale').then(cubit.loadSavedLocale);
            return cubit;
          },
        ),
        BlocProvider(
          create: (_) {
            final cubit = ThemeCubit();
            settingsDao.getValue('theme').then(cubit.loadSavedTheme);
            return cubit;
          },
        ),
        BlocProvider(create: (_) => getIt<AuthBloc>()),
        BlocProvider(
          create: (_) => getIt<AppLockCubit>()..checkDeviceSupport(),
        ),
        BlocProvider(create: (_) => getIt<VaultBloc>()),
        BlocProvider(create: (_) => getIt<ExpiringBloc>()),
      ],
      child: BlocBuilder<LocaleCubit, LocaleState>(
        builder: (context, localeState) {
          return BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) {
              final langCode = localeState.locale.languageCode;
              return MaterialApp(
                title: 'Warranty Vault',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light(locale: langCode),
                darkTheme: AppTheme.dark(locale: langCode),
                themeMode: _resolveThemeMode(themeState.mode),
                localizationsDelegates:
                    AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: localeState.locale,
                home: const AuthGate(),
              );
            },
          );
        },
      ),
    );
  }

  ThemeMode _resolveThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}
