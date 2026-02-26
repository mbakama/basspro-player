import 'dart:developer' as developer;

/// Logging utility for BassPro Player
/// Provides structured logging with different severity levels
class Logger {
  final String _tag;

  const Logger(this._tag);

  /// Log debug message (verbose information for development)
  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _log('DEBUG', message, error, stackTrace);
  }

  /// Log info message (general information)
  void info(String message, [Object? error, StackTrace? stackTrace]) {
    _log('INFO', message, error, stackTrace);
  }

  /// Log warning message (potential issues)
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _log('WARNING', message, error, stackTrace);
  }

  /// Log error message (errors that need attention)
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log('ERROR', message, error, stackTrace);
  }

  /// Log critical error (severe errors that may crash the app)
  void critical(String message, [Object? error, StackTrace? stackTrace]) {
    _log('CRITICAL', message, error, stackTrace);
  }

  void _log(
    String level,
    String message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] [$level] [$_tag] $message';

    // Use dart:developer log for better integration with Flutter DevTools
    developer.log(
      logMessage,
      time: DateTime.now(),
      level: _getLevelValue(level),
      name: _tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  int _getLevelValue(String level) {
    switch (level) {
      case 'DEBUG':
        return 500;
      case 'INFO':
        return 800;
      case 'WARNING':
        return 900;
      case 'ERROR':
        return 1000;
      case 'CRITICAL':
        return 1200;
      default:
        return 0;
    }
  }

  /// Create a logger for a specific class or component
  factory Logger.forClass(Type type) {
    return Logger(type.toString());
  }

  /// Create a logger with a custom tag
  factory Logger.withTag(String tag) {
    return Logger(tag);
  }
}

/// Pre-configured loggers for common components
class AppLoggers {
  static const app = Logger('App');
  static const database = Logger('Database');
  static const audio = Logger('AudioPlayer');
  static const equalizer = Logger('Equalizer');
  static const scanner = Logger('LibraryScanner');
  static const network = Logger('Network');
  static const ui = Logger('UI');
  static const storage = Logger('Storage');
  static const permissions = Logger('Permissions');
  static const cache = Logger('QueryCache');

  // Private constructor to prevent instantiation
  AppLoggers._();
}
