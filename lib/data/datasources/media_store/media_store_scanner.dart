import 'package:flutter/services.dart';
import '../../../core/utils/logger.dart';

/// Service for scanning audio files from Android MediaStore
class MediaStoreScanner {
  static const MethodChannel _channel =
      MethodChannel('com.basspro.player/mediastore');
  
  static final _logger = Logger.withTag('MediaStoreScanner');

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
      _logger.info('Querying audio files from MediaStore');
      
      final result = await _channel.invokeMethod<List<dynamic>>('queryAudioFiles');
      
      if (result == null) {
        _logger.warning('MediaStore query returned null');
        return [];
      }

      final audioFiles = result
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      _logger.info('Found ${audioFiles.length} audio files');
      return audioFiles;
    } on PlatformException catch (e) {
      _logger.error('Failed to query audio files: ${e.message}', e);
      rethrow;
    } catch (e) {
      _logger.error('Unexpected error querying audio files', e);
      rethrow;
    }
  }
}
