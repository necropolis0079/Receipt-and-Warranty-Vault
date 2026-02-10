import 'package:amplify_auth_cognito/amplify_auth_cognito.dart' as cognito;
import 'package:amplify_flutter/amplify_flutter.dart' as amplify;

import '../../domain/entities/auth_result.dart';
import '../../domain/entities/auth_user.dart' as domain;
import '../../domain/repositories/auth_repository.dart';

/// Production implementation of [AuthRepository] backed by AWS Cognito
/// via Amplify Flutter Gen 2.
///
/// Handles email/password sign-up/sign-in, Google and Apple social login,
/// password reset, account deletion, and user attribute retrieval.
///
/// Import aliases used to disambiguate naming collisions:
/// - `amplify` = core Amplify classes (Amplify, AuthException, etc.)
/// - `cognito` = Cognito-specific exception types
/// - `domain`  = Our domain entities (AuthUser, AuthProvider)
class AmplifyAuthRepository implements AuthRepository {
  @override
  Future<domain.AuthUser?> getCurrentUser() async {
    try {
      final amplifyUser = await amplify.Amplify.Auth.getCurrentUser();
      final attributes = await amplify.Amplify.Auth.fetchUserAttributes();

      return _mapToAuthUser(amplifyUser.userId, attributes);
    } on amplify.SignedOutException {
      return null;
    } on amplify.AuthException {
      return null;
    }
  }

  @override
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Clear any stale session before attempting a new sign-in.
      await _signOutSilently();

      final result = await amplify.Amplify.Auth.signIn(
        username: email,
        password: password,
      );

      if (result.isSignedIn) {
        final user = await getCurrentUser();
        if (user != null) {
          return AuthSuccess(user);
        }
        return const AuthFailure('Sign-in succeeded but failed to fetch user.');
      }

      // User signed up but never confirmed their email.
      if (result.nextStep.signInStep == amplify.AuthSignInStep.confirmSignUp) {
        return AuthNeedsConfirmation(email: email);
      }

