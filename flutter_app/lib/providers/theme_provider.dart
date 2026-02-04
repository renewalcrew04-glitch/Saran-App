import 'package:flutter/material.dart';

import '../core/theme/app_light_theme.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode get themeMode => ThemeMode.light;
  bool get isDarkMode => false;

  ThemeData get lightTheme => AppLightTheme.theme;

  ThemeData get darkTheme => AppLightTheme.theme;

  // Theme switching is intentionally disabled for now per spec.
  void toggleTheme() {
    notifyListeners();
  }
}
