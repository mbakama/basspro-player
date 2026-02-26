import '../../entities/eq_preset.dart';
import '../../repositories/eq_preset_repository.dart';

/// Use case for retrieving all equalizer presets.
///
/// This use case encapsulates the business logic for fetching all equalizer
/// presets from the repository, including both built-in and custom presets.
///
/// **Validates: Requirements 14.1, 14.2**
class GetAllEqPresetsUseCase {
  final EqPresetRepository _repository;

  GetAllEqPresetsUseCase(this._repository);

  /// Retrieves all equalizer presets.
  ///
  /// Returns a list of all presets, with built-in presets typically appearing first.
  /// The list includes both built-in presets (Deep Bass, Punch Bass, Hip-Hop, EDM,
  /// Rock, Pop, Vocal Clarity, Balanced) and any custom user-created presets.
  Future<List<EqPreset>> call() async {
    return await _repository.getAllEqPresets();
  }
}
