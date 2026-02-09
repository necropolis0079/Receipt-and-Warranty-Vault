import '../../domain/entities/auth_result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Amplify-based implementation of [AuthRepository].
///
/// Stub for now — real implementation in Sprint 5-6 when Cognito is deployed.
/// Swap [MockAuthRepository] for this in [configureDependencies] to go live.
class AmplifyAuthRepository implements AuthRepository {
  @override
  Future<AuthUser?> getCurrentUser() {
    throw UnimplementedError('Amplify auth not yet configured');
  }

  @override
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) {
    throw UnimplementedError('Amplify auth not yet configured');
  }

  @override
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
  }) {
    throw UnimplementedError('Amplify auth not yet configured');
  }

  @override
  Future<AuthResult> confirmSignUp({
    required String email,
    required String code,
  }) {
    throw UnimplementedError('Amplify auth not yet configured');
  }

  @override
  Future<void> resendConfirmationCode({required String email}) {
    throw UnimplementedError('Amplify auth not yet configured');
  }

  @override
  Future<void> sendPasswordResetCode({required String email}) {
    throw UnimplementedError('Amplify auth not yet configured');
  }

  @override
  Future<AuthResult> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) {
    throw UnimplementedError('Amplify auth not yet configured');
  }

  @override
  Future<AuthResult> signInWithGoogle() {
    throw UnimplementedError('Amplify auth not yet configured');
  }

  @override
  Future<AuthResult> signInWithApple() {
    throw UnimplementedError('Amplify auth not yet configured');
  }

  @override
  Future<void> signOut() {
    throw UnimplementedError('Amplify auth not yet configured');
  }

  @override
  Future<void> deleteAccount() {
    throw UnimplementedError('Amplify auth not yet configured');
  }

  @override
  List<AuthProvider> getAvailableProviders() {
    // Real implementation would check Cognito config
    return [AuthProvider.email];
  }
}
