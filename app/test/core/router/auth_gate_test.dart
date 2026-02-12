import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warrantyvault/core/database/app_database.dart';
import 'package:warrantyvault/core/di/injection.dart';
import 'package:warrantyvault/core/l10n/locale_cubit.dart';
import 'package:warrantyvault/core/router/auth_gate.dart';
import 'package:warrantyvault/core/security/app_lock_cubit.dart';
import 'package:warrantyvault/core/security/app_lock_service.dart';
import 'package:warrantyvault/core/services/home_widget_service.dart';
import 'package:warrantyvault/core/theme/theme_cubit.dart';
import 'package:warrantyvault/core/notifications/mock_notification_service.dart';
import 'package:warrantyvault/core/notifications/notification_service.dart';
import 'package:warrantyvault/core/notifications/reminder_scheduler.dart';
import 'package:warrantyvault/features/auth/domain/entities/auth_result.dart';
import 'package:warrantyvault/features/auth/domain/entities/auth_user.dart';
import 'package:warrantyvault/features/auth/domain/repositories/auth_repository.dart';
import 'package:warrantyvault/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:warrantyvault/features/auth/presentation/bloc/auth_state.dart';
import 'package:warrantyvault/features/receipt/domain/repositories/receipt_repository.dart';
import 'package:warrantyvault/features/receipt/presentation/bloc/trash_cubit.dart';
import 'package:warrantyvault/features/receipt/presentation/bloc/vault_bloc.dart';
import 'package:warrantyvault/features/search/presentation/bloc/search_bloc.dart';
import 'package:warrantyvault/features/warranty/presentation/bloc/expiring_bloc.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAppLockService extends Mock implements AppLockService {}

class MockReceiptRepository extends Mock implements ReceiptRepository {}

class MockHomeWidgetService extends Mock implements HomeWidgetService {}

