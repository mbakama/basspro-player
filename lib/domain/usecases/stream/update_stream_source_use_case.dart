import '../../entities/stream_source.dart';
import '../../repositories/stream_repository.dart';

/// Use case for updating an existing stream source with validation.
///
/// This use case encapsulates the business logic for updating streaming sources,
/// including validation of the stream URL and name.
///
/// **Validates: Requirements 5.3**
class UpdateStreamSourceUseCase {
  final StreamRepository _repository;

  UpdateStreamSourceUseCase(this._repository);

  /// Updates an existing stream source with the given details.
  ///
  /// [streamSource] is the stream source to update with new values.
  ///
  /// Throws [ArgumentError] if the name is empty or the URL is invalid.
  /// Throws [StateError] if the stream source doesn't have an ID.
  Future<void> call(StreamSource streamSource) async {
    // Ensure the stream source has an ID
    if (streamSource.id == null) {
      throw StateError('Cannot update stream source without an ID');
    }

    // Validate stream name
    final trimmedName = streamSource.name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Stream name cannot be empty');
    }

    // Validate stream URL
    final trimmedUrl = streamSource.url.trim();
    if (trimmedUrl.isEmpty) {
      throw ArgumentError('Stream URL cannot be empty');
    }

    // Basic URL validation - must start with http:// or https://
    if (!trimmedUrl.startsWith('http://') && !trimmedUrl.startsWith('https://')) {
      throw ArgumentError('Stream URL must start with http:// or https://');
    }

    // Validate URL format
    try {
      Uri.parse(trimmedUrl);
    } catch (e) {
      throw ArgumentError('Invalid stream URL format');
    }

    // Create updated stream source with trimmed values
    final updatedSource = streamSource.copyWith(
      name: trimmedName,
      url: trimmedUrl,
      category: streamSource.category?.trim(),
    );

    await _repository.updateStreamSource(updatedSource);
  }
}
