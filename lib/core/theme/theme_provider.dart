import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

// ── Theme names ──
enum AppTheme {
  defaultDark,
  oceanBlue,
  forestGreen,
  sunsetOrange,
  midnightPurple,
  paperLight,
}

const _sfAlt = Color(0xFF161B22);
const _textPri = Color(0xFFE6EDF3);

extension AppThemeColors on AppTheme {
  String get label {
    switch (this) {
      case AppTheme.defaultDark:
        return 'Default Dark';
      case AppTheme.oceanBlue:
        return 'Ocean Blue';
      case AppTheme.forestGreen:
        return 'Forest Green';
      case AppTheme.sunsetOrange:
        return 'Sunset Orange';
      case AppTheme.midnightPurple:
        return 'Midnight Purple';
      case AppTheme.paperLight:
        return 'Paper Light';
    }
  }

  IconData get icon {
    switch (this) {
      case AppTheme.defaultDark:
        return Icons.dark_mode;
      case AppTheme.oceanBlue:
        return Icons.water_drop;
      case AppTheme.forestGreen:
        return Icons.forest;
      case AppTheme.sunsetOrange:
        return Icons.wb_sunny;
      case AppTheme.midnightPurple:
        return Icons.nightlight_round;
      case AppTheme.paperLight:
        return Icons.light_mode;
    }
  }

  Color get primaryColor {
    switch (this) {
      case AppTheme.defaultDark:
        return Color(0xFF6366F1);
      case AppTheme.oceanBlue:
        return Color(0xFF0EA5E9);
      case AppTheme.forestGreen:
        return Color(0xFF22C55E);
      case AppTheme.sunsetOrange:
        return Color(0xFFF97316);
      case AppTheme.midnightPurple:
        return Color(0xFFA855F7);
      case AppTheme.paperLight:
        return Color(0xFF6366F1);
    }
  }

  Color get accentColor {
    switch (this) {
      case AppTheme.defaultDark:
        return Color(0xFF238636);
      case AppTheme.oceanBlue:
        return Color(0xFF06B6D4);
      case AppTheme.forestGreen:
        return Color(0xFF10B981);
      case AppTheme.sunsetOrange:
        return Color(0xFFF59E0B);
      case AppTheme.midnightPurple:
        return Color(0xFFD946EF);
      case AppTheme.paperLight:
        return Color(0xFF16A34A);
    }
  }

  ColorScheme get colorScheme {
    final pri = primaryColor;
    final sec = accentColor;

    if (this == AppTheme.paperLight) {
      return ColorScheme.light(
        primary: pri,
        secondary: sec,
        surface: Color(0xFFF6F8FA),
        error: Color(0xFFDA3633),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF1F2328),
        onError: Colors.white,
      );
    }

    return ColorScheme.dark(
      primary: pri,
      secondary: sec,
      surface: _sfAlt,
      error: Color(0xFFDA3633),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _textPri,
      onError: Colors.white,
    );
  }
}

// ── Notifier ──
class ThemeModeNotifier extends StateNotifier<AppTheme> {
  ThemeModeNotifier() : super(AppTheme.defaultDark) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('app_theme');
    if (raw != null) {
      state = AppTheme.values.firstWhere(
        (t) => t.name == raw,
        orElse: () => AppTheme.defaultDark,
      );
    }
  }

  Future<void> setTheme(AppTheme theme) async {
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', theme.name);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, AppTheme>(
  (ref) => ThemeModeNotifier(),
);

final appThemeProvider = Provider<ThemeData>((ref) {
  final mode = ref.watch(themeModeProvider);
  return buildAppTheme(mode.colorScheme);
});

final currentColorSchemeProvider = Provider<ColorScheme>((ref) {
  return ref.watch(themeModeProvider).colorScheme;
});
