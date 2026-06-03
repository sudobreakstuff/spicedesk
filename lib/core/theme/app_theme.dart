import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _primary = Color(0xFF6366F1);
const _surface = Color(0xFF0D1117);
const _surfaceAlt = Color(0xFF161B22);
const _border = Color(0xFF30363D);
const _textPrimary = Color(0xFFE6EDF3);
const _textSecondary = Color(0xFF8B949E);
const _accent = Color(0xFF238636);
const _danger = Color(0xFFDA3633);
const _warning = Color(0xFFD29922);

final appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: _surface,
  colorScheme: const ColorScheme.dark(
    primary: _primary,
    secondary: _accent,
    surface: _surfaceAlt,
    error: _danger,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: _textPrimary,
    onError: Colors.white,
  ),
  textTheme: GoogleFonts.interTextTheme(
    ThemeData.dark().textTheme,
  ).copyWith(
    headlineLarge: GoogleFonts.inter(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: _textPrimary,
      letterSpacing: -0.5,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: _textPrimary,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: _textPrimary,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: _textPrimary,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: _textPrimary,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: _textPrimary,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: _textSecondary,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: _textPrimary,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: _textSecondary,
    ),
  ),
  cardTheme: CardThemeData(
    color: _surfaceAlt,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: _border.withAlpha(128)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: _surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _danger),
    ),
    hintStyle: const TextStyle(color: _textSecondary),
    labelStyle: const TextStyle(color: _textSecondary),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: _surface,
    selectedColor: _primary.withAlpha(40),
    labelStyle: const TextStyle(color: _textPrimary, fontSize: 13),
    side: const BorderSide(color: _border),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: _border,
    thickness: 1,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: _surfaceAlt,
    selectedItemColor: _primary,
    unselectedItemColor: _textSecondary,
    type: BottomNavigationBarType.fixed,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: _surface.withAlpha(200),
    foregroundColor: _textPrimary,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: _textPrimary,
    ),
  ),
);

// SpiceDesk brand colors
class SpiceColors {
  static const primary = _primary;
  static const surface = _surface;
  static const surfaceAlt = _surfaceAlt;
  static const border = _border;
  static const textPrimary = _textPrimary;
  static const textSecondary = _textSecondary;
  static const accent = _accent;
  static const danger = _danger;
  static const warning = _warning;

  // Opacity variants for glass effects
  static Color glassSurface = _surfaceAlt.withAlpha(180);
  static Color glassBorder = _border.withAlpha(100);
  static Color glassHighlight = Colors.white.withAlpha(15);
}
