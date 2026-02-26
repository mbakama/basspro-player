import 'package:flutter/services.dart';
import '../../../core/utils/logger.dart';

/// Service for scanning audio files from Android MediaStore
class MediaStoreScanner {
  static const MethodChannel _channel =
      MethodChannel('com.example.basspro_player/mediastore');

  /// Query all audio files from Android MediaStore
  /// 
  /// Returns a list of maps containing audio file metadata:
  /// - id: MediaStore audio ID
  /// - title: Track title
  /// - artist: Artist name
  /// - album: Album name
  /// - duration: Duration in milliseconds
  /// - uri: Content URI for the audio file
  /// - artworkUri: Content URI for album artwork
  /// - dateAdded: Date added timestamp in milliseconds
  Future<List<Map<String, dynamic>>> queryAudioFiles() async {
    try {
      AppLogger.info('Querying audio files from MediaStore');
      
      final result = await _channel.invokeMethod<List<dynamic>>('queryAudioFiles');
      
      if (result == null) {
        AppLogger.warning('MediaStore query returned null');
        return [];
      }

      final audioFiles = result
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      AppLogger.info('Found ${audioFiles.length} audio files');
      return audioFiles;
    } on PlatformException catch (e) {
      AppLogger.error('Failed to query audio files: ${e.message}', e);
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected error querying audio files', e);
      rethrow;
    }
  }
}
