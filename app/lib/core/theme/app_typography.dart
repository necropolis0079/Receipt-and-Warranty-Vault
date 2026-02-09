import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

abstract final class AppTypography {
  static TextTheme get textTheme {
    return TextTheme(
      // Display styles — DM Serif Display
      displayLarge: _heading(57, 64, FontWeight.w400),
      displayMedium: _heading(45, 52, FontWeight.w400),
      displaySmall: _heading(36, 44, FontWeight.w400),

      // Headline styles — DM Serif Display
      headlineLarge: _heading(32, 40, FontWeight.w400),
      headlineMedium: _heading(28, 36, FontWeight.w400),
      headlineSmall: _heading(24, 32, FontWeight.w400),

      // Title styles — Plus Jakarta Sans (semi-bold)
      titleLarge: _body(22, 28, FontWeight.w600),
      titleMedium: _body(16, 24, FontWeight.w600),
      titleSmall: _body(14, 20, FontWeight.w600),

      // Body styles — Plus Jakarta Sans
      bodyLarge: _body(16, 24, FontWeight.w400),
      bodyMedium: _body(14, 20, FontWeight.w400),
      bodySmall: _body(12, 16, FontWeight.w400),

      // Label styles — Plus Jakarta Sans (medium)
      labelLarge: _body(14, 20, FontWeight.w500),
      labelMedium: _body(12, 16, FontWeight.w500),
      labelSmall: _body(11, 16, FontWeight.w500),
    );
  }

  static TextStyle _heading(double size, double height, FontWeight weight) {
    return GoogleFonts.dmSerifDisplay(
      fontSize: size,
      height: height / size,
      fontWeight: weight,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle _body(double size, double height, FontWeight weight) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      height: height / size,
      fontWeight: weight,
      color: AppColors.textPrimary,
    );
  }
}
