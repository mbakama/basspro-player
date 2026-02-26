import '../../domain/entities/stream_source.dart';
import '../../domain/repositories/stream_repository.dart';
import '../datasources/database/database_service.dart';

/// Implementation of StreamRepository using DatabaseService.
///
/// This class provides concrete implementations of all stream source-related
/// data operations including CRUD operations, favorites, and playback history.
/// It delegates to the DatabaseService and converts between database maps
/// and StreamSource entities.
class StreamRepositoryImpl implements StreamRepository {
  final DatabaseService _databaseService;

  StreamRepositoryImpl(this._databaseService);

  @override
  Future<int> insertStreamSource(StreamSource source) async {
    final map = source.toMap();
    map.remove('id'); // Remove id for insertion
    return await _databaseService.insertStreamSource(map);
  }

  @override
  Future<StreamSource?> getStreamSource(int id) async {
    final map = await _databaseService.getStreamSource(id);
    return map != null ? StreamSource.fromMap(map) : null;
  }

  @override
  Future<List<StreamSource>> getAllStreamSources() async {
    final maps = await _databaseService.getAllStreamSources();
    return maps.map((map) => StreamSource.fromMap(map)).toList();
  }

  @override
  Future<void> updateStreamSource(StreamSource source) async {
    if (source.id == null) {
      throw ArgumentError('StreamSource must have an id to be updated');
    }
    final map = source.toMap();
    map.remove('id'); // Remove id from update map
    await _databaseService.updateStreamSource(source.id!, map);
  }

  @override
  Future<void> deleteStreamSource(int id) async {
    await _databaseService.deleteStreamSource(id);
  }

  @override
  Future<List<StreamSource>> getFavoriteStreams() async {
    final maps = await _databaseService.getFavoriteStreams();
    return maps.map((map) => StreamSource.fromMap(map)).toList();
  }

  @override
  Future<List<StreamSource>> getRecentlyPlayedStreams(int limit) async {
    final maps = await _databaseService.getRecentlyPlayedStreams(limit);
    return maps.map((map) => StreamSource.fromMap(map)).toList();
  }

  @override
  Future<void> updateLastPlayed(int streamId) async {
    final source = await getStreamSource(streamId);
    if (source == null) {
      throw ArgumentError('StreamSource with id $streamId not found');
    }

    final updatedSource = source.copyWith(
      lastPlayedAt: DateTime.now(),
    );

    await updateStreamSource(updatedSource);
  }

  @override
  Future<void> toggleFavorite(int streamId) async {
    final source = await getStreamSource(streamId);
    if (source == null) {
      throw ArgumentError('StreamSource with id $streamId not found');
    }

    final updatedSource = source.copyWith(
      isFavorite: !source.isFavorite,
    );

    await updateStreamSource(updatedSource);
  }
}
