import '../entities/stream_source.dart';

/// Repository interface for StreamSource entity operations.
///
/// Defines the contract for data access operations related to streaming sources,
/// including CRUD operations, favorites, and playback history.
abstract class StreamRepository {
  /// Inserts a new stream source into the repository.
  ///
  /// Returns the ID of the inserted stream source.
  Future<int> insertStreamSource(StreamSource source);

  /// Retrieves a stream source by its ID.
  ///
  /// Returns null if no stream source with the given ID exists.
  Future<StreamSource?> getStreamSource(int id);

  /// Retrieves all stream sources from the repository.
  Future<List<StreamSource>> getAllStreamSources();

  /// Updates an existing stream source in the repository.
  Future<void> updateStreamSource(StreamSource source);

  /// Deletes a stream source by its ID.
  Future<void> deleteStreamSource(int id);

  /// Retrieves all stream sources marked as favorites.
  Future<List<StreamSource>> getFavoriteStreams();

  /// Retrieves recently played streams, limited to the specified count.
  ///
  /// Streams are ordered by lastPlayedAt in descending order.
  Future<List<StreamSource>> getRecentlyPlayedStreams(int limit);

  /// Updates the last played timestamp for a stream source.
  Future<void> updateLastPlayed(int streamId);

  /// Toggles the favorite status of a stream source.
  Future<void> toggleFavorite(int streamId);
}
