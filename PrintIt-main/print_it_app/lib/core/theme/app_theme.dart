import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryCyan = Color(0xFF06B6D4); // Cyan from Stitch design
  static const Color accentPurple = Color(0xFF7C3AED); // Purple from Stitch design
  static const Color lightBackground = Color(0xFFF8FCFF); // Stitch Light background
  static const Color darkBackground = Color(0xFF050811); // Stitch Dark background

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryCyan,
      scaffoldBackgroundColor: lightBackground,
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Color(0xFF000000)),
        displayMedium: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Color(0xFF000000)),
        displaySmall: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Color(0xFF000000)),
        headlineMedium: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, color: Color(0xFF000000)),
        titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF000000)),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
        bodyLarge: TextStyle(color: Color(0xFF0F172A)),
        bodyMedium: TextStyle(color: Color(0xFF334155)),
        bodySmall: TextStyle(color: Color(0xFF64748B)),
      ),
      colorScheme: const ColorScheme.light(
        primary: primaryCyan,
        secondary: accentPurple,
        surface: Colors.white,
        onSurface: Color(0xFF000000),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF000000)),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryCyan,
      scaffoldBackgroundColor: darkBackground,
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Colors.white),
        displayMedium: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Colors.white),
        displaySmall: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Colors.white),
        headlineMedium: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, color: Colors.white),
        titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFF1F5F9)),
        bodyLarge: TextStyle(color: Color(0xFFE2E8F0)),
        bodyMedium: TextStyle(color: Color(0xFF94A3B8)),
        bodySmall: TextStyle(color: Color(0xFF64748B)),
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryCyan,
        secondary: accentPurple,
        surface: Color(0xFF111928),
        onSurface: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }
}
