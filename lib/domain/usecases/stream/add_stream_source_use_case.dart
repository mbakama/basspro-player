import '../../entities/stream_source.dart';
import '../../repositories/stream_repository.dart';

/// Use case for adding a new stream source with URL validation.
///
/// This use case encapsulates the business logic for adding streaming sources,
/// including validation of the stream URL and name.
///
/// **Validates: Requirements 5.1**
class AddStreamSourceUseCase {
  final StreamRepository _repository;

  AddStreamSourceUseCase(this._repository);

  /// Adds a new stream source with the given details.
  ///
  /// [name] is the name of the stream source.
  /// [url] is the streaming URL.
  /// [category] is an optional category for organizing streams.
  ///
  /// Throws [ArgumentError] if the name is empty or the URL is invalid.
  /// Returns the ID of the created stream source.
  Future<int> call({
    required String name,
    required String url,
    String? category,
  }) async {
    // Validate stream name
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Stream name cannot be empty');
    }

    // Validate stream URL
    final trimmedUrl = url.trim();
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

    final streamSource = StreamSource(
      name: trimmedName,
      url: trimmedUrl,
      category: category?.trim(),
      createdAt: DateTime.now(),
    );

    return await _repository.insertStreamSource(streamSource);
  }
}
