import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warrantyvault/features/auth/domain/entities/auth_result.dart';
import 'package:warrantyvault/features/auth/domain/repositories/auth_repository.dart';
import 'package:warrantyvault/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:warrantyvault/features/auth/presentation/screens/sign_up_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;
  late AuthBloc authBloc;
  bool signInCalled = false;

  setUp(() {
    mockRepo = MockAuthRepository();
    authBloc = AuthBloc(authRepository: mockRepo);
    signInCalled = false;
  });

  tearDown(() => authBloc.close());

  Widget buildApp() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: BlocProvider.value(
        value: authBloc,
        child: SignUpScreen(onSignIn: () => signInCalled = true),
      ),
    );
  }

  testWidgets('displays sign up title in app bar', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(find.text('Sign Up'), findsWidgets);
  });

  testWidgets('displays email, password, and confirm password fields',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
  });

  testWidgets('displays password requirements widget', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    // The PasswordRequirementsWidget shows requirement labels
    expect(find.text('At least 8 characters'), findsOneWidget);
  });

  testWidgets('displays sign in link', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(find.text('Already have an account? Sign In'), findsOneWidget);
  });

  testWidgets('tapping sign in link calls callback', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Already have an account? Sign In'));
    expect(signInCalled, true);
  });

  testWidgets('shows validation error for short password', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'test@test.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'short');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'), 'short');

    // Find and tap the Sign Up elevated button
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
    await tester.pumpAndSettle();

    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
  });

  testWidgets('shows validation error for mismatched passwords',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'test@test.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'Password1!');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'), 'Different1!');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('submitting valid form dispatches AuthSignUpRequested',
      (tester) async {
    when(() => mockRepo.signUpWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async =>
        const AuthNeedsConfirmation(email: 'new@test.com'));

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'new@test.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'Password1!');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'), 'Password1!');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
    await tester.pumpAndSettle();

    verify(() => mockRepo.signUpWithEmail(
          email: 'new@test.com',
          password: 'Password1!',
        )).called(1);
  });
}
