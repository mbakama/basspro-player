import 'dart:async';
import 'dart:math' as math;
import 'package:just_audio/just_audio.dart';
import '../../core/errors/app_error.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/eq_preset.dart';

/// Service for managing audio equalization with professional-grade controls.
///
/// This service provides:
/// - 10-band frequency equalization (32Hz to 16kHz)
/// - Preamp gain control
/// - Sub-bass boost (32Hz and 64Hz bands)
/// - Bass boost (125Hz and 250Hz bands)
/// - Limiter for anti-clipping protection
/// - Preset management
///
/// The service integrates with just_audio's AndroidEqualizer to provide
/// real-time audio processing for both local and streaming playback.
///
/// Note: The AudioPlayer must be created with an AudioPipeline containing
/// the AndroidEqualizer before initializing this service.
class EqualizerService {
  final AudioPlayer _player;
  final AndroidEqualizer _equalizer;
  static const _logger = AppLoggers.equalizer;

  // Warning event stream
  final _warningController = StreamController<String>.broadcast();

  // Frequency bands in Hz (10-band equalizer)
  // Note: Actual bands depend on device hardware
  static const List<int> targetFrequencyBands = [
    32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000
  ];

  // Current equalizer state
  final List<double> _bandLevels = [];
  double _preamp = 0.0;
  double _subBass = 0.0;
  double _bass = 0.0;
  bool _limiterEnabled = true;

  // Safe threshold for total gain (in dB)
  static const double safeThreshold = 12.0;

  // Band level constraints (in dB)
  static const double minBandLevel = -12.0;
  static const double maxBandLevel = 12.0;

  EqualizerService(this._player, this._equalizer);

  /// Initialize the equalizer with the audio player
  ///
  /// This must be called before using any equalizer functions.
  /// Throws [AudioError] if equalizer is not supported on the device.
  Future<void> initialize() async {
    try {
      _logger.info('Initializing equalizer service');

      // Enable the equalizer
      _logger.info('Enabling AndroidEqualizer...');
      await _equalizer.setEnabled(true);
      _logger.info('AndroidEqualizer enabled');

      // Get the equalizer parameters to determine available bands
      _logger.info('Fetching equalizer parameters...');
      final params = await _equalizer.parameters;
      _logger.info('Equalizer parameters fetched');
      final bands = params.bands;

      _logger.info('Equalizer has ${bands.length} bands');

      // Initialize band levels array
      _bandLevels.clear();
      for (int i = 0; i < bands.length; i++) {
        _bandLevels.add(0.0);
      }

      _logger.info('Equalizer initialized successfully with ${bands.length} bands');
    } catch (e) {
      _logger.error('Failed to initialize equalizer', e);
      // Don't rethrow - allow app to function without equalizer if it fails to init
      _logger.warning('App will continue without equalizer functionality');
    }
  }

  /// Set the level for a specific frequency band
  ///
  /// [bandIndex] must be between 0 and the number of available bands - 1
  /// [level] must be between -12.0 and 12.0 dB
  ///
  /// Throws [ValidationError] if parameters are out of range.
  Future<void> setBandLevel(int bandIndex, double level) async {
    if (bandIndex < 0 || bandIndex >= _bandLevels.length) {
      throw ValidationError.invalidRange('bandIndex', 0, _bandLevels.length - 1);
    }

    if (level < minBandLevel || level > maxBandLevel) {
      throw ValidationError.invalidRange('level', minBandLevel, maxBandLevel);
    }

    try {
      _logger.debug('Setting band $bandIndex to $level dB');

      // Get the equalizer parameters
      final params = await _equalizer.parameters;
      final band = params.bands[bandIndex];

      // Set the band level (gain is in dB)
      await band.setGain(level);

      // Update internal state
      _bandLevels[bandIndex] = level;

      // Apply limiter if enabled
      if (_limiterEnabled) {
        await _applyLimiter();
      } else {
        // Check for clipping risk when limiter is disabled
        isClippingRisk();
      }

      _logger.debug('Band $bandIndex set to $level dB');
    } catch (e) {
      _logger.error('Failed to set band level', e);
      if (e is AudioError || e is ValidationError) {
        rethrow;
      }
      throw AudioError.playbackFailed('Failed to set band level: $e');
    }
  }

