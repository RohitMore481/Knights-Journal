import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFF37474F),
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF37474F),
        secondary: Color(0xFFFFC107),
        surface: Color(0xFFFFFFFF),
        onPrimary: Colors.white,
        onSecondary: Colors.black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF37474F),
        foregroundColor: Colors.white,
        elevation: 2,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFFFC107),
        foregroundColor: Colors.black,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Color(0xFF212121), fontSize: 16),
        titleLarge: TextStyle(
          color: Color(0xFF37474F),
          fontWeight: FontWeight.bold,
        ),
      ),
      cardColor: const Color(0xFFFFFFFF),
      cardTheme: const CardThemeData(
        color: Color(0xFFFFFFFF),
        elevation: 2,
        shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

    );
  }
}
