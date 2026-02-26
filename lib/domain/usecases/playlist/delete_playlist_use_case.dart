import '../../repositories/playlist_repository.dart';

/// Use case for deleting a playlist with cascade delete of track associations.
///
/// This use case encapsulates the business logic for deleting playlists,
/// ensuring that all associated playlist-track relationships are also removed.
///
/// **Validates: Requirements 15.4**
class DeletePlaylistUseCase {
  final PlaylistRepository _repository;

  DeletePlaylistUseCase(this._repository);

  /// Deletes a playlist and all its track associations.
  ///
  /// [playlistId] is the ID of the playlist to delete.
  /// This operation cascades to remove all playlist-track associations.
  Future<void> call(int playlistId) async {
    await _repository.deletePlaylist(playlistId);
  }
}
