import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warrantyvault/core/constants/app_colors.dart';

void main() {
  group('AppColors', () {
    group('Brand colors', () {
      test('cream is #FAF7F2', () {
        expect(AppColors.cream, equals(const Color(0xFFFAF7F2)));
      });

      test('primaryGreen is #2D5A3D', () {
        expect(AppColors.primaryGreen, equals(const Color(0xFF2D5A3D)));
      });

      test('accentAmber is #D4920B', () {
        expect(AppColors.accentAmber, equals(const Color(0xFFD4920B)));
      });

      test('error is #C0392B', () {
        expect(AppColors.error, equals(const Color(0xFFC0392B)));
      });
    });

    group('Neutrals', () {
      test('white is #FFFFFF', () {
        expect(AppColors.white, equals(const Color(0xFFFFFFFF)));
      });

      test('textPrimary is #1A1A1A', () {
        expect(AppColors.textPrimary, equals(const Color(0xFF1A1A1A)));
      });

      test('textSecondary is #6B7280', () {
        expect(AppColors.textSecondary, equals(const Color(0xFF6B7280)));
      });

      test('divider is #E5E7EB', () {
        expect(AppColors.divider, equals(const Color(0xFFE5E7EB)));
      });
    });

    group('Derived colors', () {
      test('surface equals white', () {
        expect(AppColors.surface, equals(AppColors.white));
      });

      test('background equals cream', () {
        expect(AppColors.background, equals(AppColors.cream));
      });

      test('onPrimary equals white', () {
        expect(AppColors.onPrimary, equals(AppColors.white));
      });

      test('onSecondary equals white', () {
        expect(AppColors.onSecondary, equals(AppColors.white));
      });

      test('onError equals white', () {
        expect(AppColors.onError, equals(AppColors.white));
      });

      test('onSurface equals textPrimary', () {
        expect(AppColors.onSurface, equals(AppColors.textPrimary));
      });

      test('onBackground equals textPrimary', () {
        expect(AppColors.onBackground, equals(AppColors.textPrimary));
      });
    });

    group('Primary variants', () {
      test('primaryLight is #3E7A52', () {
        expect(AppColors.primaryLight, equals(const Color(0xFF3E7A52)));
      });

      test('primaryDark is #1E3D29', () {
        expect(AppColors.primaryDark, equals(const Color(0xFF1E3D29)));
      });
    });

    group('Accent variants', () {
      test('accentLight is #F0B840', () {
        expect(AppColors.accentLight, equals(const Color(0xFFF0B840)));
      });

      test('accentDark is #B07A09', () {
        expect(AppColors.accentDark, equals(const Color(0xFFB07A09)));
      });
    });

    group('ColorScheme', () {
      test('lightColorScheme creates a valid ColorScheme', () {
        final scheme = AppColors.lightColorScheme;
        expect(scheme, isA<ColorScheme>());
        expect(scheme.brightness, equals(Brightness.light));
      });

      test('lightColorScheme has correct primary', () {
        expect(AppColors.lightColorScheme.primary, equals(AppColors.primaryGreen));
      });

      test('lightColorScheme has correct secondary', () {
        expect(AppColors.lightColorScheme.secondary, equals(AppColors.accentAmber));
      });

      test('lightColorScheme has correct error', () {
        expect(AppColors.lightColorScheme.error, equals(AppColors.error));
      });

      test('lightColorScheme has correct surface', () {
        expect(AppColors.lightColorScheme.surface, equals(AppColors.surface));
      });
    });
  });
}
