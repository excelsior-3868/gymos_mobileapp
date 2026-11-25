import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand colors
  static const Color primary = Color(0xFF0057A3);
  static const Color primaryDark = Color(0xFF003D75);
  static const Color primaryDeep = Color(0xFF00264A);
  static const Color primarySoft = Color(0xFFE6F0FA);
  static const Color accent = Color(0xFF00A6D6);

  // Backgrounds & Surfaces
  static const Color bg = Color(0xFFF4F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFEEF3F9);
  static const Color border = Color(0xFFE1E8F0);

  // Text
  static const Color text = Color(0xFF0B1B2E);
  static const Color textMuted = Color(0xFF5B6B7F);
  static const Color textFaint = Color(0xFF93A1B3);

  // Status Colors
  static const Color success = Color(0xFF12A150);
  static const Color successSoft = Color(0xFFE3F6EB);
  static const Color warning = Color(0xFFE08A00);
  static const Color warningSoft = Color(0xFFFFF2DB);
  static const Color danger = Color(0xFFD93B3B);
  static const Color dangerSoft = Color(0xFFFDE7E7);
  static const Color info = Color(0xFF2F6FED);
  static const Color infoSoft = Color(0xFFE5EDFD);
}

class AppRadius {
  static const double sm = 10.0;
  static const double md = 14.0;
  static const double lg = 20.0;
  static const double xl = 28.0;
  static const double pill = 999.0;
}

class AppTheme {
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.outfitTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
      textTheme: textTheme.copyWith(
        headlineLarge: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
          letterSpacing: -0.4,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
        headlineSmall: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.text,
          height: 1.45,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
        ),
        labelSmall: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: AppColors.textMuted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.text),
      ),
    );
  }
}
