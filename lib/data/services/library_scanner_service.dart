import 'dart:async';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/errors/app_error.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/track.dart';
import '../datasources/database/database_service.dart';
import '../datasources/media_store/media_store_scanner.dart';

/// Service for scanning the device's music library and storing tracks in the database.
///
/// This service handles:
/// - Requesting storage permissions
/// - Scanning audio files from MediaStore
/// - Converting MediaStore results to Track entities
/// - Storing tracks in the database with conflict resolution
/// - Emitting progress events during scanning
class LibraryScannerService {
  final DatabaseService _database;
  final MediaStoreScanner _mediaStoreScanner;
  static const _logger = AppLoggers.scanner;

  final StreamController<ScanProgress> _progressController =
      StreamController<ScanProgress>.broadcast();

  LibraryScannerService({
    DatabaseService? database,
    MediaStoreScanner? mediaStoreScanner,
  })  : _database = database ?? DatabaseService(),
        _mediaStoreScanner = mediaStoreScanner ?? MediaStoreScanner();

  /// Stream of scan progress events
  Stream<ScanProgress> get scanProgressStream => _progressController.stream;

  /// Request storage permissions required for scanning
  ///
  /// Returns true if permissions are granted, false otherwise.
  /// Handles different Android versions appropriately:
  /// - Android 10+: Uses scoped storage (no permission needed)
  /// - Android 9 and below: Requests READ_EXTERNAL_STORAGE
  Future<bool> requestPermissions() async {
    try {
      _logger.info('Requesting storage permissions');

      // On Android 10+ (API 29+), we can use MediaStore without storage permission
      // For older versions, we need READ_EXTERNAL_STORAGE
      if (await Permission.storage.isGranted) {
        _logger.info('Storage permission already granted');
        return true;
      }

      // Request permission
      final status = await Permission.storage.request();

      if (status.isGranted) {
        _logger.info('Storage permission granted');
        return true;
      } else if (status.isPermanentlyDenied) {
        _logger.warning('Storage permission permanently denied');
        throw PermissionError.storageDenied();
      } else {
        _logger.warning('Storage permission denied');
        return false;
      }
    } catch (e) {
      if (e is PermissionError) {
        rethrow;
      }
      _logger.error('Error requesting permissions', e);
      throw PermissionError.generic('storage');
    }
  }

