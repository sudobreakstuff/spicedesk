import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _mode = AppThemeMode.light;
  ThemeData _themeData = AppTheme.build(AppThemeMode.light);

  AppThemeMode get mode => _mode;
  ThemeData get themeData => _themeData;
  bool get isDark => _mode == AppThemeMode.dark || _mode == AppThemeMode.spiceDark;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('theme_mode') ?? 'light';
    _mode = switch (name) {
      'dark' => AppThemeMode.dark,
      'spice_dark' => AppThemeMode.spiceDark,
      _ => AppThemeMode.light,
    };
    _themeData = AppTheme.build(_mode);
    notifyListeners();
  }

  Future<void> setMode(AppThemeMode mode) async {
    _mode = mode;
    _themeData = AppTheme.build(mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', switch (mode) {
      AppThemeMode.dark => 'dark',
      AppThemeMode.spiceDark => 'spice_dark',
      AppThemeMode.light => 'light',
    });
    notifyListeners();
  }
}
