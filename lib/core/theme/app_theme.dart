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

final appTheme = buildAppTheme(
  const ColorScheme.dark(
    primary: _primary,
    secondary: _accent,
    surface: _surfaceAlt,
    error: _danger,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: _textPrimary,
    onError: Colors.white,
  ),
);

ThemeData buildAppTheme(ColorScheme colorScheme) {
  // Always use dark surface colors — no white backgrounds
  final surfaceColor = _surface;
  final surfaceAltColor = _surfaceAlt;
  final borderColor = _border;
  final textPri = _textPrimary;
  final textSec = _textSecondary;

  SpiceColors.applyTheme(colorScheme, false); // Always dark mode

  return ThemeData(
    useMaterial3: true,
    brightness: colorScheme.brightness,
    scaffoldBackgroundColor: surfaceColor,
    colorScheme: colorScheme,
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32, fontWeight: FontWeight.w700, color: textPri,
        fontFamily: _fontFamily, letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 24, fontWeight: FontWeight.w600, color: textPri,
        fontFamily: _fontFamily,
      ),
      headlineSmall: TextStyle(
        fontSize: 20, fontWeight: FontWeight.w600, color: textPri,
        fontFamily: _fontFamily,
      ),
      titleLarge: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w600, color: textPri,
        fontFamily: _fontFamily,
      ),
      titleMedium: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w500, color: textPri,
        fontFamily: _fontFamily,
      ),
      bodyLarge: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w400, color: textPri,
        fontFamily: _fontFamily,
      ),
      bodyMedium: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w400, color: textSec,
        fontFamily: _fontFamily,
      ),
      labelLarge: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w600, color: textPri,
        fontFamily: _fontFamily,
      ),
      labelMedium: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w500, color: textSec,
        fontFamily: _fontFamily,
      ),
    ),
    cardTheme: CardThemeData(
      color: surfaceAltColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor.withAlpha(128)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _danger),
      ),
      hintStyle: TextStyle(color: textSec),
      labelStyle: TextStyle(color: textSec),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceColor,
      selectedColor: colorScheme.primary.withAlpha(40),
      labelStyle: TextStyle(color: textPri, fontSize: 13),
      side: BorderSide(color: borderColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: borderColor,
      thickness: 1,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceAltColor,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: textSec,
      type: BottomNavigationBarType.fixed,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceColor.withAlpha(200),
      foregroundColor: textPri,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPri,
      ),
    ),
  );
}

// SpiceDesk brand colors — dynamically updated by buildAppTheme
class SpiceColors {
  static Color primary = _primary;
  static Color surface = _surface;
  static Color surfaceAlt = _surfaceAlt;
  static Color border = _border;
  static Color textPrimary = _textPrimary;
  static Color textSecondary = _textSecondary;
  static Color accent = _accent;
  static Color danger = _danger;
  static Color warning = _warning;

  static void applyTheme(ColorScheme scheme, bool isLight) {
    primary = scheme.primary;
    surface = isLight ? const Color(0xFFF6F8FA) : _surface;
    surfaceAlt = isLight ? Colors.white : _surfaceAlt;
    border = isLight ? const Color(0xFFD0D7DE) : _border;
    textPrimary = isLight ? const Color(0xFF1F2328) : _textPrimary;
    textSecondary = isLight ? const Color(0xFF656D76) : _textSecondary;
    accent = scheme.secondary;
    danger = scheme.error;
    warning = _warning;
  }

  static Color glassSurface = _surfaceAlt.withAlpha(180);
  static Color glassBorder = _border.withAlpha(100);
  static Color glassHighlight = Colors.white.withAlpha(15);
}
