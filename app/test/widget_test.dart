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

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAppLockService extends Mock implements AppLockService {}

/// Smoke test — verifies the app's navigation shell renders without errors.
void main() {
  testWidgets('App shell renders the bottom navigation bar', (tester) async {
    final mockRepo = MockAuthRepository();
    final mockLockService = MockAppLockService();
    when(() => mockLockService.isDeviceSupported())
        .thenAnswer((_) async => false);
    when(() => mockRepo.getCurrentUser()).thenAnswer((_) async => null);

    final authBloc = AuthBloc(authRepository: mockRepo);
    final lockCubit = AppLockCubit(appLockService: mockLockService);

    addTearDown(() {
      authBloc.close();
      lockCubit.close();
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
          ],
          child: const AppShell(),
        ),
      ),
    );

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
  });
}
