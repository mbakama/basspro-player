import 'package:audio_service/audio_service.dart';
import '../../domain/entities/track.dart';

/// Mapper to convert domain Track entities to audio_service MediaItems.
extension TrackToMediaItem on Track {
  MediaItem toMediaItem() {
    return MediaItem(
      id: uri,
      album: album,
      title: title,
      artist: artist,
      duration: duration,
      artUri: artworkUri != null ? Uri.parse(artworkUri!) : null,
      extras: {
        'id': id,
        'dateAdded': dateAdded.millisecondsSinceEpoch,
        'playCount': playCount,
        'isFavorite': isFavorite,
      },
    );
  }
}

extension MediaItemToTrack on MediaItem {
  Track toTrack() {
    return Track(
      id: extras?['id'] as int?,
      title: title,
      artist: artist ?? 'Unknown Artist',
      album: album ?? 'Unknown Album',
      duration: duration ?? Duration.zero,
      uri: id,
      artworkUri: artUri?.toString(),
      dateAdded: DateTime.fromMillisecondsSinceEpoch(
        extras?['dateAdded'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      playCount: extras?['playCount'] as int? ?? 0,
      isFavorite: extras?['isFavorite'] as bool? ?? false,
    );
  }
}
