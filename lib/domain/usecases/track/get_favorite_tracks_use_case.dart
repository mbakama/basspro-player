import '../../entities/track.dart';
import '../../repositories/track_repository.dart';

/// Use case for retrieving all favorite tracks.
///
/// This use case encapsulates the business logic for fetching tracks
/// that have been marked as favorites by the user.
///
/// **Validates: Requirements 4.2**
class GetFavoriteTracksUseCase {
  final TrackRepository _repository;

  GetFavoriteTracksUseCase(this._repository);

  /// Retrieves all tracks marked as favorites.
  ///
  /// Returns a list of tracks where isFavorite is true.
  Future<List<Track>> call() async {
    return await _repository.getFavoriteTracks();
  }
}
