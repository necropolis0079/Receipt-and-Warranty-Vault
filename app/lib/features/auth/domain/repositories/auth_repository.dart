import '../entities/auth_result.dart';
import '../entities/auth_user.dart';

/// Abstract interface for authentication operations.
///
/// Implementations:
/// - [MockAuthRepository] for development/testing
/// - [AmplifyAuthRepository] for production (Sprint 5-6)
abstract class AuthRepository {
  /// Returns the currently signed-in user, or null if unauthenticated.
  Future<AuthUser?> getCurrentUser();

  /// Sign in with email and password.
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  });

  /// Create a new account with email and password.
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Confirm email verification with a 6-digit code.
  Future<AuthResult> confirmSignUp({
    required String email,
    required String code,
  });

  /// Resend the email verification code.
  Future<void> resendConfirmationCode({required String email});

  /// Send a password reset code to the given email.
  Future<void> sendPasswordResetCode({required String email});

  /// Complete the password reset flow.
  Future<AuthResult> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  });

  /// Sign in with Google.
  Future<AuthResult> signInWithGoogle();

  /// Sign in with Apple.
  Future<AuthResult> signInWithApple();

  /// Sign out the current user.
  Future<void> signOut();

  /// Delete the current user's account permanently.
  Future<void> deleteAccount();

  /// Returns available sign-in providers for the current environment.
  /// Mock returns all; real returns what's configured.
  List<AuthProvider> getAvailableProviders();
}
