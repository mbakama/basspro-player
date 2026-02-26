import '../../repositories/playlist_repository.dart';

/// Use case for adding a track to a playlist with order index management.
///
/// This use case encapsulates the business logic for adding tracks to playlists,
/// including automatic order index calculation.
///
/// **Validates: Requirements 16.1**
class AddTrackToPlaylistUseCase {
  final PlaylistRepository _repository;

  AddTrackToPlaylistUseCase(this._repository);

  /// Adds a track to a playlist at the specified order index.
  ///
  /// [playlistId] is the ID of the playlist to add the track to.
  /// [trackId] is the ID of the track to add.
  /// [orderIndex] is the position where the track should be inserted.
  /// If not specified, the track is added at the end of the playlist.
  Future<void> call(int playlistId, int trackId, {int? orderIndex}) async {
    // If no order index specified, add at the end
    final int finalOrderIndex;
    if (orderIndex == null) {
      final trackCount = await _repository.getPlaylistTrackCount(playlistId);
      finalOrderIndex = trackCount;
    } else {
      finalOrderIndex = orderIndex;
    }

    await _repository.addTrackToPlaylist(playlistId, trackId, finalOrderIndex);
  }
}
