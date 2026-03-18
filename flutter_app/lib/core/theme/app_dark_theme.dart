import 'package:flutter/material.dart';

/// Dark theme for SARAN app.
/// Matches the SARAN dark-navy + orange-brand design system.
class AppDarkTheme {
  // Brand orange
  static const Color primary       = Color(0xFFFF8132);
  static const Color primaryLight  = Color(0xFFFF9D5C);
  static const Color primaryDark   = Color(0xFFFF6A00);

  // Backgrounds — deep navy hierarchy
  static const Color background       = Color(0xFF060B14); // page bg
  static const Color surface          = Color(0xFF0B0F1A); // appbar / sidebar
  static const Color surfaceVariant   = Color(0xFF111827); // card interior
  static const Color surfaceContainer = Color(0xFF1A2235); // elevated inputs

  // Text
  static const Color onSurface        = Color(0xFFF1F5F9); // primary text
  static const Color onSurfaceVariant = Color(0xFF64748B); // muted / placeholder

  // Borders
  static const Color outline        = Color(0xFF1E2535);
  static const Color outlineVariant = Color(0xFF252D40);

  // Semantic
  static const Color error = Color(0xFFEF4444);
  static const Color sos   = Color(0xFFEF4444);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF3D1500),
        onPrimaryContainer: Color(0xFFFF9D5C),
        secondary: Color(0xFF94A3B8),
        onSecondary: Color(0xFF1E2535),
        surface: surface,
        onSurface: onSurface,
        surfaceContainerHighest: surfaceContainer,
        surfaceContainerHigh: surfaceVariant,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
        error: error,
        onError: Colors.white,
        shadow: Color(0x70000000),
        scrim: Color(0x99000000),
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: Color(0xFF94A3B8), size: 22),
      ),
      cardTheme: CardThemeData(
        color: surfaceVariant,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: outline),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: onSurfaceVariant, fontSize: 16),
        floatingLabelStyle: const TextStyle(color: primary, fontSize: 12),
        hintStyle: const TextStyle(color: onSurfaceVariant, fontSize: 13),
        prefixIconColor: onSurfaceVariant,
        suffixIconColor: onSurfaceVariant,
        counterStyle: const TextStyle(color: onSurfaceVariant),
        errorStyle: const TextStyle(color: error),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: Color(0x26FF8132), // primary @15%
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: outline),
        ),
      ),
      dividerTheme: const DividerThemeData(color: outline, thickness: 1),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: onSurface,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: onSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          color: Color(0xFFCBD5E1),
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          color: Color(0xFFCBD5E1),
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 11,
          color: onSurfaceVariant,
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
      ),
    );
  }
}
