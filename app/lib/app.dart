import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'core/l10n/locale_cubit.dart';
import 'core/l10n/locale_state.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_shell.dart';

/// The root widget for the Warranty Vault application.
///
/// Provides the [LocaleCubit] at the top of the widget tree and configures
/// theming, localization delegates, and top-level navigation.
class WarrantyVaultApp extends StatelessWidget {
  const WarrantyVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LocaleCubit(),
      child: BlocBuilder<LocaleCubit, LocaleState>(
        builder: (context, state) {
          return MaterialApp(
            title: 'Warranty Vault',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: state.locale,
            home: const AppShell(),
          );
        },
      ),
    );
  }
}
