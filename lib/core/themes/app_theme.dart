import 'package:flutter/material.dart';

class AppTheme {
  // Modern color scheme for light mode
  static const _lightPrimary = Color(0xFF6750A4);
  static const _lightSecondary = Color(0xFF625B71);

  // Modern color scheme for dark mode
  static const _darkPrimary = Color(0xFFD0BCFF);
  static const _darkSecondary = Color(0xFFCCC2DC);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _lightPrimary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFFFFBFE),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Color(0xFFFFFBFE),
        foregroundColor: Color(0xFF1C1B1F),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _darkPrimary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF1C1B1F),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: const Color(0xFF2B2930),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Color(0xFF1C1B1F),
        foregroundColor: Color(0xFFE6E1E5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}
