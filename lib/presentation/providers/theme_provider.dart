import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../data/datasources/database/database_service.dart';
import '../../data/repositories/settings_repository_impl.dart';

/// Setting key for theme preference
const String _themeSettingKey = 'theme_mode';

/// Theme mode values
const String _themeDark = 'dark';
const String _themeLight = 'light';

/// Provider for SettingsRepository
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(DatabaseService());
});

/// State notifier for managing theme mode
class ThemeNotifier extends StateNotifier<ThemeMode> {
  final SettingsRepository _settingsRepository;

  ThemeNotifier(this._settingsRepository) : super(ThemeMode.dark) {
    _loadTheme();
  }

  /// Load theme preference from database
  Future<void> _loadTheme() async {
    final themeValue = await _settingsRepository.getSetting(_themeSettingKey);
    if (themeValue == _themeLight) {
      state = ThemeMode.light;
    } else {
      // Default to dark mode
      state = ThemeMode.dark;
    }
  }

  /// Toggle between dark and light theme
  Future<void> toggleTheme() async {
    final newTheme = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setTheme(newTheme);
  }

  /// Set specific theme mode
  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final themeValue = mode == ThemeMode.dark ? _themeDark : _themeLight;
    await _settingsRepository.setSetting(_themeSettingKey, themeValue);
  }

  /// Check if current theme is dark
  bool get isDark => state == ThemeMode.dark;

  /// Check if current theme is light
  bool get isLight => state == ThemeMode.light;
}

/// Provider for theme state
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final settingsRepository = ref.watch(settingsRepositoryProvider);
  return ThemeNotifier(settingsRepository);
});
