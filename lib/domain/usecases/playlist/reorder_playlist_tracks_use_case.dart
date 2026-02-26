import '../../repositories/playlist_repository.dart';

/// Use case for reordering tracks within a playlist.
///
/// This use case encapsulates the business logic for changing the order
/// of tracks in a playlist.
///
/// **Validates: Requirements 16.3**
class ReorderPlaylistTracksUseCase {
  final PlaylistRepository _repository;

  ReorderPlaylistTracksUseCase(this._repository);

  /// Reorders tracks within a playlist by moving a track from one position to another.
  ///
  /// [playlistId] is the ID of the playlist containing the tracks.
  /// [oldIndex] is the current position of the track to move.
  /// [newIndex] is the target position for the track.
  Future<void> call(int playlistId, int oldIndex, int newIndex) async {
    if (oldIndex < 0 || newIndex < 0) {
      throw ArgumentError('Track indices must be non-negative');
    }

    if (oldIndex == newIndex) {
      return; // No change needed
    }

    await _repository.reorderPlaylistTracks(playlistId, oldIndex, newIndex);
  }
}
