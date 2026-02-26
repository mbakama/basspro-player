import '../../repositories/track_repository.dart';

/// Use case for incrementing a track's play count and updating statistics.
///
/// This use case encapsulates the business logic for updating track
/// playback statistics when a track is played.
///
/// **Validates: Requirements 4.3, 4.5**
class IncrementPlayCountUseCase {
  final TrackRepository _repository;

  IncrementPlayCountUseCase(this._repository);

  /// Increments the play count for the track with the given ID.
  ///
  /// [trackId] is the ID of the track that was played.
  /// This updates both the play count and the last played timestamp.
  Future<void> call(int trackId) async {
    await _repository.incrementPlayCount(trackId);
  }
}
