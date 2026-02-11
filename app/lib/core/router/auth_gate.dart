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
import '../../features/receipt/presentation/bloc/trash_cubit.dart';
import '../../features/search/presentation/bloc/search_bloc.dart';
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

          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => getIt<SearchBloc>(param1: userId),
              ),
              BlocProvider(
                create: (_) => getIt<TrashCubit>(param1: userId),
              ),
            ],
            child: BlocBuilder<AppLockCubit, AppLockState>(
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
