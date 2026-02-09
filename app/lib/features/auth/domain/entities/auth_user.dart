import 'package:equatable/equatable.dart';

enum AuthProvider { email, google, apple }

class AuthUser extends Equatable {
  const AuthUser({
    required this.userId,
    required this.email,
    required this.provider,
    this.displayName,
    this.isEmailVerified = false,
  });

  final String userId;
  final String email;
  final AuthProvider provider;
  final String? displayName;
  final bool isEmailVerified;

  @override
  List<Object?> get props => [
        userId,
        email,
        provider,
        displayName,
        isEmailVerified,
      ];
}
