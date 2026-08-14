import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDark => _isDarkMode;
  bool get isDarkMode => _isDarkMode;

  ThemeData get lightTheme =>
      ThemeData(brightness: Brightness.light, useMaterial3: true);

  ThemeData get darkTheme =>
      ThemeData(brightness: Brightness.dark, useMaterial3: true);

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