void main() {
  late MockAuthRepository mockRepo;
  late MockAppLockService mockLockService;
  late MockReceiptRepository mockReceiptRepo;
  late AuthBloc authBloc;
  late AppLockCubit lockCubit;
  late VaultBloc vaultBloc;
  late ExpiringBloc expiringBloc;
  late SearchBloc searchBloc;
  late LocaleCubit localeCubit;
  late ThemeCubit themeCubit;
  late AppDatabase db;

  const testUser = AuthUser(
    userId: 'test-id',
    email: 'test@example.com',
    provider: AuthProvider.email,
    isEmailVerified: true,
  );

  /// Waits for the AuthBloc to reach a target state, then pumps the widget.
  Future<void> waitForAuthState<T extends AuthState>(
    WidgetTester tester,
    AuthBloc bloc,
  ) async {
    if (bloc.state is! T) {
      await tester.runAsync(() async {
        await bloc.stream.firstWhere((s) => s is T);
      });
    }
    await tester.pump();
  }

  setUp(() async {
    mockRepo = MockAuthRepository();
    mockLockService = MockAppLockService();
    mockReceiptRepo = MockReceiptRepository();

    when(() => mockLockService.isDeviceSupported())
        .thenAnswer((_) async => false);

    // Default: no signed-in user
    when(() => mockRepo.getCurrentUser()).thenAnswer((_) async => null);

    when(() => mockReceiptRepo.watchUserReceipts(any()))
        .thenAnswer((_) => Stream.value([]));
    when(() => mockReceiptRepo.getExpiringWarranties(any(), any()))
        .thenAnswer((_) async => []);
    when(() => mockReceiptRepo.getExpiredWarranties(any()))
        .thenAnswer((_) async => []);
    when(() => mockReceiptRepo.search(any(), any()))
        .thenAnswer((_) async => []);

    // Register user-dependent BLoC factories in GetIt
    // (AuthGate resolves these via getIt<T>(param1: userId) when authenticated).
    await getIt.reset();

    // In-memory database for settings DAO (bulk import check)
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.settingsDao.setValue('bulk_import_shown', 'true');
    getIt.registerSingleton<AppDatabase>(db);

    final mockNotificationService = MockNotificationService();
    getIt.registerSingleton<NotificationService>(mockNotificationService);
    getIt.registerSingleton<ReminderScheduler>(
      ReminderScheduler(
        notificationService: mockNotificationService,
        settingsDao: db.settingsDao,
      ),
    );

    getIt.registerFactoryParam<SearchBloc, String, void>(
      (userId, _) => SearchBloc(
        receiptRepository: mockReceiptRepo,
        userId: userId,
      ),
    );
    getIt.registerFactoryParam<TrashCubit, String, void>(
      (userId, _) => TrashCubit(
        receiptRepository: mockReceiptRepo,
        userId: userId,
      ),
    );

    final mockHomeWidget = MockHomeWidgetService();
    when(() => mockHomeWidget.consumePendingUri()).thenReturn(null);
    when(() => mockHomeWidget.widgetClickStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockHomeWidget.updateStats(any()))
        .thenAnswer((_) async {});
    getIt.registerSingleton<HomeWidgetService>(mockHomeWidget);

    authBloc = AuthBloc(authRepository: mockRepo);
    lockCubit = AppLockCubit(appLockService: mockLockService);
    vaultBloc = VaultBloc(receiptRepository: mockReceiptRepo);
    expiringBloc = ExpiringBloc(receiptRepository: mockReceiptRepo);
    searchBloc = SearchBloc(receiptRepository: mockReceiptRepo, userId: 'test');
    localeCubit = LocaleCubit();
    themeCubit = ThemeCubit();
  });

  tearDown(() async {
    authBloc.close();
    lockCubit.close();
    vaultBloc.close();
    expiringBloc.close();
    searchBloc.close();
    localeCubit.close();
    themeCubit.close();
    await db.close();
    await getIt.reset();
  });

  Widget buildApp() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authBloc),
          BlocProvider.value(value: lockCubit),
          BlocProvider.value(value: vaultBloc),
          BlocProvider.value(value: expiringBloc),
          BlocProvider.value(value: searchBloc),
          BlocProvider.value(value: localeCubit),
          BlocProvider.value(value: themeCubit),
        ],
        child: const AuthGate(),
      ),
    );
  }

  testWidgets('shows loading indicator on initial state', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows welcome screen when unauthenticated', (tester) async {
    await tester.pumpWidget(buildApp());
    await waitForAuthState<AuthUnauthenticated>(tester, authBloc);

    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('shows AppShell when authenticated', (tester) async {
    when(() => mockRepo.getCurrentUser())
        .thenAnswer((_) async => testUser);

    await tester.pumpWidget(buildApp());
    await waitForAuthState<AuthAuthenticated>(tester, authBloc);

    expect(find.text('Vault'), findsOneWidget);
  });

  testWidgets('shows lock screen overlay when locked', (tester) async {
    when(() => mockRepo.getCurrentUser())
        .thenAnswer((_) async => testUser);
    when(() => mockLockService.isDeviceSupported())
        .thenAnswer((_) async => true);

    await tester.pumpWidget(buildApp());
    await waitForAuthState<AuthAuthenticated>(tester, authBloc);

    // Enable lock and simulate lock
    await tester.runAsync(() => lockCubit.enable());
    lockCubit.onAppResumed(); // Will lock since no pause recorded
    await tester.pump();

    expect(find.text('Unlock'), findsOneWidget);
    expect(find.text('App Locked'), findsOneWidget);
  });

  testWidgets('navigates to sign in from welcome', (tester) async {
    await tester.pumpWidget(buildApp());
    await waitForAuthState<AuthUnauthenticated>(tester, authBloc);

    await tester.tap(find.text('Skip'));
    await tester.pump();

    expect(find.text('Sign In'), findsWidgets);
  });

  testWidgets('navigates to sign up from sign in', (tester) async {
    await tester.pumpWidget(buildApp());
    await waitForAuthState<AuthUnauthenticated>(tester, authBloc);

    // Navigate: welcome → sign in
    await tester.tap(find.text('Skip'));
    await tester.pump();

    // Navigate: sign in → sign up
    await tester.tap(find.text("Don't have an account? Sign Up"));
    await tester.pump();

    expect(find.text('Confirm Password'), findsOneWidget);
  });

  testWidgets('navigates to forgot password from sign in', (tester) async {
    await tester.pumpWidget(buildApp());
    await waitForAuthState<AuthUnauthenticated>(tester, authBloc);

    // Navigate: welcome → sign in
    await tester.tap(find.text('Skip'));
    await tester.pump();

    // Navigate: sign in → forgot password
    await tester.tap(find.text('Forgot Password?'));
    await tester.pump();

    expect(find.text('Send Reset Code'), findsOneWidget);
  });

  testWidgets('shows verification screen on AuthNeedsVerification',
      (tester) async {
    when(() => mockRepo.getCurrentUser()).thenAnswer((_) async => null);
    when(() => mockRepo.signUpWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async =>
        const AuthNeedsConfirmation(email: 'test@test.com'));

    await tester.pumpWidget(buildApp());
    await waitForAuthState<AuthUnauthenticated>(tester, authBloc);

    // Navigate to sign in, then sign up
    await tester.tap(find.text('Skip'));
    await tester.pump();

    await tester.tap(find.text("Don't have an account? Sign Up"));
    await tester.pump();

    // Fill in sign up form
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'test@test.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'Password1!');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'), 'Password1!');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));

    // Wait for the BLoC to process the sign-up and emit NeedsVerification
    await waitForAuthState<AuthNeedsVerification>(tester, authBloc);

    expect(find.text('Verify Email'), findsOneWidget);
  });
}
