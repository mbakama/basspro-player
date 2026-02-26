import '../../core/services/query_cache_service.dart';
import '../../domain/entities/track.dart';
import '../../domain/repositories/track_repository.dart';
import '../datasources/database/database_service.dart';

/// Implementation of TrackRepository using DatabaseService.
///
/// This class provides concrete implementations of all track-related
/// data operations by delegating to the DatabaseService and converting
/// between database maps and Track entities.
///
/// Includes query result caching for frequently accessed queries to improve
/// performance with large music libraries.
class TrackRepositoryImpl implements TrackRepository {
  final DatabaseService _databaseService;
  final QueryCacheService _cacheService;

  TrackRepositoryImpl(
    this._databaseService, {
    QueryCacheService? cacheService,
  }) : _cacheService = cacheService ?? QueryCacheService();

  @override
  Future<int> insertTrack(Track track) async {
    final map = track.toMap();
    map.remove('id'); // Remove id for insertion
    return await _databaseService.insertTrack(map);
  }

  @override
  Future<Track?> getTrack(int id) async {
    final map = await _databaseService.getTrack(id);
    return map != null ? Track.fromMap(map) : null;
  }

  @override
  Future<List<Track>> getAllTracks() async {
    final maps = await _databaseService.getAllTracks();
    return maps.map((map) => Track.fromMap(map)).toList();
  }

  @override
  Future<void> updateTrack(Track track) async {
    if (track.id == null) {
      throw ArgumentError('Track must have an id to be updated');
    }
    final map = track.toMap();
    map.remove('id'); // Remove id from update map
    await _databaseService.updateTrack(track.id!, map);
  }

  @override
  Future<void> deleteTrack(int id) async {
    await _databaseService.deleteTrack(id);
  }

  @override
  Future<List<Track>> searchTracks(String query) async {
    final maps = await _databaseService.searchTracks(query);
    return maps.map((map) => Track.fromMap(map)).toList();
  }

  @override
  Future<List<Track>> getFavoriteTracks() async {
    // Try to get from cache first
    final cached = _cacheService.getCachedFavorites();
    if (cached != null) {
      return cached;
    }

    // Cache miss - query database
    final maps = await _databaseService.getFavoriteTracks();
    final tracks = maps.map((map) => Track.fromMap(map)).toList();
    
    // Cache the result
    _cacheService.cacheFavorites(tracks);
    
    return tracks;
  }

  @override
  Future<List<Track>> getRecentlyPlayed(int limit) async {
    // Try to get from cache first
    final cached = _cacheService.getCachedRecentlyPlayed();
    if (cached != null) {
      // Return only the requested limit from cache
      return cached.take(limit).toList();
    }

    // Cache miss - query database
    final maps = await _databaseService.getRecentlyPlayed(limit);
    final tracks = maps.map((map) => Track.fromMap(map)).toList();
    
    // Cache the result
    _cacheService.cacheRecentlyPlayed(tracks);
    
    return tracks;
  }

  @override
  Future<List<Track>> getMostPlayed(int limit) async {
    // Try to get from cache first
    final cached = _cacheService.getCachedMostPlayed();
    if (cached != null) {
      // Return only the requested limit from cache
      return cached.take(limit).toList();
    }

    // Cache miss - query database
    final maps = await _databaseService.getMostPlayed(limit);
    final tracks = maps.map((map) => Track.fromMap(map)).toList();
    
    // Cache the result
    _cacheService.cacheMostPlayed(tracks);
    
    return tracks;
  }

  @override
  Future<void> incrementPlayCount(int trackId) async {
    final track = await getTrack(trackId);
    if (track == null) {
      throw ArgumentError('Track with id $trackId not found');
    }

    final updatedTrack = track.copyWith(
      playCount: track.playCount + 1,
      lastPlayedAt: DateTime.now(),
    );

    await updateTrack(updatedTrack);
    
    // Invalidate caches that depend on play count and last played
    _cacheService.invalidateRecentlyPlayed();
    _cacheService.invalidateMostPlayed();
  }

  @override
  Future<void> toggleFavorite(int trackId) async {
    final track = await getTrack(trackId);
    if (track == null) {
      throw ArgumentError('Track with id $trackId not found');
    }

    final updatedTrack = track.copyWith(
      isFavorite: !track.isFavorite,
    );

    await updateTrack(updatedTrack);
    
    // Invalidate favorites cache
    _cacheService.invalidateFavorites();
  }
}
