import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SpiceColors {
  static const primary = Color(0xFF1E40AF);
  static const primaryLight = Color(0xFF3B82F6);
  static const primaryBg = Color(0xFFEFF6FF);

  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF8FAFC);
  static const cardBorder = Color(0xFFE2E8F0);

  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textTertiary = Color(0xFF94A3B8);

  static const success = Color(0xFF059669);
  static const successBg = Color(0xFFECFDF5);
  static const warning = Color(0xFFD97706);
  static const warningBg = Color(0xFFFFFBEB);
  static const error = Color(0xFFDC2626);
  static const errorBg = Color(0xFFFEF2F2);

  static const darkSurface = Color(0xFF0F172A);
  static const darkCard = Color(0xFF1E293B);
  static const darkBorder = Color(0xFF334155);
  static const darkText = Color(0xFFF1F5F9);
  static const darkTextSecondary = Color(0xFF94A3B8);
}

enum AppThemeMode { light, dark }

class AppTheme {
  static ThemeData build(AppThemeMode mode) {
    return mode == AppThemeMode.dark ? _dark() : _light();
  }

  static ThemeData _light() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: SpiceColors.primary,
      onPrimary: Colors.white,
      surface: SpiceColors.surface,
      error: SpiceColors.error,
    ),
    scaffoldBackgroundColor: SpiceColors.surfaceAlt,
    dividerTheme: const DividerThemeData(color: SpiceColors.cardBorder, thickness: 1, space: 0),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      backgroundColor: SpiceColors.surface,
      foregroundColor: SpiceColors.textPrimary,
      titleTextStyle: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: SpiceColors.textPrimary),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: SpiceColors.surface,
      indicatorColor: SpiceColors.primaryBg,
      elevation: 2,
      height: 64,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(color: s.contains(WidgetState.selected) ? SpiceColors.primary : SpiceColors.textSecondary, size: 22)),
      labelTextStyle: WidgetStateProperty.resolveWith((s) => GoogleFonts.inter(fontSize: 11, fontWeight: s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500, color: s.contains(WidgetState.selected) ? SpiceColors.primary : SpiceColors.textSecondary)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: SpiceColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: SpiceColors.cardBorder)),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: SpiceColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: SpiceColors.primary,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: SpiceColors.cardBorder)),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: SpiceColors.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: SpiceColors.cardBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: SpiceColors.cardBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: SpiceColors.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: SpiceColors.error)),
    ),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
    floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: SpiceColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    dialogTheme: DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      headlineLarge: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: SpiceColors.textPrimary, letterSpacing: -0.5),
      headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: SpiceColors.textPrimary, letterSpacing: -0.3),
      titleLarge: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: SpiceColors.textPrimary),
      titleMedium: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: SpiceColors.textPrimary),
      titleSmall: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary, letterSpacing: 0.5),
      bodyLarge: GoogleFonts.inter(fontSize: 15, color: SpiceColors.textPrimary),
      bodyMedium: GoogleFonts.inter(fontSize: 13, color: SpiceColors.textSecondary),
      bodySmall: GoogleFonts.inter(fontSize: 12, color: SpiceColors.textTertiary),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0),
      labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),
    ),
  );

  static ThemeData _dark() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: SpiceColors.primaryLight,
      onPrimary: Colors.white,
      surface: SpiceColors.darkSurface,
      error: SpiceColors.error,
    ),
    scaffoldBackgroundColor: SpiceColors.darkSurface,
    dividerTheme: const DividerThemeData(color: SpiceColors.darkBorder, thickness: 1, space: 0),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      backgroundColor: SpiceColors.darkSurface,
      foregroundColor: SpiceColors.darkText,
      titleTextStyle: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: SpiceColors.darkText),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: SpiceColors.darkSurface,
      indicatorColor: SpiceColors.darkCard,
      elevation: 2,
      height: 64,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(color: s.contains(WidgetState.selected) ? SpiceColors.primaryLight : SpiceColors.darkTextSecondary, size: 22)),
      labelTextStyle: WidgetStateProperty.resolveWith((s) => GoogleFonts.inter(fontSize: 11, fontWeight: s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500, color: s.contains(WidgetState.selected) ? SpiceColors.primaryLight : SpiceColors.darkTextSecondary)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: SpiceColors.darkCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: SpiceColors.darkBorder)),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: SpiceColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: SpiceColors.primaryLight,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: SpiceColors.darkBorder)),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: SpiceColors.darkCard,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: SpiceColors.darkBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: SpiceColors.darkBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: SpiceColors.primaryLight, width: 1.5)),
    ),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
    floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: SpiceColors.primaryLight, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    dialogTheme: DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      headlineLarge: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: SpiceColors.darkText, letterSpacing: -0.5),
      headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: SpiceColors.darkText, letterSpacing: -0.3),
      titleLarge: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: SpiceColors.darkText),
      titleMedium: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: SpiceColors.darkText),
      titleSmall: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: SpiceColors.darkTextSecondary, letterSpacing: 0.5),
      bodyLarge: GoogleFonts.inter(fontSize: 15, color: SpiceColors.darkText),
      bodyMedium: GoogleFonts.inter(fontSize: 13, color: SpiceColors.darkTextSecondary),
      bodySmall: GoogleFonts.inter(fontSize: 12, color: SpiceColors.darkTextSecondary),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0),
      labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),
    ),
  );
}
