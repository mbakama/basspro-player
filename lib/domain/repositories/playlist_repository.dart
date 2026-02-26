import '../entities/playlist.dart';
import '../entities/track.dart';

/// Repository interface for Playlist entity operations.
///
/// Defines the contract for data access operations related to playlists,
/// including playlist management and track associations.
abstract class PlaylistRepository {
  /// Inserts a new playlist into the repository.
  ///
  /// Returns the ID of the inserted playlist.
  Future<int> insertPlaylist(Playlist playlist);

  /// Retrieves a playlist by its ID.
  ///
  /// Returns null if no playlist with the given ID exists.
  Future<Playlist?> getPlaylist(int id);

  /// Retrieves all playlists from the repository.
  Future<List<Playlist>> getAllPlaylists();

  /// Updates an existing playlist in the repository.
  Future<void> updatePlaylist(Playlist playlist);

  /// Deletes a playlist by its ID.
  ///
  /// This should cascade delete all associated playlist-track relationships.
  Future<void> deletePlaylist(int id);

  /// Adds a track to a playlist at the specified order index.
  ///
  /// The orderIndex determines the position of the track in the playlist.
  Future<void> addTrackToPlaylist(int playlistId, int trackId, int orderIndex);

  /// Removes a track from a playlist.
  Future<void> removeTrackFromPlaylist(int playlistId, int trackId);

  /// Reorders tracks within a playlist.
  ///
  /// Moves a track from oldIndex to newIndex and updates all affected orderIndex values.
  Future<void> reorderPlaylistTracks(int playlistId, int oldIndex, int newIndex);

  /// Retrieves all tracks in a playlist, ordered by their orderIndex.
  Future<List<Track>> getPlaylistTracks(int playlistId);

  /// Retrieves the count of tracks in a playlist.
  Future<int> getPlaylistTrackCount(int playlistId);
}
