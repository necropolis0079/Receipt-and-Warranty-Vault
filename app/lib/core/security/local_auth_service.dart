import 'package:local_auth/local_auth.dart';

import 'app_lock_service.dart';

/// Concrete implementation using the local_auth package.
class LocalAuthService implements AppLockService {
  final _localAuth = LocalAuthentication();

  @override
  Future<bool> isDeviceSupported() => _localAuth.isDeviceSupported();

  @override
  Future<bool> canCheckBiometrics() => _localAuth.canCheckBiometrics;

  @override
  Future<bool> authenticate({required String localizedReason}) {
    return _localAuth.authenticate(
      localizedReason: localizedReason,
      options: const AuthenticationOptions(
        stickyAuth: true,
        biometricOnly: false,
      ),
    );
  }
}
