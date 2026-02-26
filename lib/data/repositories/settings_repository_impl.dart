import '../../domain/repositories/settings_repository.dart';
import '../datasources/database/database_service.dart';

/// Implementation of SettingsRepository using DatabaseService.
///
/// This class provides concrete implementations of all settings-related
/// data operations using a key-value storage approach. It delegates to
/// the DatabaseService and provides convenience methods for common data types
/// (bool, int) in addition to the base string storage.
class SettingsRepositoryImpl implements SettingsRepository {
  final DatabaseService _databaseService;

  SettingsRepositoryImpl(this._databaseService);

  @override
  Future<String?> getSetting(String key) async {
    return await _databaseService.getSetting(key);
  }

  @override
  Future<void> setSetting(String key, String value) async {
    await _databaseService.setSetting(key, value);
  }

  @override
  Future<bool> getBoolSetting(String key, {bool defaultValue = false}) async {
    final value = await getSetting(key);
    if (value == null) {
      return defaultValue;
    }
    // Parse 'true' and '1' as true, everything else as false
    return value.toLowerCase() == 'true' || value == '1';
  }

  @override
  Future<void> setBoolSetting(String key, bool value) async {
    await setSetting(key, value ? 'true' : 'false');
  }

  @override
  Future<int> getIntSetting(String key, {int defaultValue = 0}) async {
    final value = await getSetting(key);
    if (value == null) {
      return defaultValue;
    }
    try {
      return int.parse(value);
    } catch (e) {
      return defaultValue;
    }
  }

  @override
  Future<void> setIntSetting(String key, int value) async {
    await setSetting(key, value.toString());
  }

  @override
  Future<void> deleteSetting(String key) async {
    // DatabaseService doesn't have a delete method, so we'll need to add it
    // For now, we can set it to an empty string or implement it in DatabaseService
    // Let's implement a workaround by getting the database and deleting directly
    final db = await _databaseService.database;
    await db.delete(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  @override
  Future<bool> settingExists(String key) async {
    final value = await getSetting(key);
    return value != null;
  }

  @override
  Future<void> clearAllSettings() async {
    // Clear all settings by getting the database and deleting all rows
    final db = await _databaseService.database;
    await db.delete('settings');
  }
}
