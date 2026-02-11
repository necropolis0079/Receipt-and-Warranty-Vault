import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warrantyvault/core/l10n/locale_cubit.dart';
import 'package:warrantyvault/core/security/app_lock_cubit.dart';
import 'package:warrantyvault/core/security/app_lock_service.dart';
import 'package:warrantyvault/core/services/home_widget_service.dart';
import 'package:warrantyvault/core/theme/theme_cubit.dart';
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

class MockHomeWidgetService extends Mock implements HomeWidgetService {}

/// Smoke test — verifies the app's navigation shell renders without errors.
void main() {
  testWidgets('App shell renders the bottom navigation bar', (tester) async {
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

    // Register HomeWidgetService mock in GetIt.
    final getIt = GetIt.instance;
    await getIt.reset();
    final mockHomeWidget = MockHomeWidgetService();
    when(() => mockHomeWidget.consumePendingUri()).thenReturn(null);
    when(() => mockHomeWidget.widgetClickStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockHomeWidget.updateStats(any()))
        .thenAnswer((_) async {});
    getIt.registerSingleton<HomeWidgetService>(mockHomeWidget);

    final authBloc = AuthBloc(authRepository: mockRepo);
    final lockCubit = AppLockCubit(appLockService: mockLockService);
    final vaultBloc = VaultBloc(receiptRepository: mockReceiptRepo);
    final expiringBloc = ExpiringBloc(receiptRepository: mockReceiptRepo);
    final searchBloc =
        SearchBloc(receiptRepository: mockReceiptRepo, userId: 'test');
    final localeCubit = LocaleCubit();
    final themeCubit = ThemeCubit();

    addTearDown(() async {
      authBloc.close();
      lockCubit.close();
      vaultBloc.close();
      expiringBloc.close();
      searchBloc.close();
      localeCubit.close();
      themeCubit.close();
      await getIt.reset();
    });

    await tester.pumpWidget(
      MaterialApp(
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
          child: const AppShell(),
        ),
      ),
    );

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
  });
}
