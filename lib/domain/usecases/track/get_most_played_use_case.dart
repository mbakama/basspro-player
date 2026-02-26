import '../../entities/track.dart';
import '../../repositories/track_repository.dart';

/// Use case for retrieving most played tracks.
///
/// This use case encapsulates the business logic for fetching tracks
/// ordered by their play count.
///
/// **Validates: Requirements 4.4**
class GetMostPlayedUseCase {
  final TrackRepository _repository;

  GetMostPlayedUseCase(this._repository);

  /// Retrieves most played tracks, limited to the specified count.
  ///
  /// [limit] is the maximum number of tracks to return (default: 20).
  /// Returns tracks ordered by playCount in descending order (most played first).
  Future<List<Track>> call([int limit = 20]) async {
    return await _repository.getMostPlayed(limit);
  }
}
