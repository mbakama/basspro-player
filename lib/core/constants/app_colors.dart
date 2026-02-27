import 'package:flutter/material.dart';

/// Color palette constants for BassPro Player
class AppColors {
  // --- Dark Theme Tokens (Premium Audio Player) ---
  static const Color darkBackground = Color(0xFF0C0C0E); // Deep Charcoal
  static const Color darkSurface = Color(0xFF1A1B1F);    // Grey Steel
  static const Color darkPrimary = Color(0xFF00E5FF);    // Electric Blue
  static const Color darkSecondary = Color(0xFF7C4DFF);  // Deep Purple (Bass highlight)
  static const Color darkError = Color(0xFFFF5252);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFA0A0A0);
  static const Color darkDivider = Color(0xFF2A2B2F);

  // --- Light Theme Tokens ---
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF00B8D4);
  static const Color lightSecondary = Color(0xFF6200EA);
  static const Color lightError = Color(0xFFD32F2F);
  static const Color lightTextPrimary = Color(0xFF121212);
  static const Color lightTextSecondary = Color(0xFF666666);
  static const Color lightDivider = Color(0xFFE0E0E0);

  // --- Common colors ---
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFAB40);
  static const Color info = Color(0xFF40C4FF);

  // --- Specialized colors (Design Spec) ---
  static const Color playButtonActive = darkPrimary;
  static const Color favoriteActive = Color(0xFFFF4081);
  static const Color shuffleActive = Color(0xFF00E5FF);
  static const Color bassHighlight = darkSecondary;
  static const Color glassSurface = Color(0x33FFFFFF);

  // Private constructor to prevent instantiation
  AppColors._();

  /// Get theme data for dark mode
  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        surface: darkSurface,
        primary: darkPrimary,
        secondary: darkSecondary,
        error: darkError,
        onSurface: darkTextPrimary,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onError: Colors.black,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 2,
      ),
      dividerColor: darkDivider,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: darkTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: darkTextSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
        ),
      ),
    );
  }

  /// Get theme data for light mode
  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        surface: lightSurface,
        primary: lightPrimary,
        secondary: lightSecondary,
        error: lightError,
        onSurface: lightTextPrimary,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: lightTextPrimary,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 2,
      ),
      dividerColor: lightDivider,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: lightTextPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: lightTextPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: lightTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: lightTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: lightTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: lightTextSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: lightTextPrimary,
        ),
      ),
    );
  }
}
