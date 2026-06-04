import 'package:flutter/material.dart';

const _fontFamily = 'Inter';

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
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32, fontWeight: FontWeight.w700, color: _textPrimary,
      fontFamily: _fontFamily, letterSpacing: -0.5,
    ),
    headlineMedium: TextStyle(
      fontSize: 24, fontWeight: FontWeight.w600, color: _textPrimary,
      fontFamily: _fontFamily,
    ),
    headlineSmall: TextStyle(
      fontSize: 20, fontWeight: FontWeight.w600, color: _textPrimary,
      fontFamily: _fontFamily,
    ),
    titleLarge: TextStyle(
      fontSize: 18, fontWeight: FontWeight.w600, color: _textPrimary,
      fontFamily: _fontFamily,
    ),
    titleMedium: TextStyle(
      fontSize: 16, fontWeight: FontWeight.w500, color: _textPrimary,
      fontFamily: _fontFamily,
    ),
    bodyLarge: TextStyle(
      fontSize: 16, fontWeight: FontWeight.w400, color: _textPrimary,
      fontFamily: _fontFamily,
    ),
    bodyMedium: TextStyle(
      fontSize: 14, fontWeight: FontWeight.w400, color: _textSecondary,
      fontFamily: _fontFamily,
    ),
    labelLarge: TextStyle(
      fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary,
      fontFamily: _fontFamily,
    ),
    labelMedium: TextStyle(
      fontSize: 12, fontWeight: FontWeight.w500, color: _textSecondary,
      fontFamily: _fontFamily,
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
      textStyle: const TextStyle(
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
    titleTextStyle: const TextStyle(
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
