import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:basspro_player/data/datasources/database/database_service.dart';
import 'package:basspro_player/data/repositories/track_repository_impl.dart';
import 'package:basspro_player/core/services/query_cache_service.dart';
import 'package:basspro_player/domain/entities/track.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TrackRepository with Query Cache', () {
    late DatabaseService databaseService;
    late QueryCacheService cacheService;
    late TrackRepositoryImpl repository;

    setUp(() async {
      databaseService = DatabaseService();
      cacheService = QueryCacheService();
      cacheService.clearAll();
      repository = TrackRepositoryImpl(databaseService, cacheService: cacheService);
      
      // Ensure clean state
      try {
        await databaseService.deleteDatabase();
      } catch (_) {}
    });

    tearDown(() async {
      await databaseService.close();
      try {
        await databaseService.deleteDatabase();
      } catch (_) {}
      cacheService.clearAll();
    });

    test('getFavoriteTracks should use cache on second call', () async {
      // Insert test tracks
      final track1 = Track(
        title: 'Favorite 1',
        artist: 'Artist 1',
        album: 'Album 1',
        duration: Duration(minutes: 3),
        uri: 'file:///track1.mp3',
        dateAdded: DateTime.now(),
        isFavorite: true,
      );
      final track2 = Track(
        title: 'Favorite 2',
        artist: 'Artist 2',
        album: 'Album 2',
        duration: Duration(minutes: 4),
        uri: 'file:///track2.mp3',
        dateAdded: DateTime.now(),
        isFavorite: true,
      );

      await repository.insertTrack(track1);
      await repository.insertTrack(track2);

      // First call - should query database and cache result
      final firstCall = await repository.getFavoriteTracks();
      expect(firstCall.length, 2);

      // Verify cache is populated
      final cached = cacheService.getCachedFavorites();
      expect(cached, isNotNull);
      expect(cached!.length, 2);

      // Second call - should use cache
      final secondCall = await repository.getFavoriteTracks();
      expect(secondCall.length, 2);
      expect(secondCall[0].title, firstCall[0].title);
    });

    test('toggleFavorite should invalidate favorites cache', () async {
      // Insert test track
      final track = Track(
        title: 'Track 1',
        artist: 'Artist 1',
        album: 'Album 1',
        duration: Duration(minutes: 3),
        uri: 'file:///track1.mp3',
        dateAdded: DateTime.now(),
        isFavorite: true,
      );

      final trackId = await repository.insertTrack(track);

      // Get favorites - should cache result
      final favorites = await repository.getFavoriteTracks();
      expect(favorites.length, 1);
      expect(cacheService.getCachedFavorites(), isNotNull);

      // Toggle favorite - should invalidate cache
      await repository.toggleFavorite(trackId);
      expect(cacheService.getCachedFavorites(), isNull);

      // Get favorites again - should query database
      final updatedFavorites = await repository.getFavoriteTracks();
      expect(updatedFavorites.length, 0);
    });

    test('incrementPlayCount should invalidate recently played and most played caches', () async {
      // Insert test track
      final track = Track(
        title: 'Track 1',
        artist: 'Artist 1',
        album: 'Album 1',
        duration: Duration(minutes: 3),
        uri: 'file:///track1.mp3',
        dateAdded: DateTime.now(),
        playCount: 5,
        lastPlayedAt: DateTime.now(),
      );

      final trackId = await repository.insertTrack(track);

      // Get recently played and most played - should cache results
      await repository.getRecentlyPlayed(10);
      await repository.getMostPlayed(10);
      expect(cacheService.getCachedRecentlyPlayed(), isNotNull);
      expect(cacheService.getCachedMostPlayed(), isNotNull);

      // Increment play count - should invalidate both caches
      await repository.incrementPlayCount(trackId);
      expect(cacheService.getCachedRecentlyPlayed(), isNull);
      expect(cacheService.getCachedMostPlayed(), isNull);
    });

    test('cache should improve query performance on repeated calls', () async {
      // Insert multiple favorite tracks
      final tracks = List.generate(100, (i) {
        return Track(
          title: 'Track $i',
          artist: 'Artist $i',
          album: 'Album $i',
          duration: Duration(minutes: 3),
          uri: 'file:///track$i.mp3',
          dateAdded: DateTime.now(),
          isFavorite: true,
        );
      });

      for (final track in tracks) {
        await repository.insertTrack(track);
      }

      // First call - queries database
      final firstStart = DateTime.now();
      await repository.getFavoriteTracks();
      final firstDuration = DateTime.now().difference(firstStart);

      // Second call - uses cache (should be faster or similar)
      final secondStart = DateTime.now();
      await repository.getFavoriteTracks();
      final secondDuration = DateTime.now().difference(secondStart);

      print('First call (database): ${firstDuration.inMicroseconds}μs');
      print('Second call (cache): ${secondDuration.inMicroseconds}μs');

      // Both should be fast, but cache should not be slower
      expect(secondDuration.inMilliseconds, lessThanOrEqualTo(firstDuration.inMilliseconds + 5));
    });

    test('getRecentlyPlayed should respect limit parameter with cache', () async {
      // Insert tracks with different last played times
      for (int i = 0; i < 50; i++) {
        final track = Track(
          title: 'Track $i',
          artist: 'Artist $i',
          album: 'Album $i',
          duration: Duration(minutes: 3),
          uri: 'file:///track$i.mp3',
          dateAdded: DateTime.now(),
          lastPlayedAt: DateTime.now().subtract(Duration(hours: i)),
        );
        await repository.insertTrack(track);
      }

      // First call with limit 10
      final first10 = await repository.getRecentlyPlayed(10);
      expect(first10.length, 10);

      // Second call with limit 5 - should use cache and return 5
      final first5 = await repository.getRecentlyPlayed(5);
      expect(first5.length, 5);

      // Verify the 5 tracks are the most recent from the cached 10
      expect(first5[0].title, first10[0].title);
    });
  });
}
