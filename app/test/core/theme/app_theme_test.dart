import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warrantyvault/core/constants/app_colors.dart';
import 'package:warrantyvault/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    late ThemeData theme;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      // GoogleFonts fires async HTTP requests to load fonts. Under
      // TestWidgetsFlutterBinding the HTTP client returns 400, producing
      // unhandled async errors that fail the test. Wrapping theme creation
      // in runZonedGuarded catches those errors in a separate error zone.
      runZonedGuarded(() {
        theme = AppTheme.light();
      }, (_, __) {});
    });

    test('creates ThemeData without exceptions', () {
      expect(theme, isA<ThemeData>());
    });

    test('uses Material 3', () {
      expect(theme.useMaterial3, isTrue);
    });

    group('ColorScheme', () {
      test('has correct primary color', () {
        expect(theme.colorScheme.primary, equals(AppColors.primaryGreen));
        expect(theme.colorScheme.primary, equals(const Color(0xFF2D5A3D)));
      });

      test('has correct secondary color', () {
        expect(theme.colorScheme.secondary, equals(AppColors.accentAmber));
        expect(theme.colorScheme.secondary, equals(const Color(0xFFD4920B)));
      });

      test('has correct error color', () {
        expect(theme.colorScheme.error, equals(AppColors.error));
        expect(theme.colorScheme.error, equals(const Color(0xFFC0392B)));
      });

      test('has correct surface color', () {
        expect(theme.colorScheme.surface, equals(AppColors.surface));
      });

      test('has white onPrimary', () {
        expect(theme.colorScheme.onPrimary, equals(AppColors.white));
      });
    });

    group('Scaffold', () {
      test('background color is cream (#FAF7F2)', () {
        expect(
          theme.scaffoldBackgroundColor,
          equals(const Color(0xFFFAF7F2)),
        );
        expect(theme.scaffoldBackgroundColor, equals(AppColors.cream));
      });
    });

    group('TextTheme', () {
      test('has all text styles defined', () {
        expect(theme.textTheme.displayLarge, isNotNull);
        expect(theme.textTheme.displayMedium, isNotNull);
        expect(theme.textTheme.displaySmall, isNotNull);
        expect(theme.textTheme.headlineLarge, isNotNull);
        expect(theme.textTheme.headlineMedium, isNotNull);
        expect(theme.textTheme.headlineSmall, isNotNull);
        expect(theme.textTheme.titleLarge, isNotNull);
        expect(theme.textTheme.titleMedium, isNotNull);
        expect(theme.textTheme.titleSmall, isNotNull);
        expect(theme.textTheme.bodyLarge, isNotNull);
        expect(theme.textTheme.bodyMedium, isNotNull);
        expect(theme.textTheme.bodySmall, isNotNull);
        expect(theme.textTheme.labelLarge, isNotNull);
        expect(theme.textTheme.labelMedium, isNotNull);
        expect(theme.textTheme.labelSmall, isNotNull);
      });

      test('English heading styles use DM Serif Display font family', () {
        final displayLarge = theme.textTheme.displayLarge!;
        final headlineMedium = theme.textTheme.headlineMedium!;
        expect(displayLarge.fontFamily, contains('DMSerifDisplay'));
        expect(headlineMedium.fontFamily, contains('DMSerifDisplay'));
      });

      test('English body styles use Plus Jakarta Sans font family', () {
        final bodyMedium = theme.textTheme.bodyMedium!;
        final labelLarge = theme.textTheme.labelLarge!;
        expect(bodyMedium.fontFamily, contains('PlusJakartaSans'));
        expect(labelLarge.fontFamily, contains('PlusJakartaSans'));
      });

      test('English title styles use Plus Jakarta Sans font family', () {
        final titleLarge = theme.textTheme.titleLarge!;
        expect(titleLarge.fontFamily, contains('PlusJakartaSans'));
      });
    });

    group('Greek locale TextTheme', () {
      late ThemeData greekTheme;

      setUpAll(() {
        runZonedGuarded(() {
          greekTheme = AppTheme.light(locale: 'el');
        }, (_, __) {});
      });

      test('Greek heading styles use Noto Serif font family', () {
        final displayLarge = greekTheme.textTheme.displayLarge!;
        final headlineMedium = greekTheme.textTheme.headlineMedium!;
        expect(displayLarge.fontFamily, contains('NotoSerif'));
        expect(headlineMedium.fontFamily, contains('NotoSerif'));
      });

      test('Greek body styles use Noto Sans font family', () {
        final bodyMedium = greekTheme.textTheme.bodyMedium!;
        final labelLarge = greekTheme.textTheme.labelLarge!;
        expect(bodyMedium.fontFamily, contains('NotoSans'));
        expect(labelLarge.fontFamily, contains('NotoSans'));
      });

      test('Greek title styles use Noto Sans font family', () {
        final titleLarge = greekTheme.textTheme.titleLarge!;
        expect(titleLarge.fontFamily, contains('NotoSans'));
      });
    });

    group('AppBar', () {
      test('has cream background', () {
        expect(theme.appBarTheme.backgroundColor, equals(AppColors.background));
      });

      test('has zero elevation', () {
        expect(theme.appBarTheme.elevation, equals(0));
      });
    });

    group('Card', () {
      test('has white surface color', () {
        expect(theme.cardTheme.color, equals(AppColors.surface));
      });
    });

    group('Input Decoration', () {
      test('has filled text fields', () {
        expect(theme.inputDecorationTheme.filled, isTrue);
      });

      test('has white fill color', () {
        expect(theme.inputDecorationTheme.fillColor, equals(AppColors.white));
      });
    });

    group('Box Decorations', () {
      test('cardDecoration has correct color and radius', () {
        final decoration = AppTheme.cardDecoration;
        expect(decoration.color, equals(AppColors.surface));
        expect(decoration.borderRadius, isNotNull);
      });

      test('elevatedCardDecoration has shadows', () {
        final decoration = AppTheme.elevatedCardDecoration;
        expect(decoration.boxShadow, isNotNull);
        expect(decoration.boxShadow!.isNotEmpty, isTrue);
      });
    });
  });
}
