import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warrantyvault/features/auth/domain/entities/auth_result.dart';
import 'package:warrantyvault/features/auth/domain/entities/auth_user.dart';
import 'package:warrantyvault/features/auth/domain/repositories/auth_repository.dart';
import 'package:warrantyvault/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:warrantyvault/features/auth/presentation/screens/sign_in_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;
  late AuthBloc authBloc;
  bool signUpCalled = false;
  bool forgotPasswordCalled = false;

  setUp(() {
    mockRepo = MockAuthRepository();
    authBloc = AuthBloc(authRepository: mockRepo);
    signUpCalled = false;
    forgotPasswordCalled = false;
  });

  tearDown(() => authBloc.close());

  Widget buildApp() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: BlocProvider.value(
        value: authBloc,
        child: SignInScreen(
          onSignUp: () => signUpCalled = true,
          onForgotPassword: () => forgotPasswordCalled = true,
        ),
      ),
    );
  }

  testWidgets('displays sign in title', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(find.text('Sign In'), findsWidgets);
  });

  testWidgets('displays email and password fields', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets('displays social sign-in buttons', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text('Sign in with Apple'), findsOneWidget);
  });

  testWidgets('displays forgot password link', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(find.text('Forgot Password?'), findsOneWidget);
  });

  testWidgets('tapping forgot password calls callback', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forgot Password?'));
    expect(forgotPasswordCalled, true);
  });

  testWidgets('tapping sign up link calls callback', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text("Don't have an account? Sign Up"));
    expect(signUpCalled, true);
  });

  testWidgets('shows validation errors for empty fields', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Tap Sign In button without filling fields
    // Find the ElevatedButton's text inside a BlocBuilder
    final signInButtons = find.widgetWithText(ElevatedButton, 'Sign In');
    await tester.tap(signInButtons);
    await tester.pumpAndSettle();

    expect(find.text('This field is required'), findsWidgets);
  });

  testWidgets('submitting valid form dispatches AuthSignInRequested',
      (tester) async {
    when(() => mockRepo.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => const AuthSuccess(AuthUser(
          userId: 'id',
          email: 'test@test.com',
          provider: AuthProvider.email,
          isEmailVerified: true,
        )));

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'test@test.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'Password1!');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pumpAndSettle();

    verify(() => mockRepo.signInWithEmail(
          email: 'test@test.com',
          password: 'Password1!',
        )).called(1);
  });
}
