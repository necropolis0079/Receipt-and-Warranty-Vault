import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand colors
  static const Color cream = Color(0xFFFAF7F2);
  static const Color primaryGreen = Color(0xFF2D5A3D);
  static const Color accentAmber = Color(0xFFD4920B);
  static const Color error = Color(0xFFC0392B);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE5E7EB);

  // Derived / surface
  static const Color surface = white;
  static const Color background = cream;
  static const Color onPrimary = white;
  static const Color onSecondary = white;
  static const Color onError = white;
  static const Color onSurface = textPrimary;
  static const Color onBackground = textPrimary;

  // Primary variants
  static const Color primaryLight = Color(0xFF3E7A52);
  static const Color primaryDark = Color(0xFF1E3D29);

  // Accent variants
  static const Color accentLight = Color(0xFFF0B840);
  static const Color accentDark = Color(0xFFB07A09);

  // Material ColorScheme helper
  static ColorScheme get lightColorScheme => const ColorScheme.light(
        primary: primaryGreen,
        onPrimary: onPrimary,
        primaryContainer: primaryLight,
        onPrimaryContainer: white,
        secondary: accentAmber,
        onSecondary: onSecondary,
        secondaryContainer: accentLight,
        onSecondaryContainer: textPrimary,
        tertiary: accentAmber,
        onTertiary: white,
        error: error,
        onError: onError,
        surface: surface,
        onSurface: onSurface,
        surfaceContainerHighest: cream,
        outline: divider,
        outlineVariant: divider,
      );
}
