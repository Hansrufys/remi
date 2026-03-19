import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextTheme textTheme(BuildContext context) {
    return textThemeFromColors(AppColors.of(context));
  }

  static TextTheme textThemeFromColors(AppColorsExtension colors) {
    final base = GoogleFonts.interTextTheme();
    return base.copyWith(
      // Display: For large hero text, Nanum Pen Script handwriting feel
      displayLarge: GoogleFonts.nanumPenScript(
        color: colors.charcoal,
        fontSize: 48,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.nanumPenScript(
        color: colors.charcoal,
        fontSize: 36,
      ),
      // Headline: Section headers
      headlineLarge: GoogleFonts.inter(
        color: colors.charcoal,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      headlineMedium: GoogleFonts.inter(
        color: colors.charcoal,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      headlineSmall: GoogleFonts.inter(
        color: colors.charcoal,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      // Title: App bar, card headers
      titleLarge: GoogleFonts.inter(
        color: colors.charcoal,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      titleMedium: GoogleFonts.inter(
        color: colors.charcoal,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      // Body: Main journal entries
      bodyLarge: GoogleFonts.inter(
        color: colors.charcoal,
        fontSize: 17,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.01,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        color: colors.inkLight,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        color: colors.mutedText,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      // Label: Chips, tags, pills
      labelLarge: GoogleFonts.inter(
        color: colors.charcoal,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.inter(
        color: colors.mutedText,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      ),
      labelSmall: GoogleFonts.inter(
        color: colors.mutedText,
        fontSize: 10,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
      ),
    );
  }

  // Handwriting style for journal entry text
  static TextStyle handwritten(BuildContext context) => 
      handwrittenFromColors(AppColors.of(context));

  static TextStyle handwrittenFromColors(AppColorsExtension colors) => GoogleFonts.nanumPenScript(
    fontSize: 20,
    color: colors.charcoal,
    letterSpacing: 0.3,
    height: 1.6,
  );

  // Intelligence margin metadata style
  static TextStyle marginMeta(BuildContext context) => 
      marginMetaFromColors(AppColors.of(context));

  static TextStyle marginMetaFromColors(AppColorsExtension colors) => GoogleFonts.inter(
    fontSize: 11,
    color: colors.mutedText,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );
}
