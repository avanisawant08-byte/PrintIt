import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF3BAFF2); // Sky Blue from logo
  static const Color lightBackground = Color(0xFFF4F9FF); // Soft blue-white
  static const Color darkBackground = Color(0xFF0F172A); // Deep Navy

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: lightBackground,
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        displayMedium: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        displaySmall: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        headlineMedium: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
        bodyLarge: TextStyle(color: Color(0xFF334155)),
        bodyMedium: TextStyle(color: Color(0xFF475569)),
      ),
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: const Color(0xFF0284C7), // Deeper blue accent
        surface: Colors.white,
        onSurface: const Color(0xFF1E293B),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBackground,
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
        secondary: const Color(0xFF7DD3FC), // Light blue accent
        surface: const Color(0xFF1E293B),
        onSurface: const Color(0xFFF8FAFC),
      ),
    );
  }
}
