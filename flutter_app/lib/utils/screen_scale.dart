import 'package:flutter/material.dart';

/// Lightweight responsive scaling helpers.
///
/// Base design width: 390 px (iPhone 14 / typical mid-size Android).
/// Usage:
///   Text('Hello', style: TextStyle(fontSize: context.sp(14)))
///   SizedBox(height: context.sc(16))
///   Padding(padding: EdgeInsets.all(context.sc(12)))
extension ScreenScale on BuildContext {
  static const double _base = 390.0;

  double get _sw => MediaQuery.sizeOf(this).width;

  /// Scale a **dimension** (padding, margin, icon size, border radius, etc.)
  /// Clamps between 80 % and 130 % of the original value so extreme screen
  /// sizes don't look broken.
  double sc(double size) => size * (_sw / _base).clamp(0.80, 1.30);

  /// Scale a **font size** — slightly tighter range so text stays legible.
  double sp(double size) => size * (_sw / _base).clamp(0.85, 1.20);
}
