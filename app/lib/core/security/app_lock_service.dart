/// Abstract interface for app lock / biometric authentication.
///
/// Wraps the local_auth package so it can be mocked in tests.
abstract class AppLockService {
  /// Whether the device supports biometric or device-credential auth.
  Future<bool> isDeviceSupported();

  /// Whether biometrics (fingerprint, face) are available and enrolled.
  Future<bool> canCheckBiometrics();

  /// Trigger biometric/PIN authentication. Returns true on success.
  Future<bool> authenticate({required String localizedReason});
}
