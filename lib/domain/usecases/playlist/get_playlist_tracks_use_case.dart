import '../../entities/track.dart';
import '../../repositories/playlist_repository.dart';

/// Use case for retrieving tracks from a playlist ordered by index.
///
/// This use case encapsulates the business logic for fetching all tracks
/// in a playlist in their defined order.
///
/// **Validates: Requirements 16.2**
class GetPlaylistTracksUseCase {
  final PlaylistRepository _repository;

  GetPlaylistTracksUseCase(this._repository);

  /// Retrieves all tracks in a playlist, ordered by their orderIndex.
  ///
  /// [playlistId] is the ID of the playlist to retrieve tracks from.
  /// Returns a list of tracks in the order they appear in the playlist.
  Future<List<Track>> call(int playlistId) async {
    return await _repository.getPlaylistTracks(playlistId);
  }
}
