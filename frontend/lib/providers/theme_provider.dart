import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  // Key for saving theme preference to SharedPreferences
  static const String _themeKey = 'theme_mode';

  // Default theme mode
  ThemeMode _themeMode = ThemeMode.system;

  // Getter for current theme mode
  ThemeMode get themeMode => _themeMode;

  // Constructor loads saved theme preference
  ThemeProvider() {
    _loadThemePreference();
  }

  // Load saved theme preference from SharedPreferences
  Future<void> _loadThemePreference() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedTheme = prefs.getString(_themeKey);

    if (savedTheme != null) {
      _themeMode = _getThemeModeFromString(savedTheme);
      notifyListeners();
    }
  }

  // Convert string representation to ThemeMode enum
  ThemeMode _getThemeModeFromString(String themeString) {
    switch (themeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  // Save theme preference
  Future<void> _saveThemePreference(ThemeMode mode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String themeString;

    switch (mode) {
      case ThemeMode.light:
        themeString = 'light';
        break;
      case ThemeMode.dark:
        themeString = 'dark';
        break;
      default:
        themeString = 'system';
    }

    await prefs.setString(_themeKey, themeString);
  }

  // Toggle between light and dark theme
  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _saveThemePreference(_themeMode);
    notifyListeners();
  }

  // Set specific theme mode
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveThemePreference(mode);
    notifyListeners();
  }

  // Check if dark mode is active
  bool isDarkMode() {
    return _themeMode == ThemeMode.dark;
  }
}
