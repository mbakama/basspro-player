import '../../entities/track.dart';
import '../../repositories/track_repository.dart';

/// Sorting options for track lists.
enum TrackSortOption {
  title,
  artist,
  album,
  dateAdded,
  duration,
}

/// Use case for retrieving all tracks with optional sorting.
///
/// This use case encapsulates the business logic for fetching all tracks
/// from the repository and applying the specified sort order.
///
/// **Validates: Requirements 3.4**
class GetAllTracksUseCase {
  final TrackRepository _repository;

  GetAllTracksUseCase(this._repository);

  /// Retrieves all tracks sorted according to the specified option.
  ///
  /// [sortOption] determines the field and order for sorting.
  /// Returns a list of tracks sorted by the specified criterion.
  Future<List<Track>> call([TrackSortOption sortOption = TrackSortOption.title]) async {
    final tracks = await _repository.getAllTracks();
    
    // Sort tracks based on the specified option
    switch (sortOption) {
      case TrackSortOption.title:
        tracks.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case TrackSortOption.artist:
        tracks.sort((a, b) {
          final artistCompare = a.artist.toLowerCase().compareTo(b.artist.toLowerCase());
          if (artistCompare != 0) return artistCompare;
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });
        break;
      case TrackSortOption.album:
        tracks.sort((a, b) {
          final albumCompare = a.album.toLowerCase().compareTo(b.album.toLowerCase());
          if (albumCompare != 0) return albumCompare;
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });
        break;
      case TrackSortOption.dateAdded:
        tracks.sort((a, b) => b.dateAdded.compareTo(a.dateAdded)); // Newest first
        break;
      case TrackSortOption.duration:
        tracks.sort((a, b) => a.duration.compareTo(b.duration));
        break;
    }
    
    return tracks;
  }
}
