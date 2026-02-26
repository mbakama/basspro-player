import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'basspro_audio_handler.dart';
import '../equalizer_service.dart';
import '../../../core/utils/logger.dart';

/// Service responsible for initializing the audio_service with BassProAudioHandler.
///
/// This service sets up the background audio playback infrastructure including:
/// - AudioPlayer instance for playback
/// - EqualizerService for audio processing
/// - BassProAudioHandler for system integration
/// - MediaSession configuration for notifications and lock screen controls
///
/// The audio_service package automatically handles:
/// - Background playback continuation
/// - Notification area controls with track info
/// - Lock screen media controls
/// - Media button events from headphones/Bluetooth
/// - Audio focus handling (pause on call, duck on notification)
///
/// Usage:
/// ```dart
/// final audioHandler = await AudioServiceInitializer.initialize();
/// ```
class AudioServiceInitializer {
  static const _logger = AppLoggers.audio;
  static BassProAudioHandler? _audioHandler;

  /// Initialize the audio service with BassProAudioHandler.
  ///
  /// This method should be called once during app startup.
  /// It creates and configures all necessary components for audio playback.
  ///
  /// Returns the initialized BassProAudioHandler instance.
  ///
  /// Throws an exception if initialization fails.
  static Future<BassProAudioHandler> initialize() async {
    try {
      _logger.info('Initializing audio service...');

      // Return existing handler if already initialized
      if (_audioHandler != null) {
        _logger.info('Audio service already initialized, returning existing handler');
        return _audioHandler!;
      }

      // Create AudioPlayer instance
      final audioPlayer = AudioPlayer();
      _logger.debug('AudioPlayer instance created');

      // Create AndroidEqualizer for the audio player
      final equalizer = AndroidEqualizer();
      await audioPlayer.setAudioSource(
        AudioSource.uri(Uri.parse('silence')),
        initialPosition: Duration.zero,
        preload: false,
      );
      _logger.debug('AndroidEqualizer instance created');

      // Create EqualizerService instance
      final equalizerService = EqualizerService(audioPlayer, equalizer);
      await equalizerService.initialize();
      _logger.debug('EqualizerService initialized');

      // Initialize audio_service with BassProAudioHandler
      // The AudioService.init method sets up the background service
      // and configures MediaSession for system integration
      _audioHandler = await AudioService.init(
        builder: () => BassProAudioHandler(audioPlayer, equalizerService),
        config: AudioServiceConfig(
          // Android configuration
          androidNotificationChannelId: 'com.example.basspro_player.audio',
          androidNotificationChannelName: 'BassPro Player',
          androidNotificationChannelDescription: 'Contrôles de lecture audio',
          
          // Notification configuration
          androidNotificationOngoing: true, // Keep notification while playing
          androidNotificationClickStartsActivity: true, // Tap opens app
          androidShowNotificationBadge: true,
          
          // Notification icon (uses default app icon)
          androidNotificationIcon: 'mipmap/ic_launcher',
          
          // Stop service when task is removed from recent apps
          androidStopForegroundOnPause: false, // Keep service alive when paused
          
          // Artwork configuration
          artDownscaleWidth: 256,
          artDownscaleHeight: 256,
          
          // Preload artwork for smoother transitions
          preloadArtwork: true,
          
          // Fast forward/rewind intervals
          fastForwardInterval: const Duration(seconds: 10),
          rewindInterval: const Duration(seconds: 10),
        ),
      );

      _logger.info('Audio service initialized successfully');
      _logger.info('MediaSession configured for notifications and lock screen controls');
      _logger.info('Audio focus handling enabled');
      _logger.info('Media button events enabled for headphones/Bluetooth');

      return _audioHandler!;
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize audio service', e, stackTrace);
      rethrow;
    }
  }

  /// Get the current audio handler instance.
  ///
  /// Returns null if the audio service has not been initialized yet.
  static BassProAudioHandler? get audioHandler => _audioHandler;

  /// Dispose the audio service and clean up resources.
  ///
  /// This should be called when the app is shutting down.
  static Future<void> dispose() async {
    try {
      _logger.info('Disposing audio service...');
      
      if (_audioHandler != null) {
        await _audioHandler!.dispose();
        _audioHandler = null;
      }
      
      _logger.info('Audio service disposed');
    } catch (e, stackTrace) {
      _logger.error('Error disposing audio service', e, stackTrace);
    }
  }
}
