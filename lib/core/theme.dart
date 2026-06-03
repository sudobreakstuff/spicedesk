import 'package:flutter/material.dart';

class T {
  static const p = Color(0xFF2563EB);
  static const pL = Color(0xFF3B82F6);
  static const pBg = Color(0xFFEFF6FF);
  static const s = Color(0xFF059669);
  static const w = Color(0xFFD97706);
  static const e = Color(0xFFDC2626);
  static const sBg = Color(0xFFECFDF5);
  static const wBg = Color(0xFFFFFBEB);
  static const eBg = Color(0xFFFEF2F2);

  static const t1 = Color(0xFF0F172A);
  static const t2 = Color(0xFF64748B);
  static const t3 = Color(0xFF94A3B8);
  static const bd = Color(0xFFE2E8F0);
  static const bg = Color(0xFFF8FAFC);

  static const dt1 = Color(0xFFF1F5F9);
  static const dt2 = Color(0xFF94A3B8);
  static const dt3 = Color(0xFF475569);
  static const dbd = Color(0xFF334155);
  static const dbg = Color(0xFF0F172A);
  static const dcard = Color(0xFF1E293B);
}

class AppTheme {
  static ThemeData light = ThemeData(
    useMaterial3: true, brightness: Brightness.light,
    colorScheme: const ColorScheme.light(primary: T.p, onPrimary: Colors.white, surface: Colors.white, error: T.e),
    scaffoldBackgroundColor: T.bg,
    dividerTheme: const DividerThemeData(color: T.bd, thickness: 1, space: 0),
    appBarTheme: const AppBarTheme(elevation: 0, scrolledUnderElevation: 1, centerTitle: false, backgroundColor: Colors.white, foregroundColor: T.t1, titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: T.t1)),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white, indicatorColor: T.pBg, elevation: 2, height: 64,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(size: 22, color: s.contains(WidgetState.selected) ? T.p : T.t2))),
    cardTheme: CardThemeData(elevation: 0, color: Colors.white, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: T.bd))),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: T.p, foregroundColor: Colors.white, elevation: 0, minimumSize: const Size(double.infinity, 46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)), textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.2))),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: T.p, minimumSize: const Size(0, 46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)), side: const BorderSide(color: T.bd), textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white, isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: T.bd)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: T.bd)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: T.p, width: 1.5))),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
    textTheme: const TextTheme(headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: T.t1, letterSpacing: -0.5), headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: T.t1), titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: T.t1), titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: T.t1), bodyLarge: TextStyle(fontSize: 14, color: T.t1), bodyMedium: TextStyle(fontSize: 13, color: T.t2), bodySmall: TextStyle(fontSize: 11, color: T.t3)),
    iconTheme: const IconThemeData(color: T.t2, size: 20),
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true, brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(primary: T.pL, onPrimary: Colors.white, surface: T.dcard, error: T.e),
    scaffoldBackgroundColor: T.dbg,
    dividerTheme: const DividerThemeData(color: T.dbd, thickness: 1, space: 0),
    appBarTheme: const AppBarTheme(elevation: 0, scrolledUnderElevation: 1, centerTitle: false, backgroundColor: T.dbg, foregroundColor: T.dt1, titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: T.dt1)),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: T.dcard, indicatorColor: T.pBg.withValues(alpha: 0.1), elevation: 2, height: 64,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(size: 22, color: s.contains(WidgetState.selected) ? T.pL : T.dt2))),
    cardTheme: CardThemeData(elevation: 0, color: T.dcard, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: T.dbd))),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: T.pL, foregroundColor: Colors.white, elevation: 0, minimumSize: const Size(double.infinity, 46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)), textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: T.pL, minimumSize: const Size(0, 46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)), side: const BorderSide(color: T.dbd), textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: T.dcard, isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: T.dbd)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: T.dbd)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: T.pL, width: 1.5))),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
    textTheme: const TextTheme(headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: T.dt1, letterSpacing: -0.5), headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: T.dt1), titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: T.dt1), titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: T.dt1), bodyLarge: TextStyle(fontSize: 14, color: T.dt1), bodyMedium: TextStyle(fontSize: 13, color: T.dt2), bodySmall: TextStyle(fontSize: 11, color: T.dt3)),
    iconTheme: const IconThemeData(color: T.dt2, size: 20),
  );
}
