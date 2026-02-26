import '../entities/track.dart';

/// Repository interface for Track entity operations.
///
/// Defines the contract for data access operations related to tracks,
/// including CRUD operations, search, favorites, and statistics.
abstract class TrackRepository {
  /// Inserts a new track into the repository.
  ///
  /// Returns the ID of the inserted track.
  Future<int> insertTrack(Track track);

  /// Retrieves a track by its ID.
  ///
  /// Returns null if no track with the given ID exists.
  Future<Track?> getTrack(int id);

  /// Retrieves all tracks from the repository.
  Future<List<Track>> getAllTracks();

  /// Updates an existing track in the repository.
  Future<void> updateTrack(Track track);

  /// Deletes a track by its ID.
  Future<void> deleteTrack(int id);

  /// Searches for tracks matching the given query.
  ///
  /// The query is matched against track title, artist, and album fields.
  Future<List<Track>> searchTracks(String query);

  /// Retrieves all tracks marked as favorites.
  Future<List<Track>> getFavoriteTracks();

  /// Retrieves recently played tracks, limited to the specified count.
  ///
  /// Tracks are ordered by lastPlayedAt in descending order.
  Future<List<Track>> getRecentlyPlayed(int limit);

  /// Retrieves most played tracks, limited to the specified count.
  ///
  /// Tracks are ordered by playCount in descending order.
  Future<List<Track>> getMostPlayed(int limit);

  /// Increments the play count for a track and updates its last played timestamp.
  Future<void> incrementPlayCount(int trackId);

  /// Toggles the favorite status of a track.
  Future<void> toggleFavorite(int trackId);
}
