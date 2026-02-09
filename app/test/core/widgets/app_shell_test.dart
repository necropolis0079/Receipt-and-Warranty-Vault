import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warrantyvault/core/security/app_lock_cubit.dart';
import 'package:warrantyvault/core/security/app_lock_service.dart';
import 'package:warrantyvault/core/widgets/app_shell.dart';
import 'package:warrantyvault/features/auth/domain/repositories/auth_repository.dart';
import 'package:warrantyvault/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:warrantyvault/features/receipt/domain/repositories/receipt_repository.dart';
import 'package:warrantyvault/features/receipt/presentation/bloc/vault_bloc.dart';
import 'package:warrantyvault/features/search/presentation/bloc/search_bloc.dart';
import 'package:warrantyvault/features/warranty/presentation/bloc/expiring_bloc.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAppLockService extends Mock implements AppLockService {}

class MockReceiptRepository extends Mock implements ReceiptRepository {}

void main() {
  late AuthBloc authBloc;
  late AppLockCubit lockCubit;
  late VaultBloc vaultBloc;
  late ExpiringBloc expiringBloc;
  late SearchBloc searchBloc;

  setUp(() {
    final mockRepo = MockAuthRepository();
    final mockLockService = MockAppLockService();
    final mockReceiptRepo = MockReceiptRepository();

    when(() => mockLockService.isDeviceSupported())
        .thenAnswer((_) async => false);
    when(() => mockRepo.getCurrentUser()).thenAnswer((_) async => null);
    when(() => mockReceiptRepo.watchUserReceipts(any()))
        .thenAnswer((_) => Stream.value([]));
    when(() => mockReceiptRepo.getExpiringWarranties(any(), any()))
        .thenAnswer((_) async => []);
    when(() => mockReceiptRepo.getExpiredWarranties(any()))
        .thenAnswer((_) async => []);
    when(() => mockReceiptRepo.search(any(), any()))
        .thenAnswer((_) async => []);

    authBloc = AuthBloc(authRepository: mockRepo);
    lockCubit = AppLockCubit(appLockService: mockLockService);
    vaultBloc = VaultBloc(receiptRepository: mockReceiptRepo);
    expiringBloc = ExpiringBloc(receiptRepository: mockReceiptRepo);
    searchBloc = SearchBloc(receiptRepository: mockReceiptRepo, userId: 'test');
  });

  tearDown(() {
    authBloc.close();
    lockCubit.close();
    vaultBloc.close();
    expiringBloc.close();
    searchBloc.close();
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
        ],
        child: const AppShell(),
      ),
    );
  }

  /// Pump the widget and allow blocs to process their initial events.
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    // Allow blocs to process async events (stream/future emissions).
    await tester.pump();
    await tester.pump();
  }

  group('AppShell', () {
    testWidgets('renders a BottomNavigationBar', (tester) async {
      await pumpApp(tester);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('shows all 5 tab labels', (tester) async {
      await pumpApp(tester);

      expect(find.text('Vault'), findsOneWidget);
      expect(find.text('Expiring'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      // "Settings" appears as both tab label and AppBar title when selected,
      // but on startup the Vault tab is active so only the tab label shows.
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('starts on the Vault tab (index 0)', (tester) async {
      await pumpApp(tester);

      // The Vault screen's AppBar title is "My Receipts".
      expect(find.text('My Receipts'), findsOneWidget);
    });

    testWidgets('uses IndexedStack to preserve tab state', (tester) async {
      await pumpApp(tester);
      expect(find.byType(IndexedStack), findsOneWidget);
    });

    testWidgets('tapping Expiring tab shows expiring screen', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Expiring'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Expiring Warranties'), findsOneWidget);
    });

    testWidgets('tapping Search tab shows search screen', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Search'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Search'), findsWidgets);
    });

    testWidgets('tapping Add tab shows capture option sheet', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Add'));
      // Pump enough frames for the bottom sheet animation to complete.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // CaptureOptionSheet displays these options
      expect(find.text('Add Receipt'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(find.text('Import Files'), findsOneWidget);
    });
  });
}
