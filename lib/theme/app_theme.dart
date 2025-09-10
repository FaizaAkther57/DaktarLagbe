import 'package:flutter/material.dart';

class AppTheme {
  static const double _borderRadius = 12.0;
  static const Color primaryColor = Color(0xFF1A3B7B);
  
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: Color(0xFF1A3B7B),
      secondary: Color(0xFF4E85D3),
      tertiary: Color(0xFF2B5299),
      surface: Colors.white,
      background: Color(0xFFF5F6FA),
      error: Color(0xFFBA1A1A),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF1C1B1F),
      onBackground: Color(0xFF1C1B1F),
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: Color(0xFFF5F6FA),
    
    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Color(0xFF1A3B7B)),
      titleTextStyle: TextStyle(
        color: Color(0xFF1A3B7B),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    
    // Card Theme
    cardTheme: ThemeData().cardTheme.copyWith(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      color: Colors.white,
      surfaceTintColor: Colors.white,
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        borderSide: BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        borderSide: BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        borderSide: BorderSide(color: Color(0xFF1A3B7B), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        borderSide: BorderSide(color: Color(0xFFBA1A1A)),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    
    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        backgroundColor: Color(0xFF1A3B7B),
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    
    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Color(0xFF1A3B7B),
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    
    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: Color(0xFF1A3B7B),
      secondarySelectedColor: Color(0xFF1A3B7B),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      labelStyle: TextStyle(fontSize: 14),
      secondaryLabelStyle: TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        side: BorderSide(color: Color(0xFFE0E0E0)),
      ),
    ),
    
    // Text Theme
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A3B7B),
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A3B7B),
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A3B7B),
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A3B7B),
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1C1B1F),
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Color(0xFF1C1B1F),
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Color(0xFF1C1B1F),
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1C1B1F),
      ),
    ),
  );
}
