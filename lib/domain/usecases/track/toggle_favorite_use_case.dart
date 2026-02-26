import '../../repositories/track_repository.dart';

/// Use case for toggling the favorite status of a track.
///
/// This use case encapsulates the business logic for marking or unmarking
/// a track as favorite.
///
/// **Validates: Requirements 4.1**
class ToggleFavoriteUseCase {
  final TrackRepository _repository;

  ToggleFavoriteUseCase(this._repository);

  /// Toggles the favorite status of the track with the given ID.
  ///
  /// [trackId] is the ID of the track to toggle.
  /// If the track is currently a favorite, it will be unmarked.
  /// If the track is not a favorite, it will be marked as favorite.
  Future<void> call(int trackId) async {
    await _repository.toggleFavorite(trackId);
  }
}
