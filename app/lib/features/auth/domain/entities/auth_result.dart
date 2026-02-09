import 'auth_user.dart';

sealed class AuthResult {
  const AuthResult();
}

class AuthSuccess extends AuthResult {
  const AuthSuccess(this.user);
  final AuthUser user;
}

class AuthNeedsConfirmation extends AuthResult {
  const AuthNeedsConfirmation({required this.email});
  final String email;
}

class AuthFailure extends AuthResult {
  const AuthFailure(this.message);
  final String message;
}
