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
import 'features/receipt/presentation/bloc/vault_bloc.dart';
import 'features/warranty/presentation/bloc/expiring_bloc.dart';

/// The root widget for the Warranty Vault application.
///
/// Provides [AuthBloc], [AppLockCubit], [LocaleCubit], [VaultBloc],
/// and [ExpiringBloc] at the top of the widget tree. User-dependent
/// BLoCs ([SearchBloc], [TrashCubit]) are provided in [AuthGate]
/// after authentication succeeds.
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
        BlocProvider(create: (_) => getIt<VaultBloc>()),
        BlocProvider(create: (_) => getIt<ExpiringBloc>()),
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
