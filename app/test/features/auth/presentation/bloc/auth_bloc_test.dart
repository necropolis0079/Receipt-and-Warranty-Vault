import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warrantyvault/features/auth/domain/entities/auth_result.dart';
import 'package:warrantyvault/features/auth/domain/entities/auth_user.dart';
import 'package:warrantyvault/features/auth/domain/repositories/auth_repository.dart';
import 'package:warrantyvault/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:warrantyvault/features/auth/presentation/bloc/auth_event.dart';
import 'package:warrantyvault/features/auth/presentation/bloc/auth_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;

  const testUser = AuthUser(
    userId: 'test-id',
    email: 'test@example.com',
    provider: AuthProvider.email,
    isEmailVerified: true,
  );

  setUp(() {
    mockRepo = MockAuthRepository();
  });

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      final bloc = AuthBloc(authRepository: mockRepo);
      expect(bloc.state, const AuthInitial());
      bloc.close();
    });

    // --- AuthCheckRequested ---
    group('AuthCheckRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [Loading, Authenticated] when user is signed in',
        build: () {
          when(() => mockRepo.getCurrentUser())
              .thenAnswer((_) async => testUser);
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const AuthCheckRequested()),
        expect: () => [
          const AuthLoading(),
          const AuthAuthenticated(testUser),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [Loading, Unauthenticated] when no user',
        build: () {
          when(() => mockRepo.getCurrentUser()).thenAnswer((_) async => null);
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const AuthCheckRequested()),
        expect: () => [
          const AuthLoading(),
          const AuthUnauthenticated(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [Loading, Unauthenticated] on exception',
        build: () {
          when(() => mockRepo.getCurrentUser()).thenThrow(Exception('fail'));
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const AuthCheckRequested()),
        expect: () => [
          const AuthLoading(),
          const AuthUnauthenticated(),
        ],
      );
    });

    // --- SignIn ---
    group('AuthSignInRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [Loading, Authenticated] on successful sign in',
        build: () {
          when(() => mockRepo.signInWithEmail(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenAnswer((_) async => const AuthSuccess(testUser));
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const AuthSignInRequested(
          email: 'test@example.com',
          password: 'Password1!',
        )),
        expect: () => [
          const AuthLoading(),
          const AuthAuthenticated(testUser),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [Loading, NeedsVerification] when unconfirmed',
        build: () {
          when(() => mockRepo.signInWithEmail(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenAnswer((_) async =>
              const AuthNeedsConfirmation(email: 'test@example.com'));
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const AuthSignInRequested(
          email: 'test@example.com',
          password: 'Password1!',
        )),
        expect: () => [
          const AuthLoading(),
          const AuthNeedsVerification(email: 'test@example.com'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [Loading, Error] on failure',
        build: () {
          when(() => mockRepo.signInWithEmail(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenAnswer(
              (_) async => const AuthFailure('Incorrect password.'));
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const AuthSignInRequested(
          email: 'test@example.com',
          password: 'wrong',
        )),
        expect: () => [
          const AuthLoading(),
          const AuthError('Incorrect password.'),
        ],
      );
    });

    // --- SignUp ---
    group('AuthSignUpRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [Loading, NeedsVerification] on successful sign up',
        build: () {
          when(() => mockRepo.signUpWithEmail(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenAnswer((_) async =>
              const AuthNeedsConfirmation(email: 'new@example.com'));
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const AuthSignUpRequested(
          email: 'new@example.com',
          password: 'Password1!',
        )),
        expect: () => [
          const AuthLoading(),
          const AuthNeedsVerification(email: 'new@example.com'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [Loading, Error] when account exists',
        build: () {
          when(() => mockRepo.signUpWithEmail(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenAnswer((_) async =>
              const AuthFailure('An account with this email already exists.'));
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const AuthSignUpRequested(
          email: 'existing@example.com',
          password: 'Password1!',
        )),
        expect: () => [
          const AuthLoading(),
          const AuthError('An account with this email already exists.'),
        ],
      );
    });

    // --- ConfirmSignUp ---
    group('AuthConfirmSignUpRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [Loading, Authenticated] on valid code',
        build: () {
          when(() => mockRepo.confirmSignUp(
                email: any(named: 'email'),
                code: any(named: 'code'),
              )).thenAnswer((_) async => const AuthSuccess(testUser));
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const AuthConfirmSignUpRequested(
          email: 'test@example.com',
          code: '123456',
        )),
        expect: () => [
          const AuthLoading(),
          const AuthAuthenticated(testUser),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [Loading, Error] on invalid code',
        build: () {
          when(() => mockRepo.confirmSignUp(
                email: any(named: 'email'),
                code: any(named: 'code'),
              )).thenAnswer(
              (_) async => const AuthFailure('Invalid verification code.'));
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const AuthConfirmSignUpRequested(
          email: 'test@example.com',
          code: '000000',
        )),
        expect: () => [
          const AuthLoading(),
          const AuthError('Invalid verification code.'),
        ],
      );
    });

    // --- ResendCode ---
    group('AuthResendCodeRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [CodeResent] on success',
        build: () {
          when(() => mockRepo.resendConfirmationCode(
                email: any(named: 'email'),
              )).thenAnswer((_) async {});
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) =>
            bloc.add(const AuthResendCodeRequested(email: 'test@example.com')),
        expect: () => [
          const AuthCodeResent(email: 'test@example.com'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [Error] on failure',
        build: () {
          when(() => mockRepo.resendConfirmationCode(
                email: any(named: 'email'),
              )).thenThrow(Exception('Network error'));
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) =>
            bloc.add(const AuthResendCodeRequested(email: 'test@example.com')),
        expect: () => [
          isA<AuthError>(),
        ],
      );
    });

    // --- PasswordReset ---
    group('AuthPasswordResetRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [Loading, PasswordResetSent] on success',
        build: () {
          when(() => mockRepo.sendPasswordResetCode(
                email: any(named: 'email'),
              )).thenAnswer((_) async {});
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) => bloc
            .add(const AuthPasswordResetRequested(email: 'test@example.com')),
        expect: () => [
          const AuthLoading(),
          const AuthPasswordResetSent(email: 'test@example.com'),
        ],
      );
    });

    // --- ConfirmPasswordReset ---
    group('AuthConfirmPasswordResetRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [Loading, Authenticated] on success',
        build: () {
          when(() => mockRepo.confirmPasswordReset(
                email: any(named: 'email'),
                code: any(named: 'code'),
                newPassword: any(named: 'newPassword'),
              )).thenAnswer((_) async => const AuthSuccess(testUser));
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const AuthConfirmPasswordResetRequested(
          email: 'test@example.com',
          code: '654321',
          newPassword: 'NewPass1!',
        )),
        expect: () => [
          const AuthLoading(),
          const AuthAuthenticated(testUser),
        ],
      );
    });

    // --- Social SignIn ---
    group('Social sign-in', () {
      blocTest<AuthBloc, AuthState>(
        'emits [Loading, Authenticated] for Google sign-in',
        build: () {
          when(() => mockRepo.signInWithGoogle())
              .thenAnswer((_) async => const AuthSuccess(testUser));
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const AuthGoogleSignInRequested()),
        expect: () => [
          const AuthLoading(),
          const AuthAuthenticated(testUser),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [Loading, Authenticated] for Apple sign-in',
        build: () {
          when(() => mockRepo.signInWithApple())
              .thenAnswer((_) async => const AuthSuccess(testUser));
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const AuthAppleSignInRequested()),
        expect: () => [
          const AuthLoading(),
          const AuthAuthenticated(testUser),
        ],
      );
    });

    // --- SignOut ---
    group('AuthSignOutRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [Loading, Unauthenticated] on sign out',
        build: () {
          when(() => mockRepo.signOut()).thenAnswer((_) async {});
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const AuthSignOutRequested()),
        expect: () => [
          const AuthLoading(),
          const AuthUnauthenticated(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [Loading, Error] on sign out failure',
        build: () {
          when(() => mockRepo.signOut()).thenThrow(Exception('fail'));
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const AuthSignOutRequested()),
        expect: () => [
          const AuthLoading(),
          isA<AuthError>(),
        ],
      );
    });

    // --- DeleteAccount ---
    group('AuthDeleteAccountRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [Loading, Unauthenticated] on account deletion',
        build: () {
          when(() => mockRepo.deleteAccount()).thenAnswer((_) async {});
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const AuthDeleteAccountRequested()),
        expect: () => [
          const AuthLoading(),
          const AuthUnauthenticated(),
        ],
      );
    });

    // --- Exception handling ---
    group('exception handling', () {
      blocTest<AuthBloc, AuthState>(
        'sign in exception emits Error',
        build: () {
          when(() => mockRepo.signInWithEmail(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenThrow(Exception('Network error'));
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const AuthSignInRequested(
          email: 'test@example.com',
          password: 'Password1!',
        )),
        expect: () => [
          const AuthLoading(),
          isA<AuthError>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'sign up exception emits Error',
        build: () {
          when(() => mockRepo.signUpWithEmail(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenThrow(Exception('Network error'));
          return AuthBloc(authRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const AuthSignUpRequested(
          email: 'test@example.com',
          password: 'Password1!',
        )),
        expect: () => [
          const AuthLoading(),
          isA<AuthError>(),
        ],
      );
    });
  });
}
