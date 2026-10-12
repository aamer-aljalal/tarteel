import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isPatternBackgroundEnabled = true;

  ThemeMode get themeMode => _themeMode;
  bool get isPatternBackgroundEnabled => _isPatternBackgroundEnabled;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('app_theme_mode') ?? 'تلقائي';
    _themeMode = _themeModeFromArabicString(savedTheme);
    _isPatternBackgroundEnabled = prefs.getBool('is_pattern_bg_enabled') ?? true;
    notifyListeners();
  }

  Future<void> updateTheme(String themeString) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme_mode', themeString);
    _themeMode = _themeModeFromArabicString(themeString);
    notifyListeners();
  }

  Future<void> setPatternBackgroundEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_pattern_bg_enabled', value);
    _isPatternBackgroundEnabled = value;
    notifyListeners();
  }

  ThemeMode _themeModeFromArabicString(String value) {
    switch (value) {
      case 'نهاري':
        return ThemeMode.light;
      case 'ليلي':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
