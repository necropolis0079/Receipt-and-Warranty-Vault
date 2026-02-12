import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/auth/presentation/screens/password_reset_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/widgets/app_lock_prompt_dialog.dart';
import '../../features/bulk_import/presentation/cubit/bulk_import_cubit.dart';
import '../../features/bulk_import/presentation/screens/bulk_import_screen.dart';
import '../../features/receipt/presentation/bloc/trash_cubit.dart';
import '../../features/search/presentation/bloc/search_bloc.dart';
import '../database/app_database.dart';
import '../di/injection.dart';
import '../security/app_lock_cubit.dart';
import '../security/app_lock_state.dart';
import '../security/lock_screen.dart';
import '../widgets/app_shell.dart';

/// Declarative router that renders the correct screen tree based on
/// [AuthBloc] state. The lock screen is displayed as a Stack overlay.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  /// Sub-navigation within the unauthenticated flow.
  _UnauthPage _currentPage = _UnauthPage.welcome;
  String? _verificationEmail;

  /// Whether we're currently showing the bulk import onboarding screen.
  bool _showBulkImport = false;

  /// Whether the first-launch check has already been performed.
  bool _bulkImportChecked = false;

  @override
  void initState() {
    super.initState();
    // Check if user is already signed in
    context.read<AuthBloc>().add(const AuthCheckRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthNeedsVerification) {
          setState(() {
            _verificationEmail = state.email;
            _currentPage = _UnauthPage.verification;
          });
        }
        if (state is AuthPasswordResetSent) {
          // Stay on password reset screen — it handles the code step
        }
      },
      builder: (context, authState) {
        // Loading state
        if (authState is AuthInitial || authState is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Authenticated: provide user-dependent BLoCs, then show main app
        if (authState is AuthAuthenticated) {
          final userId = authState.user.userId;

          // First-launch bulk import check
          if (!_bulkImportChecked) {
            _bulkImportChecked = true;
            _checkBulkImportShown();
          }

          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => getIt<SearchBloc>(param1: userId),
              ),
              BlocProvider(
                create: (_) => getIt<TrashCubit>(param1: userId),
              ),
            ],
            child: _showBulkImport
                ? BlocProvider(
                    create: (_) => getIt<BulkImportCubit>(),
                    child: BulkImportScreen(
                      onComplete: () async {
                        await getIt<AppDatabase>()
                            .settingsDao
                            .setValue('bulk_import_shown', 'true');
                        if (mounted) {
                          setState(() => _showBulkImport = false);
                          _promptAppLockIfNeeded();
                        }
                      },
                    ),
                  )
                : BlocBuilder<AppLockCubit, AppLockState>(
                    builder: (context, lockState) {
                      return Stack(
                        children: [
                          const AppShell(),
                          if (lockState.isEnabled && lockState.isLocked)
                            const Positioned.fill(child: LockScreen()),
                        ],
                      );
                    },
                  ),
          );
        }

        // Unauthenticated: show auth flow
        return _buildUnauthenticatedFlow();
      },
    );
  }

  Future<void> _checkBulkImportShown() async {
    final value =
        await getIt<AppDatabase>().settingsDao.getValue('bulk_import_shown');
    if (value == null && mounted) {
      setState(() => _showBulkImport = true);
    }
  }

  /// After bulk import, prompt the user to enable app lock if the device
  /// supports biometrics and the prompt hasn't been shown before.
  Future<void> _promptAppLockIfNeeded() async {
    final db = getIt<AppDatabase>();
    final alreadyPrompted =
        await db.settingsDao.getValue('app_lock_prompted');
    if (alreadyPrompted != null) return;
    if (!mounted) return;

    // Check device support
    final lockCubit = context.read<AppLockCubit>();
    await lockCubit.checkDeviceSupport();
    if (!lockCubit.state.isDeviceSupported) {
      // Device doesn't support biometrics — skip prompt.
      await db.settingsDao.setValue('app_lock_prompted', 'true');
      return;
    }

    if (!mounted) return;
    final enableNow = await AppLockPromptDialog.show(context);

    // Record that we've shown the prompt regardless of the choice.
    await db.settingsDao.setValue('app_lock_prompted', 'true');

    if (enableNow) {
      await lockCubit.enable();
    }
  }

  Widget _buildUnauthenticatedFlow() {
    return switch (_currentPage) {
      _UnauthPage.welcome => WelcomeScreen(
          onGetStarted: () {
            setState(() => _currentPage = _UnauthPage.signIn);
          },
        ),
      _UnauthPage.signIn => SignInScreen(
          onSignUp: () {
            setState(() => _currentPage = _UnauthPage.signUp);
          },
          onForgotPassword: () {
            setState(() => _currentPage = _UnauthPage.passwordReset);
          },
        ),
      _UnauthPage.signUp => SignUpScreen(
          onSignIn: () {
            setState(() => _currentPage = _UnauthPage.signIn);
          },
        ),
      _UnauthPage.verification => EmailVerificationScreen(
          email: _verificationEmail ?? '',
        ),
      _UnauthPage.passwordReset => const PasswordResetScreen(),
    };
  }
}

enum _UnauthPage { welcome, signIn, signUp, verification, passwordReset }
