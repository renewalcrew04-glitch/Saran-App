import 'package:flutter/material.dart';

import '../core/theme/premium_black_theme.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode get themeMode => ThemeMode.light;
  bool get isDarkMode => false;

  ThemeData get lightTheme => PremiumBlackTheme.theme;

  // Keep a darkTheme for compatibility but use the same light theme for now.
  ThemeData get darkTheme => PremiumBlackTheme.theme;

  // Theme switching is intentionally disabled for now per spec.
  void toggleTheme() {
    notifyListeners();
  }
}
