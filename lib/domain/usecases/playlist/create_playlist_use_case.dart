import '../../entities/playlist.dart';
import '../../repositories/playlist_repository.dart';

/// Use case for creating a new playlist with name validation.
///
/// This use case encapsulates the business logic for creating playlists,
/// including validation of the playlist name.
///
/// **Validates: Requirements 15.1**
class CreatePlaylistUseCase {
  final PlaylistRepository _repository;

  CreatePlaylistUseCase(this._repository);

  /// Creates a new playlist with the given name.
  ///
  /// [name] is the name of the playlist to create.
  /// Throws [ArgumentError] if the name is empty or contains only whitespace.
  /// Returns the ID of the created playlist.
  Future<int> call(String name) async {
    // Validate playlist name
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Playlist name cannot be empty');
    }

    final playlist = Playlist(
      name: trimmedName,
      createdAt: DateTime.now(),
    );

    return await _repository.insertPlaylist(playlist);
  }
}
