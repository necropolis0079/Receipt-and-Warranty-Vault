import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warrantyvault/core/security/app_lock_cubit.dart';
import 'package:warrantyvault/core/security/app_lock_service.dart';
import 'package:warrantyvault/core/security/lock_screen.dart';

class MockAppLockService extends Mock implements AppLockService {}

void main() {
  late MockAppLockService mockService;
  late AppLockCubit cubit;

  setUp(() {
    mockService = MockAppLockService();
    when(() => mockService.isDeviceSupported())
        .thenAnswer((_) async => true);
    cubit = AppLockCubit(appLockService: mockService);
  });

  tearDown(() => cubit.close());

  Widget buildApp() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: BlocProvider.value(
        value: cubit,
        child: const LockScreen(),
      ),
    );
  }

  testWidgets('displays lock icon', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.lock_outlined), findsOneWidget);
  });

  testWidgets('displays lock title text', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(find.text('App Locked'), findsOneWidget);
  });

  testWidgets('displays unlock button', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(find.text('Unlock'), findsOneWidget);
  });

  testWidgets('tapping unlock calls authenticate', (tester) async {
    when(() => mockService.authenticate(
          localizedReason: any(named: 'localizedReason'),
        )).thenAnswer((_) async => true);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();

    verify(() => mockService.authenticate(
          localizedReason: any(named: 'localizedReason'),
        )).called(1);
  });

  testWidgets('shows snackbar on auth failure', (tester) async {
    when(() => mockService.authenticate(
          localizedReason: any(named: 'localizedReason'),
        )).thenAnswer((_) async => false);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();

    expect(find.text('Authentication failed. Please try again.'),
        findsOneWidget);
  });
}
