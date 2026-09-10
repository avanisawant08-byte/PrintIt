import 'package:flutter/material.dart';

class AppTheme {
  static const Color logoBlue = Color(0xFF51C5F6); // Dominant saturated brand blue from original logo
  static const Color primaryCyan = logoBlue; // Saturated blue from logo
  static const Color brandBlue = Color(0xFF0284C7); // High-contrast deep brand blue
  static const Color accentPurple = brandBlue; // Legacy alias replaced with brandBlue
  static const Color lightBackground = Color(0xFFF8FCFF); // Stitch Light background
  static const Color darkBackground = Color(0xFF050811); // Stitch Dark background

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: brandBlue,
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
        primary: brandBlue,
        secondary: primaryCyan,
        surface: Colors.white,
        onSurface: Color(0xFF000000),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF000000)),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: brandBlue,
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
        primary: brandBlue,
        secondary: primaryCyan,
        surface: Color(0xFF111928),
        onSurface: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }
}