  /// Set the preamp gain level
  ///
  /// [level] should be between -6.0 and 6.0 dB for safe operation.
  /// The preamp affects the overall volume before equalization.
  Future<void> setPreamp(double level) async {
    try {
      _logger.debug('Setting preamp to $level dB');

      // Store the requested preamp level
      _preamp = level;

      // Apply limiter if enabled (which may adjust the actual preamp)
      if (_limiterEnabled) {
        await _applyLimiter();
      } else {
        // Apply preamp directly through player volume
        await _setPreampInternal(level);
        // Check for clipping risk when limiter is disabled
        isClippingRisk();
      }

      _logger.debug('Preamp set to $level dB');
    } catch (e) {
      _logger.error('Failed to set preamp', e);
      throw AudioError.playbackFailed('Failed to set preamp: $e');
    }
  }

  /// Set the sub-bass boost level
  ///
  /// This boosts the 32Hz and 64Hz frequency bands.
  /// [level] should be between 0.0 and 10.0 dB.
  Future<void> setSubBass(double level) async {
    if (level < 0.0 || level > 10.0) {
      throw ValidationError.invalidRange('subBass', 0.0, 10.0);
    }

    try {
      _logger.debug('Setting sub-bass to $level dB');

      _subBass = level;

      // Boost 32Hz band (index 0)
      await setBandLevel(0, level);

      // Boost 64Hz band (index 1)
      await setBandLevel(1, level);

      _logger.debug('Sub-bass set to $level dB');
    } catch (e) {
      _logger.error('Failed to set sub-bass', e);
      if (e is ValidationError) {
        rethrow;
      }
      throw AudioError.playbackFailed('Failed to set sub-bass: $e');
    }
  }

  /// Set the bass boost level
  ///
  /// This boosts the 125Hz and 250Hz frequency bands.
  /// [level] should be between 0.0 and 10.0 dB.
  Future<void> setBass(double level) async {
    if (level < 0.0 || level > 10.0) {
      throw ValidationError.invalidRange('bass', 0.0, 10.0);
    }

    try {
      _logger.debug('Setting bass to $level dB');

      _bass = level;

      // Boost 125Hz band (index 2)
      await setBandLevel(2, level);

      // Boost 250Hz band (index 3)
      await setBandLevel(3, level);

      _logger.debug('Bass set to $level dB');
    } catch (e) {
      _logger.error('Failed to set bass', e);
      if (e is ValidationError) {
        rethrow;
      }
      throw AudioError.playbackFailed('Failed to set bass: $e');
    }
  }

