import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData theme = ThemeData(
    primaryColor: const Color(0xFF4CAF50), // Green
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4CAF50),
      secondary: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF4CAF50),
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF4CAF50),
      unselectedItemColor: Colors.grey,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
    ),
  );
}