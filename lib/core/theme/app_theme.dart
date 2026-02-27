import 'package:flutter/material.dart';

/// Theme definitions for BassPro Player - Premium Edition
/// 
/// Provides comprehensive Material 3 theme configurations for both
/// dark and light modes with custom color schemes and text styles.
class AppTheme {
  AppTheme._();

  // --- Dark Theme Tokens (Premium Audio Player) ---
  static const Color _darkBackground = Color(0xFF0C0C0E); // Deep Charcoal
  static const Color _darkSurface = Color(0xFF1A1B1F);    // Grey Steel
  static const Color _darkPrimary = Color(0xFF00E5FF);    // Electric Blue
  static const Color _darkSecondary = Color(0xFF7C4DFF);  // Deep Purple (Bass highlight)
  static const Color _darkError = Color(0xFFFF5252);
  static const Color _darkOnSurface = Color(0xFFFFFFFF);
  static const Color _darkOnPrimary = Color(0xFF000000);
  static const Color _darkOnSecondary = Color(0xFFFFFFFF);
  static const Color _darkSurfaceVariant = Color(0xFF2A2B2F);
  static const Color _darkOutline = Color(0xFF404040);

  // --- Light Theme Tokens ---
  static const Color _lightBackground = Color(0xFFF8F9FA);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightPrimary = Color(0xFF00B8D4);
  static const Color _lightSecondary = Color(0xFF6200EA);
  static const Color _lightError = Color(0xFFD32F2F);
  static const Color _lightOnSurface = Color(0xFF121212);
  static const Color _lightOnPrimary = Color(0xFFFFFFFF);
  static const Color _lightOnSecondary = Color(0xFFFFFFFF);
  static const Color _lightSurfaceVariant = Color(0xFFE0E0E0);
  static const Color _lightOutline = Color(0xFF999999);

  /// Dark theme configuration (default)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: _darkPrimary,
        onPrimary: _darkOnPrimary,
        secondary: _darkSecondary,
        onSecondary: _darkOnSecondary,
        error: _darkError,
        onError: _darkOnSecondary,
        surface: _darkSurface,
        onSurface: _darkOnSurface,
        surfaceVariant: _darkSurfaceVariant,
        outline: _darkOutline,
      ),
      
      scaffoldBackgroundColor: _darkBackground,
      
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: _darkOnSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: _darkOnSurface,
          letterSpacing: -0.5,
        ),
      ),
      
      cardTheme: CardThemeData(
        color: _darkSurface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _darkOutline.withOpacity(0.5), width: 1),
        ),
      ),
      
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _darkSurface,
        selectedItemColor: _darkPrimary,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
      
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _darkSurface,
        indicatorColor: _darkPrimary.withOpacity(0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: _darkPrimary, fontSize: 12, fontWeight: FontWeight.w600);
          }
          return const TextStyle(color: Colors.white54, fontSize: 12);
        }),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: _darkPrimary,
        inactiveTrackColor: _darkOutline,
        thumbColor: _darkPrimary,
        overlayColor: _darkPrimary.withOpacity(0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      
      textTheme: _buildTextTheme(Brightness.dark),
    );
  }

  /// Build text theme with Design System sizes
  static TextTheme _buildTextTheme(Brightness brightness) {
    final Color primaryColor = brightness == Brightness.dark ? _darkOnSurface : _lightOnSurface;
    final Color secondaryColor = brightness == Brightness.dark ? Colors.white60 : Colors.black54;

    return TextTheme(
      // H1 - Titre Écran (utilisé par AppBar)
      displayLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: primaryColor,
        letterSpacing: -0.5,
      ),
      // H2 - Titre Musique / Section
      headlineMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      // Body - Titres items
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: primaryColor,
      ),
      // Body - Sous-titres / Artist names
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: secondaryColor,
      ),
      // Caption - Duration / Small info
      labelSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Light theme (Alternative)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: _lightPrimary,
        secondary: _lightSecondary,
        surface: _lightSurface,
        onSurface: _lightOnSurface,
      ),
      scaffoldBackgroundColor: _lightBackground,
      textTheme: _buildTextTheme(Brightness.light),
    );
  }
}
