import '../repositories/eq_preset_repository_impl.dart';
import '../datasources/database/database_service.dart';
import 'audio/audio_service_initializer.dart';
import 'audio/basspro_audio_handler.dart';
import '../../core/utils/logger.dart';

/// Service responsible for initializing the application on startup.
///
/// This service handles one-time initialization tasks such as:
/// - Initializing the audio service for background playback
/// - Initializing built-in equalizer presets (can be deferred)
/// - Setting up default settings
/// - Performing any necessary data migrations
///
/// Should be called once during app startup before the main UI is displayed.
class AppInitializationService {
  static const _logger = AppLoggers.app;
  final DatabaseService _databaseService;
  final EqPresetRepositoryImpl _eqPresetRepository;
  final bool _initializeAudio;
  final bool _deferPresetInitialization;

  AppInitializationService({
    required DatabaseService databaseService,
    required EqPresetRepositoryImpl eqPresetRepository,
    bool initializeAudio = true,
    bool deferPresetInitialization = false,
  })  : _databaseService = databaseService,
        _eqPresetRepository = eqPresetRepository,
        _initializeAudio = initializeAudio,
        _deferPresetInitialization = deferPresetInitialization;

  /// Initialize the application.
  ///
  /// This method should be called once during app startup.
  /// It performs all necessary initialization tasks in the correct order.
  ///
  /// Returns the initialized BassProAudioHandler if successful, null otherwise.
  Future<BassProAudioHandler?> initialize() async {
    try {
      _logger.info('Starting app initialization...');

      // Ensure database is initialized (critical - must be done first)
      await _databaseService.database;
      _logger.info('Database initialized');

      // Initialize built-in equalizer presets (can be deferred for faster startup)
      if (!_deferPresetInitialization) {
        await _initializeBuiltinPresets();
      } else {
        _logger.info('Preset initialization deferred (will load on demand)');
      }

      // Initialize audio service for background playback (if enabled)
      BassProAudioHandler? audioHandler;
      if (_initializeAudio) {
        audioHandler = await _initializeAudioService();
      } else {
        _logger.info('Audio service initialization skipped (test mode)');
      }

      _logger.info('App initialization completed successfully');
      return audioHandler;
    } catch (e, stackTrace) {
      _logger.error('App initialization failed', e, stackTrace);
      return null;
    }
  }

  /// Initialize built-in equalizer presets in the database.
  ///
  /// This method checks if each built-in preset already exists in the database.
  /// If a preset doesn't exist, it will be inserted.
  /// This ensures that built-in presets are always available to the user.
  ///
  /// This can be called lazily when the equalizer screen is first opened
  /// to improve startup performance.
  Future<void> _initializeBuiltinPresets() async {
    try {
      _logger.info('Initializing built-in equalizer presets...');
      await _eqPresetRepository.initializeBuiltinPresets();
      _logger.info('Built-in equalizer presets initialized');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize built-in presets', e, stackTrace);
      rethrow;
    }
  }

  /// Initialize the audio service for background playback.
  ///
  /// This method sets up the audio_service with BassProAudioHandler,
  /// which enables:
  /// - Background playback continuation
  /// - Notification area controls with track info
  /// - Lock screen media controls
  /// - Media button events from headphones/Bluetooth
  /// - Audio focus handling (pause on call, duck on notification)
  /// - Equalizer integration with all playback
  ///
  /// Returns the initialized BassProAudioHandler instance.
  Future<BassProAudioHandler> _initializeAudioService() async {
    try {
      _logger.info('Initializing audio service for background playback...');
      final audioHandler = await AudioServiceInitializer.initialize();
      _logger.info('Audio service initialized with system integration');
      return audioHandler;
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize audio service', e, stackTrace);
      rethrow;
    }
  }
}