  /// Enable or disable the limiter
  ///
  /// When enabled, the limiter automatically reduces gain to prevent clipping.
  /// When disabled, the user is responsible for avoiding distortion.
  Future<void> setLimiterEnabled(bool enabled) async {
    try {
      _logger.info('Setting limiter enabled: $enabled');

      _limiterEnabled = enabled;

      if (enabled) {
        // Apply limiter immediately
        await _applyLimiter();
      } else {
        // Restore the requested preamp level without limiting
        await _setPreampInternal(_preamp);
        // Check for clipping risk when limiter is disabled
        isClippingRisk();
      }

      _logger.info('Limiter ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      _logger.error('Failed to set limiter', e);
      throw AudioError.playbackFailed('Failed to set limiter: $e');
    }
  }

  /// Apply an equalizer preset
  ///
  /// This loads all settings from the preset including:
  /// - All band levels (up to the number of available bands)
  /// - Preamp gain
  /// - Sub-bass boost
  /// - Bass boost
  /// - Limiter status
  Future<void> applyPreset(EqPreset preset) async {
    try {
      _logger.info('Applying preset: ${preset.name}');

      // Validate band levels count
      if (preset.bandLevels.length != 10) {
        throw ValidationError.invalidFormat(
          'Preset must have exactly 10 band levels',
        );
      }

      // Apply band levels (up to the number of available bands)
      final numBands = _bandLevels.length < 10 ? _bandLevels.length : 10;
      for (int i = 0; i < numBands; i++) {
        await setBandLevel(i, preset.bandLevels[i]);
      }

      // Apply preamp
      await setPreamp(preset.preamp);

      // Apply sub-bass
      _subBass = preset.subBass;

      // Apply bass
      _bass = preset.bass;

      // Apply limiter setting
      await setLimiterEnabled(preset.limiterEnabled);

      _logger.info('Preset ${preset.name} applied successfully');
    } catch (e) {
      _logger.error('Failed to apply preset', e);
      if (e is ValidationError) {
        rethrow;
      }
      throw AudioError.playbackFailed('Failed to apply preset: $e');
    }
  }

  /// Check if current settings pose a clipping risk
  ///
  /// Returns true if the total gain exceeds the safe threshold
  /// and the limiter is disabled.
  bool isClippingRisk() {
    if (_limiterEnabled) {
      return false; // Limiter prevents clipping
    }

    final totalGain = calculateTotalGain();
    final isRisk = totalGain > safeThreshold;
    
    // Emit warning event when clipping risk is detected
    if (isRisk) {
      _emitWarning('Clipping risk detected: Total gain ${totalGain.toStringAsFixed(1)} dB exceeds safe threshold of $safeThreshold dB');
    }
    
    return isRisk;
  }

  /// Calculate the total gain from all equalizer settings
  ///
  /// This considers:
  /// - Preamp gain (full weight)
  /// - Positive band levels (50% weight)
  /// - Sub-bass boost (70% weight)
  /// - Bass boost (70% weight)
  double calculateTotalGain() {
    double total = _preamp;

    // Add positive band gains with 50% weight
    for (final level in _bandLevels) {
      if (level > 0) {
        total += level * 0.5;
      }
    }

    // Add sub-bass and bass with 70% weight
    total += _subBass * 0.7;
    total += _bass * 0.7;

    return total;
  }

  /// Get the safe preamp limit based on current settings
  ///
  /// This calculates the maximum preamp level that won't cause clipping
  /// given the current band levels and bass boost settings.
  double getSafePreampLimit() {
    double otherGains = 0.0;

    // Calculate gains from band levels
    for (final level in _bandLevels) {
      if (level > 0) {
        otherGains += level * 0.5;
      }
    }

    // Add sub-bass and bass gains
    otherGains += _subBass * 0.7;
    otherGains += _bass * 0.7;

    // Calculate safe preamp limit
    return safeThreshold - otherGains;
  }

  /// Apply the limiter by reducing preamp if total gain exceeds threshold
  Future<void> _applyLimiter() async {
    if (!_limiterEnabled) return;

    final totalGain = calculateTotalGain();

    if (totalGain > safeThreshold) {
      // Calculate how much to reduce
      final reduction = totalGain - safeThreshold;
      final safePreamp = _preamp - reduction;

      _logger.debug(
        'Limiter active: reducing preamp from $_preamp to $safePreamp dB '
        '(total gain: $totalGain dB)',
      );

      // Apply the reduced preamp
      await _setPreampInternal(safePreamp);
    } else {
      // Total gain is safe, apply requested preamp
      await _setPreampInternal(_preamp);
    }
  }

  /// Internal method to set preamp through player volume
  ///
  /// Converts dB to linear volume scale and applies to player.
  Future<void> _setPreampInternal(double levelInDb) async {
    // Convert dB to linear scale
    // Formula: linear = 10^(dB/20)
    // Clamp between 0.0 and 2.0 for safety
    final linearVolume = _dbToLinear(levelInDb).clamp(0.0, 2.0);

    _logger.debug('Setting internal preamp: $levelInDb dB = $linearVolume linear');

    // Apply volume to player
    await _player.setVolume(linearVolume);
  }

  /// Convert dB to linear scale
  double _dbToLinear(double db) {
    // 10^(dB/20)
    return (db / 20.0).exp10();
  }

  /// Get current band levels
  List<double> get bandLevels => List.unmodifiable(_bandLevels);

  /// Get current preamp level
  double get preamp => _preamp;

  /// Get current sub-bass level
  double get subBass => _subBass;

  /// Get current bass level
  double get bass => _bass;

  /// Get limiter enabled status
  bool get limiterEnabled => _limiterEnabled;

  /// Stream of warning messages for clipping risks
  Stream<String> get warningStream => _warningController.stream;

  /// Emit a warning event
  void _emitWarning(String message) {
    _logger.warning(message);
    _warningController.add(message);
  }

  /// Dispose resources
  Future<void> dispose() async {
    _logger.info('Disposing equalizer service');
    
    await _warningController.close();
    await _equalizer.setEnabled(false);
  }
}

/// Extension to add exp10 function (10^x)
extension on double {
  double exp10() {
    // 10^x = e^(x * ln(10))
    return math.exp(this * 2.302585092994046); // ln(10)
  }
}
