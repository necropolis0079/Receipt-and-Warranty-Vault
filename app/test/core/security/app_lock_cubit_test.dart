import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warrantyvault/core/security/app_lock_cubit.dart';
import 'package:warrantyvault/core/security/app_lock_service.dart';
import 'package:warrantyvault/core/security/app_lock_state.dart';

class MockAppLockService extends Mock implements AppLockService {}

void main() {
  late MockAppLockService mockService;

  setUp(() {
    mockService = MockAppLockService();
  });

  group('AppLockCubit', () {
    test('initial state is correct', () {
      final cubit = AppLockCubit(appLockService: mockService);
      expect(cubit.state, AppLockState.initial());
      expect(cubit.state.isEnabled, false);
      expect(cubit.state.isLocked, false);
      expect(cubit.state.timeout, LockTimeout.immediate);
      expect(cubit.state.isDeviceSupported, false);
      cubit.close();
    });

    // --- checkDeviceSupport ---
    blocTest<AppLockCubit, AppLockState>(
      'checkDeviceSupport emits isDeviceSupported=true when supported',
      build: () {
        when(() => mockService.isDeviceSupported())
            .thenAnswer((_) async => true);
        return AppLockCubit(appLockService: mockService);
      },
      act: (cubit) => cubit.checkDeviceSupport(),
      expect: () => [
        AppLockState.initial().copyWith(isDeviceSupported: true),
      ],
    );

    blocTest<AppLockCubit, AppLockState>(
      'checkDeviceSupport emits isDeviceSupported=false when unsupported',
      build: () {
        when(() => mockService.isDeviceSupported())
            .thenAnswer((_) async => false);
        return AppLockCubit(appLockService: mockService);
      },
      act: (cubit) => cubit.checkDeviceSupport(),
      expect: () => [
        AppLockState.initial().copyWith(isDeviceSupported: false),
      ],
    );

    // --- enable ---
    blocTest<AppLockCubit, AppLockState>(
      'enable sets isEnabled=true when device supports it',
      build: () {
        when(() => mockService.isDeviceSupported())
            .thenAnswer((_) async => true);
        return AppLockCubit(appLockService: mockService);
      },
      act: (cubit) async {
        final result = await cubit.enable();
        expect(result, true);
      },
      expect: () => [
        AppLockState.initial()
            .copyWith(isEnabled: true, isDeviceSupported: true),
      ],
    );

    blocTest<AppLockCubit, AppLockState>(
      'enable returns false when device does not support it',
      build: () {
        when(() => mockService.isDeviceSupported())
            .thenAnswer((_) async => false);
        return AppLockCubit(appLockService: mockService);
      },
      act: (cubit) async {
        final result = await cubit.enable();
        expect(result, false);
      },
      expect: () => <AppLockState>[],
    );

    // --- disable ---
    blocTest<AppLockCubit, AppLockState>(
      'disable sets isEnabled=false and isLocked=false',
      build: () {
        when(() => mockService.isDeviceSupported())
            .thenAnswer((_) async => true);
        return AppLockCubit(appLockService: mockService);
      },
      seed: () => AppLockState.initial().copyWith(
        isEnabled: true,
        isLocked: true,
        isDeviceSupported: true,
      ),
      act: (cubit) => cubit.disable(),
      expect: () => [
        AppLockState.initial().copyWith(
          isEnabled: false,
          isLocked: false,
          isDeviceSupported: true,
        ),
      ],
    );

    // --- setTimeout ---
    blocTest<AppLockCubit, AppLockState>(
      'setTimeout changes the timeout setting',
      build: () => AppLockCubit(appLockService: mockService),
      act: (cubit) => cubit.setTimeout(LockTimeout.after5Min),
      expect: () => [
        AppLockState.initial().copyWith(timeout: LockTimeout.after5Min),
      ],
    );

    // --- onAppResumed ---
    blocTest<AppLockCubit, AppLockState>(
      'onAppResumed does nothing when not enabled',
      build: () => AppLockCubit(appLockService: mockService),
      act: (cubit) => cubit.onAppResumed(),
      expect: () => <AppLockState>[],
    );

    blocTest<AppLockCubit, AppLockState>(
      'onAppResumed locks when enabled and no pause recorded',
      build: () => AppLockCubit(appLockService: mockService),
      seed: () => AppLockState.initial().copyWith(
        isEnabled: true,
        isDeviceSupported: true,
      ),
      act: (cubit) => cubit.onAppResumed(),
      expect: () => [
        AppLockState.initial().copyWith(
          isEnabled: true,
          isLocked: true,
          isDeviceSupported: true,
        ),
      ],
    );

    blocTest<AppLockCubit, AppLockState>(
      'onAppResumed locks immediately when timeout is immediate',
      build: () => AppLockCubit(appLockService: mockService),
      seed: () => AppLockState.initial().copyWith(
        isEnabled: true,
        isDeviceSupported: true,
        timeout: LockTimeout.immediate,
      ),
      act: (cubit) {
        cubit.onAppPaused();
        cubit.onAppResumed();
      },
      expect: () => [
        AppLockState.initial().copyWith(
          isEnabled: true,
          isLocked: true,
          isDeviceSupported: true,
          timeout: LockTimeout.immediate,
        ),
      ],
    );

    // --- unlock ---
    blocTest<AppLockCubit, AppLockState>(
      'unlock sets isLocked=false on success',
      build: () {
        when(() => mockService.authenticate(
              localizedReason: any(named: 'localizedReason'),
            )).thenAnswer((_) async => true);
        return AppLockCubit(appLockService: mockService);
      },
      seed: () => AppLockState.initial().copyWith(
        isEnabled: true,
        isLocked: true,
        isDeviceSupported: true,
      ),
      act: (cubit) async {
        final result = await cubit.unlock(localizedReason: 'test');
        expect(result, true);
      },
      expect: () => [
        AppLockState.initial().copyWith(
          isEnabled: true,
          isLocked: false,
          isDeviceSupported: true,
        ),
      ],
    );

    blocTest<AppLockCubit, AppLockState>(
      'unlock keeps isLocked=true on failure',
      build: () {
        when(() => mockService.authenticate(
              localizedReason: any(named: 'localizedReason'),
            )).thenAnswer((_) async => false);
        return AppLockCubit(appLockService: mockService);
      },
      seed: () => AppLockState.initial().copyWith(
        isEnabled: true,
        isLocked: true,
        isDeviceSupported: true,
      ),
      act: (cubit) async {
        final result = await cubit.unlock(localizedReason: 'test');
        expect(result, false);
      },
      expect: () => <AppLockState>[],
    );
  });
}