      return const AuthFailure('Sign-in incomplete.');
    } on cognito.UserNotFoundException {
      return const AuthFailure('No account found with this email.');
    } on cognito.NotAuthorizedServiceException {
      return const AuthFailure('Incorrect email or password.');
    } on cognito.UserNotConfirmedException {
      return AuthNeedsConfirmation(email: email);
    } on cognito.LimitExceededException {
      return const AuthFailure('Too many attempts. Please try again later.');
    } on amplify.AuthException catch (e) {
      return AuthFailure(e.message);
    }
  }

  @override
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final result = await amplify.Amplify.Auth.signUp(
        username: email,
        password: password,
        options: amplify.SignUpOptions(
          userAttributes: {
            amplify.AuthUserAttributeKey.email: email,
          },
        ),
      );

      if (result.nextStep.signUpStep == amplify.AuthSignUpStep.confirmSignUp) {
        return AuthNeedsConfirmation(email: email);
      }

      // Auto-confirmed (unlikely with our Cognito config, but handle it).
      if (result.isSignUpComplete) {
        return await signInWithEmail(email: email, password: password);
      }

      return AuthNeedsConfirmation(email: email);
    } on cognito.UsernameExistsException {
      return const AuthFailure(
        'An account with this email already exists.',
      );
    } on cognito.InvalidPasswordException catch (e) {
      return AuthFailure(e.message);
    } on cognito.LimitExceededException {
      return const AuthFailure('Too many attempts. Please try again later.');
    } on amplify.AuthException catch (e) {
      return AuthFailure(e.message);
    }
  }

  @override
  Future<AuthResult> confirmSignUp({
    required String email,
    required String code,
  }) async {
    try {
      final result = await amplify.Amplify.Auth.confirmSignUp(
        username: email,
        confirmationCode: code,
      );

      if (result.isSignUpComplete) {
        // After confirmation, check if a session already exists
        // (some Cognito configs auto-sign-in after confirmation).
        final user = await getCurrentUser();
        if (user != null) {
          return AuthSuccess(user);
        }

        // User confirmed but must sign in manually with credentials.
        // Return a provisional AuthSuccess so the UI knows confirmation
        // succeeded. The caller should then navigate to the sign-in screen.
        return AuthSuccess(
          domain.AuthUser(
            userId: '',
            email: email,
            provider: domain.AuthProvider.email,
            isEmailVerified: true,
          ),
        );
      }

      return const AuthFailure('Confirmation incomplete.');
    } on cognito.CodeMismatchException {
      return const AuthFailure('Invalid verification code.');
    } on cognito.ExpiredCodeException {
      return const AuthFailure(
        'Verification code expired. Please request a new one.',
      );
    } on cognito.LimitExceededException {
      return const AuthFailure('Too many attempts. Please try again later.');
    } on amplify.AuthException catch (e) {
      return AuthFailure(e.message);
    }
  }

  @override
  Future<void> resendConfirmationCode({required String email}) async {
    try {
      await amplify.Amplify.Auth.resendSignUpCode(username: email);
    } on cognito.LimitExceededException {
      throw Exception('Too many attempts. Please try again later.');
    } on amplify.AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  @override
  Future<void> sendPasswordResetCode({required String email}) async {
    try {
      await amplify.Amplify.Auth.resetPassword(username: email);
    } on cognito.UserNotFoundException {
      // Don't reveal whether the user exists (security best practice).
      // Silently succeed so attackers cannot enumerate accounts.
      return;
    } on cognito.LimitExceededException {
      throw Exception('Too many attempts. Please try again later.');
    } on amplify.AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  @override
  Future<AuthResult> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await amplify.Amplify.Auth.confirmResetPassword(
        username: email,
        newPassword: newPassword,
        confirmationCode: code,
      );

      // After password reset, attempt auto-sign-in for better UX.
      return await signInWithEmail(email: email, password: newPassword);
    } on cognito.CodeMismatchException {
      return const AuthFailure('Invalid reset code.');
    } on cognito.ExpiredCodeException {
      return const AuthFailure(
        'Reset code expired. Please request a new one.',
      );
    } on cognito.InvalidPasswordException catch (e) {
      return AuthFailure(e.message);
    } on cognito.LimitExceededException {
      return const AuthFailure('Too many attempts. Please try again later.');
    } on amplify.AuthException catch (e) {
      return AuthFailure(e.message);
    }
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    return _signInWithSocialProvider(
      amplify.AuthProvider.google,
      domain.AuthProvider.google,
    );
  }

  @override
  Future<AuthResult> signInWithApple() async {
    return _signInWithSocialProvider(
      amplify.AuthProvider.apple,
      domain.AuthProvider.apple,
    );
  }

  @override
  Future<void> signOut() async {
    await amplify.Amplify.Auth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    await amplify.Amplify.Auth.deleteUser();
  }

  @override
  List<domain.AuthProvider> getAvailableProviders() {
    return [
      domain.AuthProvider.email,
      domain.AuthProvider.google,
      domain.AuthProvider.apple,
    ];
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Handles social sign-in via Cognito hosted UI / web UI.
  ///
  /// [amplifyProvider] is Amplify's provider enum for the web UI redirect.
  /// [domainProvider] is our domain enum stored on the returned [domain.AuthUser].
  Future<AuthResult> _signInWithSocialProvider(
    amplify.AuthProvider amplifyProvider,
    domain.AuthProvider domainProvider,
  ) async {
    try {
      final result = await amplify.Amplify.Auth.signInWithWebUI(
        provider: amplifyProvider,
      );

      if (result.isSignedIn) {
        final user = await getCurrentUser();
        if (user != null) {
          // Ensure provider is set correctly even if the Cognito
          // 'identities' attribute hasn't propagated yet.
          final socialUser = domain.AuthUser(
            userId: user.userId,
            email: user.email,
            provider: domainProvider,
            displayName: user.displayName,
            isEmailVerified: user.isEmailVerified,
          );
          return AuthSuccess(socialUser);
        }
        return const AuthFailure(
          'Social sign-in succeeded but failed to fetch user.',
        );
      }

      return const AuthFailure('Social sign-in incomplete.');
    } on amplify.UserCancelledException {
      return const AuthFailure('Sign-in was cancelled.');
    } on cognito.LimitExceededException {
      return const AuthFailure('Too many attempts. Please try again later.');
    } on amplify.AuthException catch (e) {
      return AuthFailure(e.message);
    }
  }

  /// Maps Amplify user ID + attributes to our domain [domain.AuthUser].
  domain.AuthUser _mapToAuthUser(
    String userId,
    List<amplify.AuthUserAttribute> attributes,
  ) {
    String email = '';
    String? displayName;
    bool isEmailVerified = false;
    domain.AuthProvider provider = domain.AuthProvider.email;

    for (final attr in attributes) {
      switch (attr.userAttributeKey) {
        case amplify.AuthUserAttributeKey.email:
          email = attr.value;
        case amplify.AuthUserAttributeKey.emailVerified:
          isEmailVerified = attr.value.toLowerCase() == 'true';
        case amplify.AuthUserAttributeKey.name:
          displayName = attr.value;
        case amplify.AuthUserAttributeKey.preferredUsername:
          displayName ??= attr.value;
        default:
          // Check for social identity provider info stored in the
          // 'identities' attribute by Cognito federated sign-in.
          if (attr.userAttributeKey.key == 'identities') {
            final identities = attr.value.toLowerCase();
            if (identities.contains('google')) {
              provider = domain.AuthProvider.google;
            } else if (identities.contains('signinwithapple') ||
                identities.contains('apple')) {
              provider = domain.AuthProvider.apple;
            }
          }
      }
    }

    return domain.AuthUser(
      userId: userId,
      email: email,
      provider: provider,
      displayName: displayName,
      isEmailVerified: isEmailVerified,
    );
  }

  /// Silently signs out any existing session to prevent
  /// "There is already a user signed in" errors.
  Future<void> _signOutSilently() async {
    try {
      await amplify.Amplify.Auth.signOut();
    } on amplify.AuthException {
      // Ignore -- no session to clear.
    }
  }
}
