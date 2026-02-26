/// Application-wide constants for BassPro Player
class AppConstants {
  // Database constants
  static const String dbName = 'basspro_player.db';
  static const int dbVersion = 1;

  // Equalizer constants
  static const double safeGainThreshold = 12.0; // dB
  static const int numBands = 10;
  
  // Frequency bands (Hz)
  static const List<int> frequencyBands = [
    32,    // Sub-bass
    64,    // Sub-bass
    125,   // Bass
    250,   // Bass
    500,   // Low-mid
    1000,  // Mid (1kHz)
    2000,  // High-mid (2kHz)
    4000,  // High-mid (4kHz)
    8000,  // High (8kHz)
    16000, // High (16kHz)
  ];

  // Equalizer ranges
  static const double minBandLevel = -12.0; // dB
  static const double maxBandLevel = 12.0;  // dB
  static const double minPreamp = -6.0;     // dB
  static const double maxPreamp = 6.0;      // dB
  static const double minBassBoost = 0.0;   // dB
  static const double maxBassBoost = 10.0;  // dB

  // Audio settings
  static const int defaultBufferSize = 4096;
  static const int streamConnectionTimeout = 10; // seconds

  // UI constants
  static const double minTouchTarget = 48.0; // dp
  static const int animationDurationMs = 300;
  static const int shortAnimationDurationMs = 150;
  static const int longAnimationDurationMs = 400;

  // Pagination
  static const int defaultPageSize = 50;
  static const int maxCachedArtwork = 100;

  // Sleep timer options (minutes)
  static const List<int> sleepTimerOptions = [15, 30, 45, 60, 90];

  // Settings keys
  static const String settingsKeyTheme = 'theme';
  static const String settingsKeyDefaultPreset = 'default_preset';
  static const String settingsKeyKeepScreenAwake = 'keep_screen_awake';
  static const String settingsKeySleepTimer = 'sleep_timer';
  static const String settingsKeyLastScanTime = 'last_scan_time';

  // Theme values
  static const String themeDark = 'dark';
  static const String themeLight = 'light';

  // Platform channel
  static const String mediaStoreChannel = 'com.basspro.player/mediastore';

  // Notification
  static const String notificationChannelId = 'basspro_player_playback';
  static const String notificationChannelName = 'Lecture audio';
  static const String notificationChannelDescription = 'Contrôles de lecture audio';

  // Private constructor to prevent instantiation
  AppConstants._();
}
