import '../../domain/entities/eq_preset.dart';
import '../../domain/repositories/eq_preset_repository.dart';
import '../datasources/database/database_service.dart';

/// Implementation of EqPresetRepository using DatabaseService.
///
/// This class provides concrete implementations of all equalizer preset-related
/// data operations including CRUD operations and built-in preset management.
/// It delegates to the DatabaseService and converts between database maps
/// and EqPreset entities.
///
/// Built-in presets are defined as static constants and can be initialized
/// in the database on first use.
class EqPresetRepositoryImpl implements EqPresetRepository {
  final DatabaseService _databaseService;

  EqPresetRepositoryImpl(this._databaseService);

  /// Built-in equalizer presets
  static final List<EqPreset> builtinPresets = [
    EqPreset(
      name: 'Deep Bass',
      bandLevels: [8.0, 6.0, 4.0, 2.0, 0.0, -1.0, -2.0, -2.0, -2.0, -2.0],
      preamp: -3.0,
      subBass: 8.0,
      bass: 6.0,
      limiterEnabled: true,
      createdAt: DateTime.now(),
      isBuiltin: true,
    ),
    EqPreset(
      name: 'Punch Bass',
      bandLevels: [6.0, 7.0, 5.0, 2.0, 0.0, 0.0, 1.0, 2.0, 1.0, 0.0],
      preamp: -2.0,
      subBass: 5.0,
      bass: 7.0,
      limiterEnabled: true,
      createdAt: DateTime.now(),
      isBuiltin: true,
    ),
    EqPreset(
      name: 'Hip-Hop',
      bandLevels: [7.0, 5.0, 3.0, 1.0, -1.0, -1.0, 1.0, 2.0, 3.0, 4.0],
      preamp: -2.0,
      subBass: 6.0,
      bass: 5.0,
      limiterEnabled: true,
      createdAt: DateTime.now(),
      isBuiltin: true,
    ),
    EqPreset(
      name: 'EDM',
      bandLevels: [6.0, 4.0, 2.0, 0.0, -2.0, -2.0, 0.0, 2.0, 4.0, 6.0],
      preamp: -3.0,
      subBass: 7.0,
      bass: 5.0,
      limiterEnabled: true,
      createdAt: DateTime.now(),
      isBuiltin: true,
    ),
    EqPreset(
      name: 'Rock',
      bandLevels: [5.0, 3.0, 1.0, -1.0, -2.0, -1.0, 1.0, 3.0, 4.0, 5.0],
      preamp: -2.0,
      subBass: 3.0,
      bass: 4.0,
      limiterEnabled: true,
      createdAt: DateTime.now(),
      isBuiltin: true,
    ),
    EqPreset(
      name: 'Pop',
      bandLevels: [2.0, 3.0, 4.0, 3.0, 1.0, 0.0, 1.0, 2.0, 3.0, 2.0],
      preamp: -1.0,
      subBass: 2.0,
      bass: 3.0,
      limiterEnabled: true,
      createdAt: DateTime.now(),
      isBuiltin: true,
    ),
    EqPreset(
      name: 'Vocal Clarity',
      bandLevels: [-2.0, -1.0, 0.0, 2.0, 4.0, 5.0, 4.0, 2.0, 0.0, -1.0],
      preamp: -1.0,
      subBass: 0.0,
      bass: 0.0,
      limiterEnabled: true,
      createdAt: DateTime.now(),
      isBuiltin: true,
    ),
    EqPreset(
      name: 'Balanced',
      bandLevels: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
      preamp: 0.0,
      subBass: 0.0,
      bass: 0.0,
      limiterEnabled: true,
      createdAt: DateTime.now(),
      isBuiltin: true,
    ),
  ];

  /// Initialize built-in presets in the database if they don't exist
  Future<void> initializeBuiltinPresets() async {
    for (final preset in builtinPresets) {
      final exists = await presetNameExists(preset.name);
      if (!exists) {
        await insertEqPreset(preset);
      }
    }
  }

  @override
  Future<int> insertEqPreset(EqPreset preset) async {
    final map = preset.toMap();
    map.remove('id'); // Remove id for insertion
    return await _databaseService.insertEqPreset(map);
  }

  @override
  Future<EqPreset?> getEqPreset(int id) async {
    final map = await _databaseService.getEqPreset(id);
    return map != null ? EqPreset.fromMap(map) : null;
  }

  @override
  Future<EqPreset?> getEqPresetByName(String name) async {
    final allPresets = await getAllEqPresets();
    try {
      return allPresets.firstWhere((preset) => preset.name == name);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<EqPreset>> getAllEqPresets() async {
    final maps = await _databaseService.getAllEqPresets();
    return maps.map((map) => EqPreset.fromMap(map)).toList();
  }

  @override
  Future<List<EqPreset>> getCustomEqPresets() async {
    final allPresets = await getAllEqPresets();
    return allPresets.where((preset) => !preset.isBuiltin).toList();
  }

  @override
  Future<List<EqPreset>> getBuiltinEqPresets() async {
    final allPresets = await getAllEqPresets();
    return allPresets.where((preset) => preset.isBuiltin).toList();
  }

  @override
  Future<void> updateEqPreset(EqPreset preset) async {
    if (preset.id == null) {
      throw ArgumentError('EqPreset must have an id to be updated');
    }
    if (preset.isBuiltin) {
      throw ArgumentError('Built-in presets cannot be updated');
    }
    final map = preset.toMap();
    map.remove('id'); // Remove id from update map
    await _databaseService.updateEqPreset(preset.id!, map);
  }

  @override
  Future<void> deleteEqPreset(int id) async {
    final preset = await getEqPreset(id);
    if (preset == null) {
      throw ArgumentError('EqPreset with id $id not found');
    }
    if (preset.isBuiltin) {
      throw ArgumentError('Built-in presets cannot be deleted');
    }
    await _databaseService.deleteEqPreset(id);
  }

  @override
  Future<bool> presetNameExists(String name) async {
    final preset = await getEqPresetByName(name);
    return preset != null;
  }
}
