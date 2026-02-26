import 'package:flutter_test/flutter_test.dart';
import 'package:basspro_player/core/services/query_cache_service.dart';
import 'package:basspro_player/domain/entities/track.dart';

void main() {
  group('QueryCacheService', () {
    late QueryCacheService cacheService;

    setUp(() {
      cacheService = QueryCacheService();
      cacheService.clearAll();
    });

    tearDown(() {
      cacheService.clearAll();
    });

    test('should return null for empty cache', () {
      expect(cacheService.getCachedFavorites(), isNull);
      expect(cacheService.getCachedRecentlyPlayed(), isNull);
      expect(cacheService.getCachedMostPlayed(), isNull);
    });

    test('should cache and retrieve favorites', () {
      final tracks = [
        Track(
          id: 1,
          title: 'Track 1',
          artist: 'Artist 1',
          album: 'Album 1',
          duration: Duration(minutes: 3),
          uri: 'file:///track1.mp3',
          dateAdded: DateTime.now(),
          isFavorite: true,
        ),
        Track(
          id: 2,
          title: 'Track 2',
          artist: 'Artist 2',
          album: 'Album 2',
          duration: Duration(minutes: 4),
          uri: 'file:///track2.mp3',
          dateAdded: DateTime.now(),
          isFavorite: true,
        ),
      ];

      cacheService.cacheFavorites(tracks);
      final cached = cacheService.getCachedFavorites();

      expect(cached, isNotNull);
      expect(cached!.length, 2);
      expect(cached[0].id, 1);
      expect(cached[1].id, 2);
    });

    test('should cache and retrieve recently played', () {
      final tracks = [
        Track(
          id: 1,
          title: 'Track 1',
          artist: 'Artist 1',
          album: 'Album 1',
          duration: Duration(minutes: 3),
          uri: 'file:///track1.mp3',
          dateAdded: DateTime.now(),
          lastPlayedAt: DateTime.now(),
        ),
      ];

      cacheService.cacheRecentlyPlayed(tracks);
      final cached = cacheService.getCachedRecentlyPlayed();

      expect(cached, isNotNull);
      expect(cached!.length, 1);
      expect(cached[0].id, 1);
    });

    test('should cache and retrieve most played', () {
      final tracks = [
        Track(
          id: 1,
          title: 'Track 1',
          artist: 'Artist 1',
          album: 'Album 1',
          duration: Duration(minutes: 3),
          uri: 'file:///track1.mp3',
          dateAdded: DateTime.now(),
          playCount: 10,
        ),
      ];

      cacheService.cacheMostPlayed(tracks);
      final cached = cacheService.getCachedMostPlayed();

      expect(cached, isNotNull);
      expect(cached!.length, 1);
      expect(cached[0].playCount, 10);
    });

    test('should invalidate favorites cache', () {
      final tracks = [
        Track(
          id: 1,
          title: 'Track 1',
          artist: 'Artist 1',
          album: 'Album 1',
          duration: Duration(minutes: 3),
          uri: 'file:///track1.mp3',
          dateAdded: DateTime.now(),
          isFavorite: true,
        ),
      ];

      cacheService.cacheFavorites(tracks);
      expect(cacheService.getCachedFavorites(), isNotNull);

      cacheService.invalidateFavorites();
      expect(cacheService.getCachedFavorites(), isNull);
    });

    test('should invalidate recently played cache', () {
      final tracks = [
        Track(
          id: 1,
          title: 'Track 1',
          artist: 'Artist 1',
          album: 'Album 1',
          duration: Duration(minutes: 3),
          uri: 'file:///track1.mp3',
          dateAdded: DateTime.now(),
          lastPlayedAt: DateTime.now(),
        ),
      ];

      cacheService.cacheRecentlyPlayed(tracks);
      expect(cacheService.getCachedRecentlyPlayed(), isNotNull);

      cacheService.invalidateRecentlyPlayed();
      expect(cacheService.getCachedRecentlyPlayed(), isNull);
    });

    test('should invalidate most played cache', () {
      final tracks = [
        Track(
          id: 1,
          title: 'Track 1',
          artist: 'Artist 1',
          album: 'Album 1',
          duration: Duration(minutes: 3),
          uri: 'file:///track1.mp3',
          dateAdded: DateTime.now(),
          playCount: 10,
        ),
      ];

      cacheService.cacheMostPlayed(tracks);
      expect(cacheService.getCachedMostPlayed(), isNotNull);

      cacheService.invalidateMostPlayed();
      expect(cacheService.getCachedMostPlayed(), isNull);
    });

    test('should invalidate all caches', () {
      final tracks = [
        Track(
          id: 1,
          title: 'Track 1',
          artist: 'Artist 1',
          album: 'Album 1',
          duration: Duration(minutes: 3),
          uri: 'file:///track1.mp3',
          dateAdded: DateTime.now(),
          isFavorite: true,
          playCount: 10,
          lastPlayedAt: DateTime.now(),
        ),
      ];

      cacheService.cacheFavorites(tracks);
      cacheService.cacheRecentlyPlayed(tracks);
      cacheService.cacheMostPlayed(tracks);

      expect(cacheService.getCachedFavorites(), isNotNull);
      expect(cacheService.getCachedRecentlyPlayed(), isNotNull);
      expect(cacheService.getCachedMostPlayed(), isNotNull);

      cacheService.invalidateAll();

      expect(cacheService.getCachedFavorites(), isNull);
      expect(cacheService.getCachedRecentlyPlayed(), isNull);
      expect(cacheService.getCachedMostPlayed(), isNull);
    });

    test('cached data should be immutable', () {
      final tracks = [
        Track(
          id: 1,
          title: 'Track 1',
          artist: 'Artist 1',
          album: 'Album 1',
          duration: Duration(minutes: 3),
          uri: 'file:///track1.mp3',
          dateAdded: DateTime.now(),
          isFavorite: true,
        ),
      ];

      cacheService.cacheFavorites(tracks);
      final cached = cacheService.getCachedFavorites();

      // Attempting to modify cached list should not affect the cache
      expect(cached, isNotNull);
      expect(() => cached!.add(tracks[0]), throwsUnsupportedError);
    });
  });
}
