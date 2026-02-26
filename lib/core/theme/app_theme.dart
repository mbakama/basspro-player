import 'package:flutter/material.dart';

/// Theme definitions for BassPro Player
/// 
/// Provides comprehensive Material 3 theme configurations for both
/// dark and light modes with custom color schemes and text styles.
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // Dark Theme Colors
  static const Color _darkBackground = Color(0xFF121212);
  static const Color _darkSurface = Color(0xFF1E1E1E);
  static const Color _darkPrimary = Color(0xFFBB86FC);
  static const Color _darkSecondary = Color(0xFF03DAC6);
  static const Color _darkError = Color(0xFFCF6679);
  static const Color _darkOnSurface = Color(0xFFFFFFFF);
  static const Color _darkOnPrimary = Color(0xFF000000);
  static const Color _darkOnSecondary = Color(0xFF000000);
  static const Color _darkOnError = Color(0xFF000000);
  static const Color _darkSurfaceVariant = Color(0xFF2C2C2C);
  static const Color _darkOutline = Color(0xFF666666);

  // Light Theme Colors
  static const Color _lightBackground = Color(0xFFFFFFFF);
  static const Color _lightSurface = Color(0xFFF5F5F5);
  static const Color _lightPrimary = Color(0xFF6200EE);
  static const Color _lightSecondary = Color(0xFF018786);
  static const Color _lightError = Color(0xFFB00020);
  static const Color _lightOnSurface = Color(0xFF000000);
  static const Color _lightOnPrimary = Color(0xFFFFFFFF);
  static const Color _lightOnSecondary = Color(0xFFFFFFFF);
  static const Color _lightOnError = Color(0xFFFFFFFF);
  static const Color _lightSurfaceVariant = Color(0xFFE0E0E0);
  static const Color _lightOutline = Color(0xFF999999);

  /// Dark theme configuration (default)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: _darkPrimary,
        onPrimary: _darkOnPrimary,
        secondary: _darkSecondary,
        onSecondary: _darkOnSecondary,
        error: _darkError,
        onError: _darkOnError,
        surface: _darkSurface,
        onSurface: _darkOnSurface,
        surfaceContainerHighest: _darkSurfaceVariant,
        outline: _darkOutline,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: _darkBackground,
      
      // App Bar
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkSurface,
        foregroundColor: _darkOnSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: _darkOnSurface,
        ),
      ),
      
      // Card
      cardTheme: const CardThemeData(
        color: _darkSurface,
        elevation: 2,
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _darkSurface,
        selectedItemColor: _darkPrimary,
        unselectedItemColor: _darkOutline,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _darkPrimary,
        foregroundColor: _darkOnPrimary,
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: _darkOnSurface,
        size: 24,
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: _darkSurfaceVariant,
        thickness: 1,
        space: 1,
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      
      // Slider
      sliderTheme: const SliderThemeData(
        activeTrackColor: _darkPrimary,
        inactiveTrackColor: _darkOutline,
        thumbColor: _darkPrimary,
        overlayColor: Color(0x29BB86FC),
      ),
      
      // Text Theme
      textTheme: _buildTextTheme(Brightness.dark),
    );
  }

  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Scheme
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: _lightPrimary,
        onPrimary: _lightOnPrimary,
        secondary: _lightSecondary,
        onSecondary: _lightOnSecondary,
        error: _lightError,
        onError: _lightOnError,
        surface: _lightSurface,
        onSurface: _lightOnSurface,
        surfaceContainerHighest: _lightSurfaceVariant,
        outline: _lightOutline,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: _lightBackground,
      
      // App Bar
      appBarTheme: const AppBarTheme(
        backgroundColor: _lightSurface,
        foregroundColor: _lightOnSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: _lightOnSurface,
        ),
      ),
      
      // Card
      cardTheme: const CardThemeData(
        color: _lightSurface,
        elevation: 2,
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _lightSurface,
        selectedItemColor: _lightPrimary,
        unselectedItemColor: _lightOutline,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _lightPrimary,
        foregroundColor: _lightOnPrimary,
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: _lightOnSurface,
        size: 24,
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: _lightSurfaceVariant,
        thickness: 1,
        space: 1,
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      
      // Slider
      sliderTheme: const SliderThemeData(
        activeTrackColor: _lightPrimary,
        inactiveTrackColor: _lightOutline,
        thumbColor: _lightPrimary,
        overlayColor: Color(0x296200EE),
      ),
      
      // Text Theme
      textTheme: _buildTextTheme(Brightness.light),
    );
  }

  /// Build text theme with specified font sizes
  /// 
  /// Text styles:
  /// - Headers: 24sp
  /// - Titles: 18sp
  /// - Body: 16sp
  /// - Captions: 14sp
  static TextTheme _buildTextTheme(Brightness brightness) {
    final Color primaryColor = brightness == Brightness.dark 
        ? _darkOnSurface 
        : _lightOnSurface;
    final Color secondaryColor = brightness == Brightness.dark 
        ? const Color(0xFFB3B3B3) 
        : const Color(0xFF666666);

    return TextTheme(
      // Headers - 24sp
      displayLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: primaryColor,
        letterSpacing: 0,
      ),
      displayMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        letterSpacing: 0,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.normal,
        color: primaryColor,
        letterSpacing: 0,
      ),
      
      // Titles - 18sp
      headlineLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: primaryColor,
        letterSpacing: 0,
      ),
      headlineMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        letterSpacing: 0,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.normal,
        color: primaryColor,
        letterSpacing: 0,
      ),
      
      // Titles - 18sp (alternative)
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: primaryColor,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.normal,
        color: primaryColor,
        letterSpacing: 0,
      ),
      titleSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.normal,
        color: secondaryColor,
        letterSpacing: 0,
      ),
      
      // Body - 16sp
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: primaryColor,
        letterSpacing: 0.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: secondaryColor,
        letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: secondaryColor,
        letterSpacing: 0.4,
      ),
      
      // Captions - 14sp
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: primaryColor,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: primaryColor,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: secondaryColor,
        letterSpacing: 0.5,
      ),
    );
  }
}
