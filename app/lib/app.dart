import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'core/di/injection.dart';
import 'core/l10n/locale_cubit.dart';
import 'core/l10n/locale_state.dart';
import 'core/router/auth_gate.dart';
import 'core/security/app_lock_cubit.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

/// The root widget for the Warranty Vault application.
///
/// Provides [AuthBloc], [AppLockCubit], and [LocaleCubit] at the top of
/// the widget tree and configures theming, localization delegates, and
/// top-level navigation via [AuthGate].
class WarrantyVaultApp extends StatelessWidget {
  const WarrantyVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LocaleCubit()),
        BlocProvider(create: (_) => getIt<AuthBloc>()),
        BlocProvider(
          create: (_) => getIt<AppLockCubit>()..checkDeviceSupport(),
        ),
      ],
      child: BlocBuilder<LocaleCubit, LocaleState>(
        builder: (context, state) {
          return MaterialApp(
            title: 'Warranty Vault',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: state.locale,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