  /// Scan the device's music library and store tracks in the database
  ///
  /// This method:
  /// 1. Requests permissions if needed
  /// 2. Queries MediaStore for audio files
  /// 3. Converts results to Track entities
  /// 4. Stores tracks in database with conflict resolution
  /// 5. Emits progress events throughout the process
  ///
  /// Returns a [ScanResult] with statistics about the scan.
  /// Throws [PermissionError] if permissions are denied.
  /// Throws [ScannerError] if scanning fails.
  Future<ScanResult> scanLibrary() async {
    try {
      _logger.info('Starting library scan');
      _emitProgress(ScanProgress(
        status: ScanStatus.requesting_permissions,
        message: 'Demande des permissions...',
      ));

      // Request permissions
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        throw PermissionError.storageDenied();
      }

      _emitProgress(ScanProgress(
        status: ScanStatus.scanning,
        message: 'Analyse des fichiers audio...',
      ));

      // Query MediaStore for audio files
      final audioFiles = await _mediaStoreScanner.queryAudioFiles();
      _logger.info('Found ${audioFiles.length} audio files from MediaStore');

      if (audioFiles.isEmpty) {
        _emitProgress(ScanProgress(
          status: ScanStatus.completed,
          message: 'Aucune piste trouvée',
          tracksFound: 0,
          tracksAdded: 0,
        ));
        return ScanResult(
          tracksFound: 0,
          tracksAdded: 0,
          tracksRemoved: 0,
          errors: [],
        );
      }

      _emitProgress(ScanProgress(
        status: ScanStatus.processing,
        message: 'Traitement de ${audioFiles.length} pistes...',
        tracksFound: audioFiles.length,
      ));

      // Get existing tracks from database to identify removed tracks
      final existingTracks = await _database.getAllTracks();
      final existingUris = existingTracks.map((t) => t['uri'] as String).toSet();
      final scannedUris = <String>{};

      // Convert MediaStore results to Track entities
      final tracksToInsert = <Map<String, dynamic>>[];
      final errors = <String>[];

      for (final audioFile in audioFiles) {
        try {
          final track = _convertToTrack(audioFile);
          scannedUris.add(track.uri);
          tracksToInsert.add(track.toMap());
        } catch (e) {
          _logger.warning('Failed to process track: ${audioFile['title']}', e);
          errors.add('Échec du traitement: ${audioFile['title']}');
        }
      }

      // Batch insert all tracks in a single transaction for better performance
      int tracksAdded = 0;
      if (tracksToInsert.isNotEmpty) {
        _emitProgress(ScanProgress(
          status: ScanStatus.processing,
          message: 'Enregistrement de ${tracksToInsert.length} pistes...',
          tracksFound: audioFiles.length,
          progress: 0.5,
        ));

        tracksAdded = await _database.insertTracksBatch(tracksToInsert);
        
        _logger.info('Batch inserted $tracksAdded tracks');
      }

      // Identify and remove tracks that no longer exist
      int tracksRemoved = 0;
      final tracksToRemove = existingUris.difference(scannedUris);
      
      if (tracksToRemove.isNotEmpty) {
        _emitProgress(ScanProgress(
          status: ScanStatus.cleaning,
          message: 'Nettoyage des pistes supprimées...',
          tracksFound: audioFiles.length,
          tracksAdded: tracksAdded,
        ));

        for (final uri in tracksToRemove) {
          try {
            final trackToRemove = existingTracks.firstWhere(
              (t) => t['uri'] == uri,
            );
            await _database.deleteTrack(trackToRemove['id'] as int);
            tracksRemoved++;
          } catch (e) {
            _logger.warning('Failed to remove track with URI: $uri', e);
          }
        }
      }

      _logger.info(
        'Library scan completed: $tracksAdded added, $tracksRemoved removed',
      );

      _emitProgress(ScanProgress(
        status: ScanStatus.completed,
        message: 'Analyse terminée',
        tracksFound: audioFiles.length,
        tracksAdded: tracksAdded,
        tracksRemoved: tracksRemoved,
        progress: 1.0,
      ));

      return ScanResult(
        tracksFound: audioFiles.length,
        tracksAdded: tracksAdded,
        tracksRemoved: tracksRemoved,
        errors: errors,
      );
    } on PermissionError {
      _emitProgress(ScanProgress(
        status: ScanStatus.error,
        message: 'Permission refusée',
      ));
      rethrow;
    } on PlatformException catch (e) {
      _logger.error('Platform error during library scan', e);
      _emitProgress(ScanProgress(
        status: ScanStatus.error,
        message: 'Erreur lors de l\'analyse',
      ));
      throw ScannerError.scanFailed(e.message);
    } catch (e) {
      _logger.error('Unexpected error during library scan', e);
      _emitProgress(ScanProgress(
        status: ScanStatus.error,
        message: 'Erreur inattendue',
      ));
      throw ScannerError.scanFailed(e.toString());
    }
  }

  /// Convert MediaStore audio file data to Track entity
  Track _convertToTrack(Map<String, dynamic> audioFile) {
    return Track(
      title: audioFile['title'] as String? ?? 'Unknown',
      artist: audioFile['artist'] as String? ?? 'Unknown Artist',
      album: audioFile['album'] as String? ?? 'Unknown Album',
      duration: Duration(milliseconds: (audioFile['duration'] as int?) ?? 0),
      uri: audioFile['uri'] as String,
      artworkUri: audioFile['artworkUri'] as String?,
      dateAdded: DateTime.fromMillisecondsSinceEpoch(
        (audioFile['dateAdded'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
      playCount: 0,
      isFavorite: false,
    );
  }

  /// Emit a progress event to listeners
  void _emitProgress(ScanProgress progress) {
    if (!_progressController.isClosed) {
      _progressController.add(progress);
    }
  }

  /// Dispose resources
  void dispose() {
    _progressController.close();
  }
}

/// Result of a library scan operation
class ScanResult {
  final int tracksFound;
  final int tracksAdded;
  final int tracksRemoved;
  final List<String> errors;

  const ScanResult({
    required this.tracksFound,
    required this.tracksAdded,
    required this.tracksRemoved,
    required this.errors,
  });

  @override
  String toString() {
    return 'ScanResult(found: $tracksFound, added: $tracksAdded, '
        'removed: $tracksRemoved, errors: ${errors.length})';
  }
}

/// Progress information during library scanning
class ScanProgress {
  final ScanStatus status;
  final String message;
  final int? tracksFound;
  final int? tracksAdded;
  final int? tracksRemoved;
  final double? progress; // 0.0 to 1.0

  const ScanProgress({
    required this.status,
    required this.message,
    this.tracksFound,
    this.tracksAdded,
    this.tracksRemoved,
    this.progress,
  });

  @override
  String toString() {
    return 'ScanProgress(status: $status, message: $message, '
        'found: $tracksFound, added: $tracksAdded, removed: $tracksRemoved, '
        'progress: $progress)';
  }
}

/// Status of the library scan operation
enum ScanStatus {
  requesting_permissions,
  scanning,
  processing,
  cleaning,
  completed,
  error,
}
