import '../../repositories/stream_repository.dart';

/// Use case for deleting a stream source.
///
/// This use case encapsulates the business logic for removing streaming sources
/// from the repository.
///
/// **Validates: Requirements 5.4**
class DeleteStreamSourceUseCase {
  final StreamRepository _repository;

  DeleteStreamSourceUseCase(this._repository);

  /// Deletes a stream source by its ID.
  ///
  /// [streamId] is the ID of the stream source to delete.
  ///
  /// Throws [ArgumentError] if the stream ID is invalid (less than or equal to 0).
  Future<void> call(int streamId) async {
    if (streamId <= 0) {
      throw ArgumentError('Invalid stream ID: $streamId');
    }

    await _repository.deleteStreamSource(streamId);
  }
}
