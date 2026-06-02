import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _mode = AppThemeMode.light;

  AppThemeMode get mode => _mode;
  bool get isDark => _mode == AppThemeMode.dark;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _mode = prefs.getString('theme') == 'dark' ? AppThemeMode.dark : AppThemeMode.light;
    notifyListeners();
  }

  Future<void> toggle() async {
    _mode = _mode == AppThemeMode.dark ? AppThemeMode.light : AppThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', _mode == AppThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> setMode(AppThemeMode mode) async {
    _mode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', mode == AppThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  ThemeData theme() => AppTheme.build(_mode);
}
