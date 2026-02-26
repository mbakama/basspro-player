import 'package:flutter/material.dart';
import '../../core/errors/app_error.dart';
import '../../core/utils/error_handler.dart';

/// Widget for displaying errors with user-friendly messages and retry options
class ErrorDisplay extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  final String? customMessage;

  const ErrorDisplay({
    super.key,
    required this.error,
    this.onRetry,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    final message = customMessage ?? ErrorHandler.getUserMessage(error);
    final isRecoverable = ErrorHandler.isRecoverable(error);
    final retryMessage = ErrorHandler.getRetryMessage(error);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getErrorIcon(),
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Une erreur est survenue',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            if (isRecoverable && onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryMessage),
              ),
            ],
            if (error is PermissionError) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  // TODO: Open app settings
                },
                icon: const Icon(Icons.settings),
                label: const Text('Ouvrir les paramètres'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getErrorIcon() {
    if (error is NetworkError) {
      return Icons.wifi_off;
    } else if (error is PermissionError) {
      return Icons.lock;
    } else if (error is AudioError) {
      return Icons.music_off;
    } else if (error is DatabaseError) {
      return Icons.storage;
    } else if (error is FileSystemError) {
      return Icons.folder_off;
    }
    return Icons.error_outline;
  }
}

/// Show an error snackbar with appropriate styling
void showErrorSnackBar(
  BuildContext context,
  Object error, {
  VoidCallback? onRetry,
  String? trackName,
}) {
  final message = ErrorHandler.getUserMessage(error);
  final isRecoverable = ErrorHandler.isRecoverable(error);

  // Build message with track name if provided
  final fullMessage = trackName != null 
      ? '$message\nPiste: $trackName'
      : message;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(fullMessage),
      backgroundColor: Theme.of(context).colorScheme.error,
      action: isRecoverable && onRetry != null
          ? SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: onRetry,
            )
          : null,
      duration: const Duration(seconds: 4),
    ),
  );
}

/// Show an error dialog with detailed information
Future<void> showErrorDialog(
  BuildContext context,
  Object error, {
  VoidCallback? onRetry,
  String? title,
}) async {
  final message = ErrorHandler.getUserMessage(error);
  final isRecoverable = ErrorHandler.isRecoverable(error);
  final retryMessage = ErrorHandler.getRetryMessage(error);

  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Text(title ?? 'Erreur'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          if (error is AppError && error.details != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Détails: ${error.details}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
        if (isRecoverable && onRetry != null)
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry();
            },
            child: Text(retryMessage),
          ),
      ],
    ),
  );
}
