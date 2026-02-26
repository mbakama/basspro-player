import '../../entities/track.dart';
import '../../repositories/track_repository.dart';

/// Use case for retrieving recently played tracks.
///
/// This use case encapsulates the business logic for fetching tracks
/// ordered by their last played timestamp.
///
/// **Validates: Requirements 4.4**
class GetRecentlyPlayedUseCase {
  final TrackRepository _repository;

  GetRecentlyPlayedUseCase(this._repository);

  /// Retrieves recently played tracks, limited to the specified count.
  ///
  /// [limit] is the maximum number of tracks to return (default: 20).
  /// Returns tracks ordered by lastPlayedAt in descending order (most recent first).
  Future<List<Track>> call([int limit = 20]) async {
    return await _repository.getRecentlyPlayed(limit);
  }
}
