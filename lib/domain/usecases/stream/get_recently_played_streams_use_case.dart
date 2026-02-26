import '../../entities/stream_source.dart';
import '../../repositories/stream_repository.dart';

/// Use case for retrieving recently played streams.
///
/// This use case encapsulates the business logic for fetching streams
/// that have been played recently, ordered by last played timestamp.
///
/// **Validates: Requirements 6.6**
class GetRecentlyPlayedStreamsUseCase {
  final StreamRepository _repository;

  GetRecentlyPlayedStreamsUseCase(this._repository);

  /// Retrieves recently played streams, limited to the specified count.
  ///
  /// [limit] is the maximum number of streams to return (default: 10).
  /// Returns a list of streams ordered by lastPlayedAt in descending order.
  ///
  /// Throws [ArgumentError] if the limit is less than or equal to 0.
  Future<List<StreamSource>> call([int limit = 10]) async {
    if (limit <= 0) {
      throw ArgumentError('Limit must be greater than 0');
    }

    return await _repository.getRecentlyPlayedStreams(limit);
  }
}
