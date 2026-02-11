import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warrantyvault/core/database/app_database.dart';
import 'package:warrantyvault/core/l10n/locale_cubit.dart';
import 'package:warrantyvault/core/notifications/mock_notification_service.dart';
import 'package:warrantyvault/core/notifications/notification_service.dart';
import 'package:warrantyvault/core/security/app_lock_cubit.dart';
import 'package:warrantyvault/core/security/app_lock_service.dart';
import 'package:warrantyvault/core/theme/theme_cubit.dart';
import 'package:warrantyvault/core/theme/theme_state.dart';
import 'package:warrantyvault/features/auth/domain/repositories/auth_repository.dart';
import 'package:warrantyvault/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:warrantyvault/features/receipt/domain/entities/receipt.dart';
import 'package:warrantyvault/features/receipt/domain/repositories/receipt_repository.dart';
import 'package:warrantyvault/features/receipt/presentation/bloc/trash_cubit.dart';
import 'package:warrantyvault/features/receipt/presentation/bloc/vault_bloc.dart';
import 'package:warrantyvault/features/search/presentation/bloc/search_bloc.dart';
import 'package:warrantyvault/features/settings/presentation/screens/settings_screen.dart';
import 'package:warrantyvault/features/warranty/presentation/bloc/expiring_bloc.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAppLockService extends Mock implements AppLockService {}

class MockReceiptRepository extends Mock implements ReceiptRepository {}

