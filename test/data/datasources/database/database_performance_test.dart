import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:basspro_player/data/datasources/database/database_service.dart';
import 'package:basspro_player/domain/entities/track.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Database Performance Tests', () {
    late DatabaseService databaseService;

    setUp(() async {
      databaseService = DatabaseService();
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
    });

    test('Batch insert should be faster than individual inserts for large datasets', () async {
      const trackCount = 1000;
      
      // Generate test tracks
      final tracks = List.generate(trackCount, (i) {
        return Track(
          title: 'Track $i',
          artist: 'Artist ${i % 100}',
          album: 'Album ${i % 50}',
          duration: Duration(minutes: 3, seconds: i % 60),
          uri: 'file:///storage/music/track_$i.mp3',
          dateAdded: DateTime.now().subtract(Duration(days: i)),
          playCount: i % 10,
          isFavorite: i % 5 == 0,
        );
      });

      // Test batch insert
      final batchStartTime = DateTime.now();
      final trackMaps = tracks.map((t) => t.toMap()).toList();
      await databaseService.insertTracksBatch(trackMaps);
      final batchDuration = DateTime.now().difference(batchStartTime);

      print('Batch insert of $trackCount tracks took: ${batchDuration.inMilliseconds}ms');

      // Verify all tracks were inserted
      final allTracks = await databaseService.getAllTracks();
      expect(allTracks.length, trackCount);

      // Batch insert should complete in reasonable time (< 2 seconds for 1000 tracks)
      expect(batchDuration.inMilliseconds, lessThan(2000));
    });

    test('Indexed queries should complete quickly', () async {
      // Insert test data
      const trackCount = 1000;
      final tracks = List.generate(trackCount, (i) {
        return Track(
          title: 'Track $i',
          artist: 'Artist ${i % 100}',
          album: 'Album ${i % 50}',
          duration: Duration(minutes: 3, seconds: i % 60),
          uri: 'file:///storage/music/track_$i.mp3',
          dateAdded: DateTime.now().subtract(Duration(days: i)),
          playCount: i % 100,
          lastPlayedAt: i % 2 == 0 ? DateTime.now().subtract(Duration(hours: i)) : null,
          isFavorite: i % 5 == 0,
        );
      }).map((t) => t.toMap()).toList();

      await databaseService.insertTracksBatch(tracks);

      // Test favorite tracks query (uses is_favorite index)
      final favStartTime = DateTime.now();
      final favorites = await databaseService.getFavoriteTracks();
      final favDuration = DateTime.now().difference(favStartTime);
      
      print('Favorites query took: ${favDuration.inMilliseconds}ms');
      expect(favorites.length, trackCount ~/ 5); // Every 5th track is favorite
      expect(favDuration.inMilliseconds, lessThan(100)); // Should be < 100ms

      // Test recently played query (uses last_played_at index)
      final recentStartTime = DateTime.now();
      final recentlyPlayed = await databaseService.getRecentlyPlayed(20);
      final recentDuration = DateTime.now().difference(recentStartTime);
      
      print('Recently played query took: ${recentDuration.inMilliseconds}ms');
      expect(recentlyPlayed.length, 20);
      expect(recentDuration.inMilliseconds, lessThan(100)); // Should be < 100ms

      // Test most played query (uses play_count index)
      final mostStartTime = DateTime.now();
      final mostPlayed = await databaseService.getMostPlayed(20);
      final mostDuration = DateTime.now().difference(mostStartTime);
      
      print('Most played query took: ${mostDuration.inMilliseconds}ms');
      expect(mostPlayed.length, 20);
      expect(mostDuration.inMilliseconds, lessThan(100)); // Should be < 100ms

      // Test search query (uses title, artist, album indexes)
      final searchStartTime = DateTime.now();
      final searchResults = await databaseService.searchTracks('Track 1');
      final searchDuration = DateTime.now().difference(searchStartTime);
      
      print('Search query took: ${searchDuration.inMilliseconds}ms');
      expect(searchResults.isNotEmpty, true);
      expect(searchDuration.inMilliseconds, lessThan(100)); // Should be < 100ms
    });

    test('Query response time should be under 100ms for typical operations', () async {
      // Insert moderate dataset
      const trackCount = 500;
      final tracks = List.generate(trackCount, (i) {
        return Track(
          title: 'Track $i',
          artist: 'Artist ${i % 50}',
          album: 'Album ${i % 25}',
          duration: Duration(minutes: 3),
          uri: 'file:///storage/music/track_$i.mp3',
          dateAdded: DateTime.now(),
          playCount: i % 50,
          isFavorite: i % 10 == 0,
        );
      }).map((t) => t.toMap()).toList();

      await databaseService.insertTracksBatch(tracks);

      // Test multiple query types
      final queries = <String, Future<List<Map<String, dynamic>>> Function()>{
        'getAllTracks': () => databaseService.getAllTracks(),
        'getFavoriteTracks': () => databaseService.getFavoriteTracks(),
        'getRecentlyPlayed': () => databaseService.getRecentlyPlayed(10),
        'getMostPlayed': () => databaseService.getMostPlayed(10),
        'searchTracks': () => databaseService.searchTracks('Track'),
      };

      for (final entry in queries.entries) {
        final startTime = DateTime.now();
        await entry.value();
        final duration = DateTime.now().difference(startTime);
        
        print('${entry.key} took: ${duration.inMilliseconds}ms');
        expect(
          duration.inMilliseconds,
          lessThan(100),
          reason: '${entry.key} should complete in < 100ms',
        );
      }
    });
  });
}
