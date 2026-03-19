import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light(BuildContext context) {
    return _buildTheme(context, Brightness.light, AppColors.light);
  }

  static ThemeData dark(BuildContext context) {
    return _buildTheme(context, Brightness.dark, AppColors.dark);
  }

  static ThemeData _buildTheme(BuildContext context, Brightness brightness, AppColorsExtension colors) {
    return ThemeData(
      useMaterial3: true,
      extensions: [colors],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.charcoal,
        onPrimary: colors.cream,
        secondary: colors.bioAccent,
        onSecondary: colors.cream,
        error: AppColors.errorRed,
        onError: colors.cream,
        surface: colors.paper,
        onSurface: colors.charcoal,
      ),
      scaffoldBackgroundColor: colors.paper,
      textTheme: AppTypography.textThemeFromColors(colors),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.paper,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: colors.charcoal),
        titleTextStyle: AppTypography.textThemeFromColors(colors).titleLarge?.copyWith(
          color: colors.charcoal,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.charcoal;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(colors.cream),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: colors.charcoal, width: 1.5),
      ),
            snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.glassFill,
        contentTextStyle: TextStyle(color: colors.charcoal, fontFamily: 'Inter'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.glassBorder, width: 1),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.cardSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colors.borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colors.charcoal, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        hintStyle: AppTypography.textTheme(context).bodyMedium?.copyWith(
          color: colors.mutedText,
        ),
      ),
    );
  }
}

