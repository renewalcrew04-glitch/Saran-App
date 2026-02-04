import 'package:flutter/material.dart';

/// App-wide colors aligned with the modern light theme.
/// Use Theme.of(context).colorScheme in widgets when possible.
class AppColors {
  static const Color primary = Color(0xFF000000);
  static const Color primaryLight = Color(0xFF1A1A1A);
  static const Color primaryDark = Color(0xFF000000);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8FAFC);
  static const Color background = Color(0xFFF1F5F9);
  static const Color onSurface = Color(0xFF0F172A);
  static const Color onSurfaceVariant = Color(0xFF64748B);
  static const Color outline = Color(0xFFE2E8F0);
  static const Color outlineVariant = Color(0xFFCBD5E1);
  static const Color error = Color(0xFFDC2626);
  static const Color sos = Color(0xFFEF4444);

  // Legacy aliases for gradual migration
  static const Color black = onSurface;
  static const Color white = surface;
  static const Color border = outline;
  static const Color subtleBorder = outline;
  static const Color greyText = onSurfaceVariant;
  static const Color greyBg = surfaceVariant;
  static const Color danger = error;
}
