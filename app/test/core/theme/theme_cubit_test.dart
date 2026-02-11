import 'package:flutter_test/flutter_test.dart';
import 'package:warrantyvault/core/theme/theme_cubit.dart';
import 'package:warrantyvault/core/theme/theme_state.dart';

void main() {
  group('ThemeCubit', () {
    late ThemeCubit cubit;

    setUp(() {
      cubit = ThemeCubit();
    });

    tearDown(() => cubit.close());

    test('initial state is AppThemeMode.system', () {
      expect(cubit.state.mode, AppThemeMode.system);
    });

    test('changeTheme emits new mode', () {
      cubit.changeTheme(AppThemeMode.dark);
      expect(cubit.state.mode, AppThemeMode.dark);
    });

    test('changeTheme to light', () {
      cubit.changeTheme(AppThemeMode.light);
      expect(cubit.state.mode, AppThemeMode.light);
    });

    test('changeTheme back to system', () {
      cubit.changeTheme(AppThemeMode.dark);
      cubit.changeTheme(AppThemeMode.system);
      expect(cubit.state.mode, AppThemeMode.system);
    });

    group('loadSavedTheme', () {
      test('loads dark theme from string', () {
        cubit.loadSavedTheme('dark');
        expect(cubit.state.mode, AppThemeMode.dark);
      });

      test('loads light theme from string', () {
        cubit.loadSavedTheme('light');
        expect(cubit.state.mode, AppThemeMode.light);
      });

      test('loads system theme from string', () {
        cubit.changeTheme(AppThemeMode.dark);
        cubit.loadSavedTheme('system');
        expect(cubit.state.mode, AppThemeMode.system);
      });

      test('ignores null value', () {
        cubit.loadSavedTheme(null);
        expect(cubit.state.mode, AppThemeMode.system);
      });

      test('ignores invalid value', () {
        cubit.loadSavedTheme('invalid_theme');
        expect(cubit.state.mode, AppThemeMode.system);
      });
    });
  });

  group('ThemeState', () {
    test('initial factory produces system mode', () {
      final state = ThemeState.initial();
      expect(state.mode, AppThemeMode.system);
    });

    test('copyWith creates new instance with updated mode', () {
      const original = ThemeState(mode: AppThemeMode.light);
      final copied = original.copyWith(mode: AppThemeMode.dark);
      expect(copied.mode, AppThemeMode.dark);
      expect(original.mode, AppThemeMode.light);
    });

    test('copyWith with no args returns equal instance', () {
      const original = ThemeState(mode: AppThemeMode.light);
      final copied = original.copyWith();
      expect(copied, equals(original));
    });

    test('equality based on mode', () {
      const a = ThemeState(mode: AppThemeMode.dark);
      const b = ThemeState(mode: AppThemeMode.dark);
      const c = ThemeState(mode: AppThemeMode.light);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