void main() {
  late AuthBloc authBloc;
  late AppLockCubit lockCubit;
  late LocaleCubit localeCubit;
  late ThemeCubit themeCubit;
  late VaultBloc vaultBloc;
  late ExpiringBloc expiringBloc;
  late SearchBloc searchBloc;
  late TrashCubit trashCubit;
  late AppDatabase db;
  late MockNotificationService mockNotificationService;
  late MockAuthRepository mockAuthRepo;

  final getIt = GetIt.instance;

  setUpAll(() {
    registerFallbackValue(ReceiptStatus.active);
  });

  setUp(() async {
    mockAuthRepo = MockAuthRepository();
    final mockLockService = MockAppLockService();
    final mockReceiptRepo = MockReceiptRepository();
    mockNotificationService = MockNotificationService();

    // Stub mocks — stubs using any() must come before stubs with no args
    // to avoid dangling argument matchers.
    when(() => mockReceiptRepo.watchUserReceipts(any()))
        .thenAnswer((_) => Stream.value([]));
    when(() => mockReceiptRepo.getExpiringWarranties(any(), any()))
        .thenAnswer((_) async => []);
    when(() => mockReceiptRepo.getExpiredWarranties(any()))
        .thenAnswer((_) async => []);
    when(() => mockReceiptRepo.search(any(), any()))
        .thenAnswer((_) async => []);
    when(() => mockReceiptRepo.watchByStatus(any(), any()))
        .thenAnswer((_) => Stream.value([]));
    when(() => mockLockService.isDeviceSupported())
        .thenAnswer((_) async => false);
    when(() => mockAuthRepo.getCurrentUser()).thenAnswer((_) async => null);
    when(() => mockAuthRepo.signOut()).thenAnswer((_) async {});

    // Create real cubits/blocs
    authBloc = AuthBloc(authRepository: mockAuthRepo);
    lockCubit = AppLockCubit(appLockService: mockLockService);
    localeCubit = LocaleCubit();
    themeCubit = ThemeCubit();
    vaultBloc = VaultBloc(receiptRepository: mockReceiptRepo);
    expiringBloc = ExpiringBloc(receiptRepository: mockReceiptRepo);
    searchBloc =
        SearchBloc(receiptRepository: mockReceiptRepo, userId: 'test');
    trashCubit =
        TrashCubit(receiptRepository: mockReceiptRepo, userId: 'test');

    // In-memory Drift database for settings DAO
    db = AppDatabase.forTesting(NativeDatabase.memory());

    // Register in GetIt for SettingsScreen's direct GetIt.I<AppDatabase>() calls
    getIt.registerSingleton<AppDatabase>(db);
    getIt.registerSingleton<NotificationService>(mockNotificationService);
  });

  tearDown(() async {
    authBloc.close();
    lockCubit.close();
    localeCubit.close();
    themeCubit.close();
    vaultBloc.close();
    expiringBloc.close();
    searchBloc.close();
    trashCubit.close();
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
          BlocProvider.value(value: localeCubit),
          BlocProvider.value(value: themeCubit),
          BlocProvider.value(value: vaultBloc),
          BlocProvider.value(value: expiringBloc),
          BlocProvider.value(value: searchBloc),
          BlocProvider.value(value: trashCubit),
        ],
        child: const SettingsScreen(),
      ),
    );
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await tester.pump();
  }

  group('SettingsScreen — rendering', () {
    testWidgets('renders Settings app bar title', (tester) async {
      await pumpApp(tester);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('renders Language tile with English subtitle', (tester) async {
      await pumpApp(tester);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('renders Theme tile with System subtitle', (tester) async {
      await pumpApp(tester);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
    });

    testWidgets('renders Warranty Reminders tile', (tester) async {
      await pumpApp(tester);
      expect(find.text('Warranty Reminders'), findsOneWidget);
      expect(find.text('Reminders enabled'), findsOneWidget);
    });

    testWidgets('renders App Lock toggle', (tester) async {
      await pumpApp(tester);
      expect(find.text('Enable App Lock'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('renders Trash tile', (tester) async {
      await pumpApp(tester);
      expect(find.text('Trash'), findsOneWidget);
    });

    testWidgets('renders About tile', (tester) async {
      await pumpApp(tester);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('renders Sign Out tile in red', (tester) async {
      await pumpApp(tester);
      await tester.scrollUntilVisible(
        find.text('Sign Out'),
        200,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      final signOutFinder = find.text('Sign Out');
      expect(signOutFinder, findsOneWidget);
      final textWidget = tester.widget<Text>(signOutFinder);
      expect(textWidget.style?.color, Colors.red);
    });
  });

  group('SettingsScreen — language dialog', () {
    testWidgets('tapping Language tile opens language dialog', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();

      // Dialog should show both language options
      expect(find.text('English'), findsWidgets); // subtitle + dialog option
      expect(find.text('Ελληνικά'), findsOneWidget);
    });

    testWidgets('selecting Greek changes subtitle to Ελληνικά',
        (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ελληνικά'));
      await tester.pumpAndSettle();

      // The locale cubit should now be 'el'
      expect(localeCubit.state.locale.languageCode, 'el');
    });
  });

  group('SettingsScreen — theme dialog', () {
    testWidgets('tapping Theme tile opens theme dialog', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      // 'System' appears in both the subtitle and dialog
      expect(find.text('System'), findsWidgets);
    });

    testWidgets('selecting Dark changes subtitle and cubit', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(themeCubit.state.mode, AppThemeMode.dark);
      expect(find.text('Dark'), findsOneWidget);
    });
  });

  group('SettingsScreen — reminder dialog', () {
    testWidgets('tapping Reminders tile opens reminder dialog', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Warranty Reminders'));
      await tester.pumpAndSettle();

      expect(find.text('Reminder Settings'), findsOneWidget);
      // Dialog contains a SwitchListTile for toggling reminders
      expect(find.byType(SwitchListTile), findsWidgets);
    });

    testWidgets('toggling reminders off updates subtitle', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Warranty Reminders'));
      await tester.pumpAndSettle();

      // Find the SwitchListTile inside the dialog (the one with
      // 'Warranty Reminders' title). The dialog's switch is in addition to the
      // app lock switch on the main screen.
      final dialogSwitches = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(SwitchListTile),
      );
      expect(dialogSwitches, findsOneWidget);

      await tester.tap(dialogSwitches);
      await tester.pumpAndSettle();

      // Close dialog
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Reminders disabled'), findsOneWidget);
    });
  });

  group('SettingsScreen — about dialog', () {
    testWidgets('tapping About shows about dialog', (tester) async {
      await pumpApp(tester);

      await tester.ensureVisible(find.text('About'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();

      expect(find.text('Warranty Vault'), findsOneWidget);
      expect(find.text('1.0.0'), findsOneWidget);
    });
  });

  group('SettingsScreen — sign out', () {
    testWidgets('tapping Sign Out shows confirmation dialog', (tester) async {
      await pumpApp(tester);

      await tester.scrollUntilVisible(
        find.text('Sign Out'),
        200,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      expect(
          find.text('Are you sure you want to sign out?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
    });

    testWidgets('confirming sign out dispatches AuthSignOutRequested',
        (tester) async {
      await pumpApp(tester);

      await tester.scrollUntilVisible(
        find.text('Sign Out'),
        200,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      // AuthBloc should have processed the sign out — mock repo was called
      verify(() => mockAuthRepo.signOut()).called(1);
    });
  });
}
