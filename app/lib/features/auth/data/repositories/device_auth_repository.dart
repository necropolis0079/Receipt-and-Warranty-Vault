import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/auth_result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Device-local authentication using a persisted UUID.
///
/// On first launch a UUID is generated and stored in [FlutterSecureStorage].
/// Subsequent launches return the same UUID, so the user is always
/// "authenticated" without any login screen. This is appropriate for the
/// offline-only v1 where cloud auth is not needed.
///
/// The [AuthRepository] interface is preserved so that real auth (e.g. Cognito)
/// can be swapped in for v1.5.
class DeviceAuthRepository implements AuthRepository {
  DeviceAuthRepository({
    FlutterSecureStorage? storage,
  }) : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const _storageKey = 'device_user_id';
  final FlutterSecureStorage _storage;
  final _uuid = const Uuid();

  @override
  Future<AuthUser?> getCurrentUser() async {
    var userId = await _storage.read(key: _storageKey);
    if (userId == null) {
      userId = _uuid.v4();
      await _storage.write(key: _storageKey, value: userId);
    }
    return AuthUser(
      userId: userId,
      email: 'device@local',
      provider: AuthProvider.device,
      isEmailVerified: true,
    );
  }

  @override
  Future<void> signOut() async {
    // No-op — sign-out is meaningless for device auth.
    // The UUID must be preserved or all receipt data becomes orphaned.
  }

  @override
  Future<void> deleteAccount() async {
    await _storage.delete(key: _storageKey);
  }

  @override
  List<AuthProvider> getAvailableProviders() => [AuthProvider.device];

  // --- Unsupported operations (unreachable in device-auth mode) ---

  @override
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) =>
      throw UnsupportedError('signInWithEmail is not supported in device-auth mode');

  @override
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
  }) =>
      throw UnsupportedError('signUpWithEmail is not supported in device-auth mode');

  @override
  Future<AuthResult> confirmSignUp({
    required String email,
    required String code,
  }) =>
      throw UnsupportedError('confirmSignUp is not supported in device-auth mode');

  @override
  Future<void> resendConfirmationCode({required String email}) =>
      throw UnsupportedError('resendConfirmationCode is not supported in device-auth mode');

  @override
  Future<void> sendPasswordResetCode({required String email}) =>
      throw UnsupportedError('sendPasswordResetCode is not supported in device-auth mode');

  @override
  Future<AuthResult> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) =>
      throw UnsupportedError('confirmPasswordReset is not supported in device-auth mode');

  @override
  Future<AuthResult> signInWithGoogle() =>
      throw UnsupportedError('signInWithGoogle is not supported in device-auth mode');

  @override
  Future<AuthResult> signInWithApple() =>
      throw UnsupportedError('signInWithApple is not supported in device-auth mode');
}
