import '../../domain/entities/track.dart';
import '../utils/logger.dart';

/// Service for caching frequently accessed database query results.
///
/// This service provides in-memory caching for expensive queries like:
/// - Favorites list
/// - Recently played tracks
/// - Most played tracks
///
/// Cache entries are invalidated when relevant data changes (e.g., favorite toggle,
/// play count update). This improves performance by reducing database queries
/// for frequently accessed data.
class QueryCacheService {
  static QueryCacheService? _instance;
  static const _logger = AppLoggers.cache;

  // Cache storage
  List<Track>? _favoritesCache;
  List<Track>? _recentlyPlayedCache;
  List<Track>? _mostPlayedCache;
  
  // Cache timestamps for TTL
  DateTime? _favoritesCacheTime;
  DateTime? _recentlyPlayedCacheTime;
  DateTime? _mostPlayedCacheTime;
  
  // Cache TTL (time-to-live) in seconds
  static const int _cacheTtlSeconds = 300; // 5 minutes

  QueryCacheService._();

  /// Singleton instance
  factory QueryCacheService() {
    _instance ??= QueryCacheService._();
    return _instance!;
  }

  /// Get cached favorites list
  /// Returns null if cache is empty or expired
  List<Track>? getCachedFavorites() {
    if (_favoritesCache == null || _favoritesCacheTime == null) {
      return null;
    }

    if (_isCacheExpired(_favoritesCacheTime!)) {
      _logger.info('Favorites cache expired');
      _favoritesCache = null;
      _favoritesCacheTime = null;
      return null;
    }

    _logger.info('Returning cached favorites (${_favoritesCache!.length} tracks)');
    return List.unmodifiable(_favoritesCache!);
  }

  /// Cache favorites list
  void cacheFavorites(List<Track> favorites) {
    _favoritesCache = List.from(favorites);
    _favoritesCacheTime = DateTime.now();
    _logger.info('Cached ${favorites.length} favorite tracks');
  }

  /// Invalidate favorites cache
  /// Call this when a track's favorite status changes
  void invalidateFavorites() {
    _favoritesCache = null;
    _favoritesCacheTime = null;
    _logger.info('Invalidated favorites cache');
  }

  /// Get cached recently played list
  /// Returns null if cache is empty or expired
  List<Track>? getCachedRecentlyPlayed() {
    if (_recentlyPlayedCache == null || _recentlyPlayedCacheTime == null) {
      return null;
    }

    if (_isCacheExpired(_recentlyPlayedCacheTime!)) {
      _logger.info('Recently played cache expired');
      _recentlyPlayedCache = null;
      _recentlyPlayedCacheTime = null;
      return null;
    }

    _logger.info('Returning cached recently played (${_recentlyPlayedCache!.length} tracks)');
    return List.unmodifiable(_recentlyPlayedCache!);
  }

  /// Cache recently played list
  void cacheRecentlyPlayed(List<Track> tracks) {
    _recentlyPlayedCache = List.from(tracks);
    _recentlyPlayedCacheTime = DateTime.now();
    _logger.info('Cached ${tracks.length} recently played tracks');
  }

  /// Invalidate recently played cache
  /// Call this when a track is played (play count or last played updated)
  void invalidateRecentlyPlayed() {
    _recentlyPlayedCache = null;
    _recentlyPlayedCacheTime = null;
    _logger.info('Invalidated recently played cache');
  }

  /// Get cached most played list
  /// Returns null if cache is empty or expired
  List<Track>? getCachedMostPlayed() {
    if (_mostPlayedCache == null || _mostPlayedCacheTime == null) {
      return null;
    }

    if (_isCacheExpired(_mostPlayedCacheTime!)) {
      _logger.info('Most played cache expired');
      _mostPlayedCache = null;
      _mostPlayedCacheTime = null;
      return null;
    }

    _logger.info('Returning cached most played (${_mostPlayedCache!.length} tracks)');
    return List.unmodifiable(_mostPlayedCache!);
  }

  /// Cache most played list
  void cacheMostPlayed(List<Track> tracks) {
    _mostPlayedCache = List.from(tracks);
    _mostPlayedCacheTime = DateTime.now();
    _logger.info('Cached ${tracks.length} most played tracks');
  }

  /// Invalidate most played cache
  /// Call this when a track's play count changes
  void invalidateMostPlayed() {
    _mostPlayedCache = null;
    _mostPlayedCacheTime = null;
    _logger.info('Invalidated most played cache');
  }

  /// Invalidate all caches
  /// Call this when performing operations that affect multiple caches
  void invalidateAll() {
    invalidateFavorites();
    invalidateRecentlyPlayed();
    invalidateMostPlayed();
    _logger.info('Invalidated all caches');
  }

  /// Check if a cache entry has expired based on TTL
  bool _isCacheExpired(DateTime cacheTime) {
    final now = DateTime.now();
    final difference = now.difference(cacheTime);
    return difference.inSeconds > _cacheTtlSeconds;
  }

  /// Clear all caches (for testing or manual refresh)
  void clearAll() {
    _favoritesCache = null;
    _recentlyPlayedCache = null;
    _mostPlayedCache = null;
    _favoritesCacheTime = null;
    _recentlyPlayedCacheTime = null;
    _mostPlayedCacheTime = null;
    _logger.info('Cleared all caches');
  }
}
