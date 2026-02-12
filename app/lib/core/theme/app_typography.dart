import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

abstract final class AppTypography {
  static TextTheme textTheme({String locale = 'en'}) {
    final bool isGreek = locale == 'el';
    return TextTheme(
      // Display styles — DM Serif Display / Noto Serif (Greek)
      displayLarge: _heading(57, 64, FontWeight.w400, isGreek),
      displayMedium: _heading(45, 52, FontWeight.w400, isGreek),
      displaySmall: _heading(36, 44, FontWeight.w400, isGreek),

      // Headline styles — DM Serif Display / Noto Serif (Greek)
      headlineLarge: _heading(32, 40, FontWeight.w400, isGreek),
      headlineMedium: _heading(28, 36, FontWeight.w400, isGreek),
      headlineSmall: _heading(24, 32, FontWeight.w400, isGreek),

      // Title styles — Plus Jakarta Sans / Noto Sans (Greek) (semi-bold)
      titleLarge: _body(22, 28, FontWeight.w600, isGreek),
      titleMedium: _body(16, 24, FontWeight.w600, isGreek),
      titleSmall: _body(14, 20, FontWeight.w600, isGreek),

      // Body styles — Plus Jakarta Sans / Noto Sans (Greek)
      bodyLarge: _body(16, 24, FontWeight.w400, isGreek),
      bodyMedium: _body(14, 20, FontWeight.w400, isGreek),
      bodySmall: _body(12, 16, FontWeight.w400, isGreek),

      // Label styles — Plus Jakarta Sans / Noto Sans (Greek) (medium)
      labelLarge: _body(14, 20, FontWeight.w500, isGreek),
      labelMedium: _body(12, 16, FontWeight.w500, isGreek),
      labelSmall: _body(11, 16, FontWeight.w500, isGreek),
    );
  }

  static TextStyle _heading(
    double size,
    double height,
    FontWeight weight,
    bool greek,
  ) {
    if (greek) {
      return GoogleFonts.notoSerif(
        fontSize: size,
        height: height / size,
        fontWeight: weight,
        color: AppColors.textPrimary,
      );
    }
    return GoogleFonts.dmSerifDisplay(
      fontSize: size,
      height: height / size,
      fontWeight: weight,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle _body(
    double size,
    double height,
    FontWeight weight,
    bool greek,
  ) {
    if (greek) {
      return GoogleFonts.notoSans(
        fontSize: size,
        height: height / size,
        fontWeight: weight,
        color: AppColors.textPrimary,
      );
    }
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      height: height / size,
      fontWeight: weight,
      color: AppColors.textPrimary,
    );
  }
}
