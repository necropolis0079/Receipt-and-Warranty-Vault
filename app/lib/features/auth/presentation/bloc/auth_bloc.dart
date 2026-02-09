import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/auth_result.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthConfirmSignUpRequested>(_onConfirmSignUp);
    on<AuthResendCodeRequested>(_onResendCode);
    on<AuthPasswordResetRequested>(_onPasswordReset);
    on<AuthConfirmPasswordResetRequested>(_onConfirmPasswordReset);
    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthAppleSignInRequested>(_onAppleSignIn);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthDeleteAccountRequested>(_onDeleteAccount);
  }

  final AuthRepository _authRepository;

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final result = await _authRepository.signInWithEmail(
        email: event.email,
        password: event.password,
      );
      _handleResult(result, emit);
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final result = await _authRepository.signUpWithEmail(
        email: event.email,
        password: event.password,
      );
      _handleResult(result, emit);
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onConfirmSignUp(
    AuthConfirmSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final result = await _authRepository.confirmSignUp(
        email: event.email,
        code: event.code,
      );
      _handleResult(result, emit);
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onResendCode(
    AuthResendCodeRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.resendConfirmationCode(email: event.email);
      emit(AuthCodeResent(email: event.email));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onPasswordReset(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.sendPasswordResetCode(email: event.email);
      emit(AuthPasswordResetSent(email: event.email));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onConfirmPasswordReset(
    AuthConfirmPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final result = await _authRepository.confirmPasswordReset(
        email: event.email,
        code: event.code,
        newPassword: event.newPassword,
      );
      _handleResult(result, emit);
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onGoogleSignIn(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final result = await _authRepository.signInWithGoogle();
      _handleResult(result, emit);
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAppleSignIn(
    AuthAppleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final result = await _authRepository.signInWithApple();
      _handleResult(result, emit);
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.signOut();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onDeleteAccount(
    AuthDeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.deleteAccount();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void _handleResult(AuthResult result, Emitter<AuthState> emit) {
    switch (result) {
      case AuthSuccess(:final user):
        emit(AuthAuthenticated(user));
      case AuthNeedsConfirmation(:final email):
        emit(AuthNeedsVerification(email: email));
      case AuthFailure(:final message):
        emit(AuthError(message));
    }
  }
}
