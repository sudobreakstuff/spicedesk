import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Brightness, ThemeData, ColorScheme, Material3;
import 'package:google_fonts/google_fonts.dart';

class GlassColors {
  static const primary = Color(0xFF007AFF);
  static const primaryLight = Color(0xFF409CFF);
  static const success = Color(0xFF34C759);
  static const warning = Color(0xFFFF9500);
  static const error = Color(0xFFFF3B30);
  static const pink = Color(0xFFFF2D55);
  static const teal = Color(0xFF5AC8FA);
  static const purple = Color(0xFFAF52DE);

  static const lightBg = Color(0xFFF2F2F7);
  static const lightCard = Color(0xCCFFFFFF);
  static const lightText = Color(0xFF1C1C1E);
  static const lightText2 = Color(0xFF8E8E93);
  static const lightText3 = Color(0xFFC7C7CC);
  static const lightBorder = Color(0xFFE5E5EA);
  static const lightSep = Color(0xFFC6C6C8);

  static const darkBg = Color(0xFF000000);
  static const darkCard = Color(0xCC1C1C1E);
  static const darkText = Color(0xFFFFFFFF);
  static const darkText2 = Color(0xFF8E8E93);
  static const darkText3 = Color(0xFF48484A);
  static const darkBorder = Color(0xFF38383A);
  static const darkSep = Color(0xFF38383A);
}

class GlassTheme {
  static BoxDecoration glassCard(bool isDark) => BoxDecoration(
    color: (isDark ? GlassColors.darkCard : GlassColors.lightCard),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: isDark ? GlassColors.darkBorder.withValues(alpha: 0.5) : GlassColors.lightBorder.withValues(alpha: 0.5), width: 0.5),
  );

  static BoxDecoration glassSheet(bool isDark) => BoxDecoration(
    color: isDark ? const Color(0xE51C1C1E) : const Color(0xE5F2F2F7),
    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
    border: Border(top: BorderSide(color: isDark ? GlassColors.darkBorder : GlassColors.lightBorder, width: 0.5)),
  );

  static BoxShadow glassShadow(bool isDark) => BoxShadow(color: isDark ? const Color(0xFF000000).withValues(alpha: 0.3) : const Color(0x1A000000), blurRadius: 20, offset: const Offset(0, 2));

  static CupertinoDynamicColor primary = CupertinoDynamicColor.withBrightness(
    color: GlassColors.primary,
    darkColor: GlassColors.primaryLight,
  );

  static CupertinoThemeData lightTheme = const CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: GlassColors.primary,
    scaffoldBackgroundColor: GlassColors.lightBg,
    barBackgroundColor: Color(0xCCF2F2F7),
    textTheme: CupertinoTextThemeData(
      primaryColor: GlassColors.lightText,
      textStyle: TextStyle(fontFamily: '.SF Pro Text', fontSize: 17, color: GlassColors.lightText, letterSpacing: -0.2),
      navTitleTextStyle: TextStyle(fontFamily: '.SF Pro Text', fontSize: 17, fontWeight: FontWeight.w600, color: GlassColors.lightText, letterSpacing: -0.2),
      navLargeTitleTextStyle: TextStyle(fontFamily: '.SF Pro Display', fontSize: 34, fontWeight: FontWeight.w700, color: GlassColors.lightText, letterSpacing: -0.5),
      actionTextStyle: TextStyle(fontFamily: '.SF Pro Text', fontSize: 17, color: GlassColors.primary),
      tabLabelTextStyle: TextStyle(fontFamily: '.SF Pro Text', fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: -0.1),
      dateTimePickerTextStyle: TextStyle(fontFamily: '.SF Pro Text', fontSize: 21, color: GlassColors.lightText),
    ),
  );

  static CupertinoThemeData darkTheme = const CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: GlassColors.primaryLight,
    scaffoldBackgroundColor: GlassColors.darkBg,
    barBackgroundColor: Color(0xCC000000),
    textTheme: CupertinoTextThemeData(
      primaryColor: GlassColors.darkText,
      textStyle: TextStyle(fontFamily: '.SF Pro Text', fontSize: 17, color: GlassColors.darkText, letterSpacing: -0.2),
      navTitleTextStyle: TextStyle(fontFamily: '.SF Pro Text', fontSize: 17, fontWeight: FontWeight.w600, color: GlassColors.darkText, letterSpacing: -0.2),
      navLargeTitleTextStyle: TextStyle(fontFamily: '.SF Pro Display', fontSize: 34, fontWeight: FontWeight.w700, color: GlassColors.darkText, letterSpacing: -0.5),
      actionTextStyle: TextStyle(fontFamily: '.SF Pro Text', fontSize: 17, color: GlassColors.primaryLight),
      tabLabelTextStyle: TextStyle(fontFamily: '.SF Pro Text', fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: -0.1),
    ),
  );
}

extension BuildContextGlass on BuildContext {
  bool get isGlassDark => CupertinoTheme.brightnessOf(this) == Brightness.dark;
  CupertinoThemeData get glassTheme => CupertinoTheme.of(this);
  Color get glassBg => isGlassDark ? GlassColors.darkBg : GlassColors.lightBg;
  Color get glassText => isGlassDark ? GlassColors.darkText : GlassColors.lightText;
  Color get glassText2 => isGlassDark ? GlassColors.darkText2 : GlassColors.lightText2;
  Color get glassText3 => isGlassDark ? GlassColors.darkText3 : GlassColors.lightText3;
  Color get glassBorder => isGlassDark ? GlassColors.darkBorder : GlassColors.lightBorder;
  BoxDecoration get glassCard => GlassTheme.glassCard(isGlassDark);
}
