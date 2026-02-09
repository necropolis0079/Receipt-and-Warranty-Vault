import 'package:uuid/uuid.dart';

import '../../domain/entities/auth_result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// In-memory mock implementation of [AuthRepository].
///
/// Stores users in a map. Useful for development and testing.
/// Simulates network delays with a configurable duration.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({this.delay = const Duration(milliseconds: 300)});

  final Duration delay;
  final _uuid = const Uuid();

  /// Registered users: email → {password, user, confirmed}
  final Map<String, _MockAccount> _accounts = {};

  /// Currently signed-in user.
  AuthUser? _currentUser;

  /// Pending confirmation codes: email → code
  final Map<String, String> _pendingCodes = {};

  /// Pending password reset codes: email → code
  final Map<String, String> _resetCodes = {};

  @override
  Future<AuthUser?> getCurrentUser() async {
    await Future<void>.delayed(delay);
    return _currentUser;
  }

  @override
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(delay);

    final account = _accounts[email.toLowerCase()];
    if (account == null) {
      return const AuthFailure('No account found with that email.');
    }
    if (account.password != password) {
      return const AuthFailure('Incorrect password.');
    }
    if (!account.confirmed) {
      return AuthNeedsConfirmation(email: email);
    }

    _currentUser = account.user;
    return AuthSuccess(account.user);
  }

  @override
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(delay);

    final key = email.toLowerCase();
    if (_accounts.containsKey(key)) {
      return const AuthFailure('An account with this email already exists.');
    }

    final user = AuthUser(
      userId: _uuid.v4(),
      email: email,
      provider: AuthProvider.email,
    );

    _accounts[key] = _MockAccount(
      user: user,
      password: password,
      confirmed: false,
    );

    // Generate a mock 6-digit code
    _pendingCodes[key] = '123456';

    return AuthNeedsConfirmation(email: email);
  }

  @override
  Future<AuthResult> confirmSignUp({
    required String email,
    required String code,
  }) async {
    await Future<void>.delayed(delay);

    final key = email.toLowerCase();
    final expectedCode = _pendingCodes[key];

    if (expectedCode == null || expectedCode != code) {
      return const AuthFailure('Invalid verification code.');
    }

    final account = _accounts[key];
    if (account == null) {
      return const AuthFailure('Account not found.');
    }

    _accounts[key] = account.copyWith(
      confirmed: true,
      user: AuthUser(
        userId: account.user.userId,
        email: account.user.email,
        provider: account.user.provider,
        displayName: account.user.displayName,
        isEmailVerified: true,
      ),
    );
    _pendingCodes.remove(key);

    final confirmedUser = _accounts[key]!.user;
    _currentUser = confirmedUser;
    return AuthSuccess(confirmedUser);
  }

  @override
  Future<void> resendConfirmationCode({required String email}) async {
    await Future<void>.delayed(delay);
    _pendingCodes[email.toLowerCase()] = '123456';
  }

  @override
  Future<void> sendPasswordResetCode({required String email}) async {
    await Future<void>.delayed(delay);

    final key = email.toLowerCase();
    if (!_accounts.containsKey(key)) return; // Silent fail for security

    _resetCodes[key] = '654321';
  }

  @override
  Future<AuthResult> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await Future<void>.delayed(delay);

    final key = email.toLowerCase();
    final expectedCode = _resetCodes[key];

    if (expectedCode == null || expectedCode != code) {
      return const AuthFailure('Invalid reset code.');
    }

    final account = _accounts[key];
    if (account == null) {
      return const AuthFailure('Account not found.');
    }

    _accounts[key] = account.copyWith(password: newPassword);
    _resetCodes.remove(key);

    return AuthSuccess(account.user);
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    await Future<void>.delayed(delay);

    final user = AuthUser(
      userId: _uuid.v4(),
      email: 'google.user@gmail.com',
      provider: AuthProvider.google,
      displayName: 'Google User',
      isEmailVerified: true,
    );

    _currentUser = user;
    return AuthSuccess(user);
  }

  @override
  Future<AuthResult> signInWithApple() async {
    await Future<void>.delayed(delay);

    final user = AuthUser(
      userId: _uuid.v4(),
      email: 'apple.user@icloud.com',
      provider: AuthProvider.apple,
      displayName: 'Apple User',
      isEmailVerified: true,
    );

    _currentUser = user;
    return AuthSuccess(user);
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(delay);
    _currentUser = null;
  }

  @override
  Future<void> deleteAccount() async {
    await Future<void>.delayed(delay);

    if (_currentUser != null) {
      _accounts.remove(_currentUser!.email.toLowerCase());
      _currentUser = null;
    }
  }

  @override
  List<AuthProvider> getAvailableProviders() {
    return AuthProvider.values;
  }
}

class _MockAccount {
  const _MockAccount({
    required this.user,
    required this.password,
    required this.confirmed,
  });

  final AuthUser user;
  final String password;
  final bool confirmed;

  _MockAccount copyWith({
    AuthUser? user,
    String? password,
    bool? confirmed,
  }) {
    return _MockAccount(
      user: user ?? this.user,
      password: password ?? this.password,
      confirmed: confirmed ?? this.confirmed,
    );
  }
}
