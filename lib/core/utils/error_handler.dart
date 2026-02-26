import '../errors/app_error.dart';
import 'logger.dart';

/// Utility class for handling errors and providing user-friendly messages
class ErrorHandler {
  static final _logger = Logger.withTag('ErrorHandler');

  /// Handle an error and return a user-friendly message in French
  static String getUserMessage(Object error, [StackTrace? stackTrace]) {
    // Log the error
    _logger.error('Error occurred', error, stackTrace);

    // Return user-friendly message based on error type
    if (error is AppError) {
      return error.toString();
    }

    // Handle common Flutter/Dart exceptions
    if (error is FormatException) {
      return 'Format de données invalide';
    }

    if (error is TypeError) {
      return 'Erreur de type de données';
    }

    if (error is ArgumentError) {
      return 'Argument invalide: ${error.message}';
    }

    if (error is StateError) {
      return 'État invalide: ${error.message}';
    }

    if (error is UnsupportedError) {
      return 'Opération non prise en charge';
    }

    // Generic error message
    return 'Une erreur inattendue s\'est produite';
  }

  /// Handle an error and log it with appropriate severity
  static void handle(
    Object error, [
    StackTrace? stackTrace,
    String? context,
  ]) {
    final contextMsg = context != null ? '[$context] ' : '';

    if (error is AppError) {
      if (error is DatabaseError || error is FileSystemError) {
        _logger.error('$contextMsg${error.message}', error, stackTrace);
      } else if (error is NetworkError || error is AudioError) {
        _logger.warning('$contextMsg${error.message}', error, stackTrace);
      } else if (error is ValidationError) {
        _logger.info('$contextMsg${error.message}', error, stackTrace);
      } else {
        _logger.error('$contextMsg${error.message}', error, stackTrace);
      }
    } else {
      _logger.error('${contextMsg}Unexpected error', error, stackTrace);
    }
  }

  /// Check if an error is recoverable (user can retry)
  static bool isRecoverable(Object error) {
    if (error is NetworkError) {
      return true; // Network errors are usually temporary
    }

    if (error is AudioError) {
      // Some audio errors are recoverable (e.g., file not found can be skipped)
      return error.message != 'Échec de l\'initialisation audio';
    }

    if (error is ScannerError) {
      return true; // Scanner errors can be retried
    }

    if (error is ValidationError) {
      return true; // User can correct validation errors
    }

    return false;
  }

  /// Get a retry message for recoverable errors
  static String getRetryMessage(Object error) {
    if (error is NetworkError) {
      return 'Vérifiez votre connexion et réessayez';
    }

    if (error is ScannerError) {
      return 'Réessayer l\'analyse';
    }

    if (error is AudioError) {
      return 'Passer à la piste suivante';
    }

    return 'Réessayer';
  }

  /// Handle error with callback for UI updates
  static void handleWithCallback(
    Object error,
    StackTrace? stackTrace,
    void Function(String message, bool isRecoverable) onError,
  ) {
    handle(error, stackTrace);
    final message = getUserMessage(error, stackTrace);
    final recoverable = isRecoverable(error);
    onError(message, recoverable);
  }

  // Private constructor to prevent instantiation
  ErrorHandler._();
}
