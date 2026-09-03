import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF60A5FA); // Expressive Blue
  static const Color scaffoldBackgroundColor = Color(0xFF0F172A); // Dark Slate

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Colors.white),
        displayMedium: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Colors.white),
        displaySmall: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Colors.white),
        headlineMedium: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge: TextStyle(color: Colors.white70),
        bodyMedium: TextStyle(color: Colors.white60),
      ),
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: const Color(0xFFC084FC), // Purple accent
        surface: Colors.white.withValues(alpha: 0.05),
      ),
    );
  }
}
