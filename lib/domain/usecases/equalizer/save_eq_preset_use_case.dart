import '../../entities/eq_preset.dart';
import '../../repositories/eq_preset_repository.dart';

/// Use case for saving an equalizer preset with name uniqueness validation.
///
/// This use case encapsulates the business logic for creating custom equalizer
/// presets, including validation of the preset name for uniqueness.
///
/// **Validates: Requirements 14.3**
class SaveEqPresetUseCase {
  final EqPresetRepository _repository;

  SaveEqPresetUseCase(this._repository);

  /// Saves a new equalizer preset with the given details.
  ///
  /// [name] is the name of the preset.
  /// [bandLevels] is the list of frequency band levels (must have 10 elements).
  /// [preamp] is the preamp gain level.
  /// [subBass] is the sub-bass boost level.
  /// [bass] is the bass boost level.
  /// [virtualizer] is the virtualizer/stereo widening level (default: 0.0).
  /// [limiterEnabled] indicates whether the limiter is enabled (default: true).
  ///
  /// Throws [ArgumentError] if:
  /// - The name is empty or contains only whitespace
  /// - The name already exists in the repository
  /// - The bandLevels list doesn't have exactly 10 elements
  ///
  /// Returns the ID of the created preset.
  Future<int> call({
    required String name,
    required List<double> bandLevels,
    required double preamp,
    required double subBass,
    required double bass,
    double virtualizer = 0.0,
    bool limiterEnabled = true,
  }) async {
    // Validate preset name
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Preset name cannot be empty');
    }

    // Check for name uniqueness
    final nameExists = await _repository.presetNameExists(trimmedName);
    if (nameExists) {
      throw ArgumentError('A preset with the name "$trimmedName" already exists');
    }

    // Validate band levels count
    if (bandLevels.length != 10) {
      throw ArgumentError('Band levels must contain exactly 10 elements, got ${bandLevels.length}');
    }

    final preset = EqPreset(
      name: trimmedName,
      bandLevels: List.from(bandLevels), // Create a copy to avoid external modifications
      preamp: preamp,
      subBass: subBass,
      bass: bass,
      virtualizer: virtualizer,
      limiterEnabled: limiterEnabled,
      createdAt: DateTime.now(),
      isBuiltin: false, // Custom presets are never built-in
    );

    return await _repository.insertEqPreset(preset);
  }
}
