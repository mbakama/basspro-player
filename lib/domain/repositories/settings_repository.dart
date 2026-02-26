/// Repository interface for application settings and preferences.
///
/// Defines the contract for data access operations related to app settings,
/// using a key-value storage approach.
abstract class SettingsRepository {
  /// Retrieves a setting value by its key.
  ///
  /// Returns null if no setting with the given key exists.
  Future<String?> getSetting(String key);

  /// Sets a setting value for the given key.
  ///
  /// If the key already exists, its value is updated.
  /// If the key doesn't exist, a new setting is created.
  Future<void> setSetting(String key, String value);

  /// Retrieves a boolean setting value by its key.
  ///
  /// Returns the default value if the setting doesn't exist.
  /// Parses 'true' and '1' as true, everything else as false.
  Future<bool> getBoolSetting(String key, {bool defaultValue = false});

  /// Sets a boolean setting value for the given key.
  ///
  /// Stores the value as 'true' or 'false' string.
  Future<void> setBoolSetting(String key, bool value);

  /// Retrieves an integer setting value by its key.
  ///
  /// Returns the default value if the setting doesn't exist or cannot be parsed.
  Future<int> getIntSetting(String key, {int defaultValue = 0});

  /// Sets an integer setting value for the given key.
  ///
  /// Stores the value as a string representation of the integer.
  Future<void> setIntSetting(String key, int value);

  /// Deletes a setting by its key.
  Future<void> deleteSetting(String key);

  /// Checks if a setting with the given key exists.
  Future<bool> settingExists(String key);

  /// Clears all settings from the repository.
  ///
  /// Use with caution as this removes all user preferences.
  Future<void> clearAllSettings();
}
