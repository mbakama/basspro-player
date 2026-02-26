import '../../repositories/playlist_repository.dart';

/// Use case for removing a track from a playlist.
///
/// This use case encapsulates the business logic for removing tracks
/// from playlists.
///
/// **Validates: Requirements 16.4**
class RemoveTrackFromPlaylistUseCase {
  final PlaylistRepository _repository;

  RemoveTrackFromPlaylistUseCase(this._repository);

  /// Removes a track from a playlist.
  ///
  /// [playlistId] is the ID of the playlist to remove the track from.
  /// [trackId] is the ID of the track to remove.
  Future<void> call(int playlistId, int trackId) async {
    await _repository.removeTrackFromPlaylist(playlistId, trackId);
  }
}
