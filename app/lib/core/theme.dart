import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryPurple = Color(0xFF534AB7);
  static const Color scaffoldBg = Colors.white;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryPurple,
        primary: primaryPurple,
        brightness: Brightness.light,
        surface: scaffoldBg,
      ),
      scaffoldBackgroundColor: scaffoldBg,
      
      // Clean, flat App Bar design
      appBarTheme: const AppBarTheme(
        backgroundColor: scaffoldBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontFamily: 'sans-serif',
        ),
        iconTheme: IconThemeData(color: Colors.black87),
      ),

      // Flat, highly visual Cards
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
      ),

      // Premium Bottom Navigation Bar Theme (Material 3 style)
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: scaffoldBg,
        elevation: 8,
        selectedItemColor: primaryPurple,
        unselectedItemColor: Colors.black38,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'sans-serif',
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          fontFamily: 'sans-serif',
        ),
        type: BottomNavigationBarType.fixed,
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'sans-serif',
          ),
        ),
      ),

      // Clean standard Sans-Serif Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'sans-serif', fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontFamily: 'sans-serif', fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontFamily: 'sans-serif', fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontFamily: 'sans-serif', color: Colors.black87),
        bodyMedium: TextStyle(fontFamily: 'sans-serif', color: Colors.black54),
      ),
    );
  }
}
