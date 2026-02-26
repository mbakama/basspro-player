import '../../entities/track.dart';
import '../../repositories/track_repository.dart';

/// Use case for searching tracks across title, artist, and album fields.
///
/// This use case encapsulates the business logic for searching tracks
/// using a query string that matches against multiple fields.
///
/// **Validates: Requirements 3.3**
class SearchTracksUseCase {
  final TrackRepository _repository;

  SearchTracksUseCase(this._repository);

  /// Searches for tracks matching the query across title, artist, and album.
  ///
  /// [query] is the search string to match against track metadata.
  /// Returns a list of tracks where the query matches title, artist, or album.
  /// Returns all tracks if query is empty.
  Future<List<Track>> call(String query) async {
    if (query.trim().isEmpty) {
      return await _repository.getAllTracks();
    }
    
    return await _repository.searchTracks(query);
  }
}
