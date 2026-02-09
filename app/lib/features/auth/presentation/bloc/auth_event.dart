sealed class AuthEvent {
  const AuthEvent();
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested({required this.email, required this.password});
  final String email;
  final String password;
}

class AuthSignUpRequested extends AuthEvent {
  const AuthSignUpRequested({required this.email, required this.password});
  final String email;
  final String password;
}

class AuthConfirmSignUpRequested extends AuthEvent {
  const AuthConfirmSignUpRequested({required this.email, required this.code});
  final String email;
  final String code;
}

class AuthResendCodeRequested extends AuthEvent {
  const AuthResendCodeRequested({required this.email});
  final String email;
}

class AuthPasswordResetRequested extends AuthEvent {
  const AuthPasswordResetRequested({required this.email});
  final String email;
}

class AuthConfirmPasswordResetRequested extends AuthEvent {
  const AuthConfirmPasswordResetRequested({
    required this.email,
    required this.code,
    required this.newPassword,
  });
  final String email;
  final String code;
  final String newPassword;
}

class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

class AuthAppleSignInRequested extends AuthEvent {
  const AuthAppleSignInRequested();
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

class AuthDeleteAccountRequested extends AuthEvent {
  const AuthDeleteAccountRequested();
}
