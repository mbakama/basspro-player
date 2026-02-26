import '../entities/eq_preset.dart';

/// Repository interface for EqPreset entity operations.
///
/// Defines the contract for data access operations related to equalizer presets,
/// including CRUD operations and built-in preset management.
abstract class EqPresetRepository {
  /// Inserts a new equalizer preset into the repository.
  ///
  /// Returns the ID of the inserted preset.
  Future<int> insertEqPreset(EqPreset preset);

  /// Retrieves an equalizer preset by its ID.
  ///
  /// Returns null if no preset with the given ID exists.
  Future<EqPreset?> getEqPreset(int id);

  /// Retrieves an equalizer preset by its name.
  ///
  /// Returns null if no preset with the given name exists.
  Future<EqPreset?> getEqPresetByName(String name);

  /// Retrieves all equalizer presets from the repository.
  ///
  /// This includes both built-in and custom presets.
  Future<List<EqPreset>> getAllEqPresets();

  /// Retrieves only custom (non-built-in) equalizer presets.
  Future<List<EqPreset>> getCustomEqPresets();

  /// Retrieves only built-in equalizer presets.
  Future<List<EqPreset>> getBuiltinEqPresets();

  /// Updates an existing equalizer preset in the repository.
  ///
  /// Built-in presets should not be updated.
  Future<void> updateEqPreset(EqPreset preset);

  /// Deletes an equalizer preset by its ID.
  ///
  /// Built-in presets should not be deleted.
  Future<void> deleteEqPreset(int id);

  /// Checks if a preset name already exists in the repository.
  ///
  /// Useful for validating unique preset names before insertion.
  Future<bool> presetNameExists(String name);
}
