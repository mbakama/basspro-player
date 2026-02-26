import 'package:flutter/material.dart';

/// Banner widget displayed when missing audio files are detected
/// 
/// This widget suggests rescanning the library to update the database
/// with current file availability.
class MissingFilesBanner extends StatelessWidget {
  final VoidCallback onRescan;
  final int missingCount;

  const MissingFilesBanner({
    super.key,
    required this.onRescan,
    this.missingCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.error,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  missingCount > 0
                      ? 'Fichiers manquants détectés'
                      : 'Fichiers manquants',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  missingCount > 0
                      ? '$missingCount fichier${missingCount > 1 ? 's' : ''} introuvable${missingCount > 1 ? 's' : ''}. Rescannez pour mettre à jour.'
                      : 'Certains fichiers sont introuvables. Rescannez la bibliothèque pour mettre à jour.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: onRescan,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Rescanner'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
          ),
        ],
      ),
    );
  }
}

/// Show a snackbar suggesting library rescan for missing files
void showRescanSuggestion(
  BuildContext context, {
  required VoidCallback onRescan,
  String? fileName,
}) {
  final message = fileName != null
      ? 'Fichier introuvable: $fileName'
      : 'Fichier introuvable';

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.error,
      action: SnackBarAction(
        label: 'Rescanner',
        textColor: Colors.white,
        onPressed: onRescan,
      ),
      duration: const Duration(seconds: 5),
    ),
  );
}

