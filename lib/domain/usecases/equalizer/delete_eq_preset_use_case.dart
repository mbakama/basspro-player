import '../../repositories/eq_preset_repository.dart';

/// Use case for deleting an equalizer preset with built-in preset protection.
///
/// This use case encapsulates the business logic for removing custom equalizer
/// presets while preventing deletion of built-in presets.
///
/// **Validates: Requirements 14.4**
class DeleteEqPresetUseCase {
  final EqPresetRepository _repository;

  DeleteEqPresetUseCase(this._repository);

  /// Deletes an equalizer preset by its ID.
  ///
  /// [presetId] is the ID of the preset to delete.
  ///
  /// Throws [ArgumentError] if:
  /// - The preset ID is invalid (less than or equal to 0)
  /// - The preset is a built-in preset (cannot be deleted)
  /// - The preset doesn't exist
  Future<void> call(int presetId) async {
    if (presetId <= 0) {
      throw ArgumentError('Invalid preset ID: $presetId');
    }

    // Retrieve the preset to check if it's built-in
    final preset = await _repository.getEqPreset(presetId);
    
    if (preset == null) {
      throw ArgumentError('Preset with ID $presetId does not exist');
    }

    // Prevent deletion of built-in presets
    if (preset.isBuiltin) {
      throw ArgumentError('Cannot delete built-in preset "${preset.name}"');
    }

    await _repository.deleteEqPreset(presetId);
  }
}
