import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';

class ThemeProvider extends ChangeNotifier {
  bool _dark = false;
  ThemeMode get mode => _dark ? ThemeMode.dark : ThemeMode.light;
  bool get isDark => _dark;
  ThemeData get lightTheme => AppTheme.light;
  ThemeData get darkTheme => AppTheme.dark;

  Future<void> load() async {
    _dark = (await SharedPreferences.getInstance()).getBool('dark') ?? false;
    notifyListeners();
  }

  Future<void> toggle() async {
    _dark = !_dark;
    await (await SharedPreferences.getInstance()).setBool('dark', _dark);
    notifyListeners();
  }
}
