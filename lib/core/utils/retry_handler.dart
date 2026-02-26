import 'dart:async';
import 'dart:math';
import '../errors/app_error.dart';
import 'logger.dart';

/// Handles automatic retry with exponential backoff for failed operations
class RetryHandler {
  static final _logger = Logger.withTag('RetryHandler');

  /// Retry a function with exponential backoff
  /// 
  /// Parameters:
  /// - [operation]: The async function to retry
  /// - [maxAttempts]: Maximum number of retry attempts (default: 3)
  /// - [initialDelay]: Initial delay before first retry in milliseconds (default: 1000ms)
  /// - [maxDelay]: Maximum delay between retries in milliseconds (default: 10000ms)
  /// - [shouldRetry]: Optional function to determine if error is retryable
  /// 
  /// Returns the result of the operation if successful
  /// Throws the last error if all retries fail
  static Future<T> retry<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    int initialDelay = 1000,
    int maxDelay = 10000,
    bool Function(Object error)? shouldRetry,
  }) async {
    int attempt = 0;
    int delay = initialDelay;

    while (true) {
      try {
        attempt++;
        _logger.debug('Attempt $attempt of $maxAttempts');
        
        final result = await operation();
        
        if (attempt > 1) {
          _logger.info('Operation succeeded after $attempt attempts');
        }
        
        return result;
      } catch (error, stackTrace) {
        // Check if we should retry this error
        final canRetry = shouldRetry?.call(error) ?? _isRetryableError(error);
        
        if (!canRetry) {
          _logger.warning('Error is not retryable, failing immediately');
          rethrow;
        }

        // Check if we've exhausted all attempts
        if (attempt >= maxAttempts) {
          _logger.error(
            'Operation failed after $maxAttempts attempts',
            error,
            stackTrace,
          );
          rethrow;
        }

        // Calculate next delay with exponential backoff and jitter
        final nextDelay = min(
          delay * pow(2, attempt - 1).toInt(),
          maxDelay,
        );
        
        // Add jitter (random variation) to prevent thundering herd
        final jitter = Random().nextInt(nextDelay ~/ 4);
        final delayWithJitter = nextDelay + jitter;

        _logger.warning(
          'Attempt $attempt failed, retrying in ${delayWithJitter}ms',
          error,
        );

        // Wait before retrying
        await Future.delayed(Duration(milliseconds: delayWithJitter));
      }
    }
  }

  /// Retry a stream connection with exponential backoff
  /// 
  /// This is specifically designed for streaming operations where
  /// we want to retry connection failures automatically.
  /// 
  /// Parameters:
  /// - [streamUrl]: The URL of the stream to connect to
  /// - [connectFunction]: Function that attempts to connect to the stream
  /// - [maxAttempts]: Maximum number of retry attempts (default: 5 for streams)
  /// - [onRetry]: Optional callback called before each retry with attempt number
  /// 
  /// Returns the result of the connection if successful
  /// Throws NetworkError if all retries fail
  static Future<T> retryStream<T>({
    required String streamUrl,
    required Future<T> Function() connectFunction,
    int maxAttempts = 5,
    void Function(int attempt, Duration delay)? onRetry,
  }) async {
    return retry<T>(
      operation: connectFunction,
      maxAttempts: maxAttempts,
      initialDelay: 2000, // Start with 2 seconds for streams
      maxDelay: 30000, // Max 30 seconds between retries
      shouldRetry: (error) {
        // Only retry network-related errors for streams
        if (error is NetworkError) {
          // Don't retry invalid URLs
          return error.message != 'URL invalide';
        }
        return _isNetworkError(error);
      },
    );
  }

  /// Check if an error is retryable
  static bool _isRetryableError(Object error) {
    // Network errors are usually retryable
    if (error is NetworkError) {
      // Don't retry invalid URLs
      return error.message != 'URL invalide';
    }

    // Some audio errors are retryable (temporary issues)
    if (error is AudioError) {
      // Don't retry unsupported formats or corrupted files
      return error.message != 'Format audio non pris en charge' &&
             error.message != 'Fichier audio corrompu';
    }

    // Scanner errors can be retried
    if (error is ScannerError) {
      return true;
    }

    // Check for common network-related exceptions
    return _isNetworkError(error);
  }

  /// Check if an error is network-related
  static bool _isNetworkError(Object error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socket') ||
           errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('unreachable');
  }

  // Private constructor to prevent instantiation
  RetryHandler._();
}

