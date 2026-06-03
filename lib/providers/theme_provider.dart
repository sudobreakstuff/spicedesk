import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;
  ThemeMode get mode => _isDark ? ThemeMode.dark : ThemeMode.light;
  bool get isDark => _isDark;

  Future<void> load() async {
    _isDark = (await SharedPreferences.getInstance()).getBool('dark') ?? false;
    notifyListeners();
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    await (await SharedPreferences.getInstance()).setBool('dark', _isDark);
    notifyListeners();
  }
}
