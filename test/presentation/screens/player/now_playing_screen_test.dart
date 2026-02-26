import 'package:flutter_test/flutter_test.dart';
import 'package:basspro_player/domain/entities/track.dart';
import 'package:basspro_player/domain/repositories/track_repository.dart';
import 'package:basspro_player/data/repositories/track_repository_impl.dart';
import 'package:basspro_player/data/datasources/database/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize sqflite_ffi for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Now Playing Screen - Favorite and Queue Actions', () {
    late TrackRepository repository;
    late DatabaseService databaseService;

    setUp(() async {
      // Create a fresh database for each test
      databaseService = DatabaseService();
      repository = TrackRepositoryImpl(databaseService);
    });

    tearDown(() async {
      // Clean up database after each test
      await databaseService.close();
      await databaseService.deleteDatabase();
    });

    test('Toggle favorite should update track favorite status', () async {
      // Arrange: Create a test track
      final track = Track(
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: const Duration(minutes: 3, seconds: 30),
        uri: 'file:///test/song.mp3',
        dateAdded: DateTime.now(),
        isFavorite: false,
      );

      // Insert track into database
      final trackId = await repository.insertTrack(track);
      final insertedTrack = await repository.getTrack(trackId);
      expect(insertedTrack, isNotNull);
      expect(insertedTrack!.isFavorite, false);

      // Act: Toggle favorite
      await repository.toggleFavorite(trackId);

      // Assert: Verify favorite status changed
      final updatedTrack = await repository.getTrack(trackId);
      expect(updatedTrack, isNotNull);
      expect(updatedTrack!.isFavorite, true);

      // Act: Toggle favorite again
      await repository.toggleFavorite(trackId);

      // Assert: Verify favorite status changed back
      final revertedTrack = await repository.getTrack(trackId);
      expect(revertedTrack, isNotNull);
      expect(revertedTrack!.isFavorite, false);
    });

    test('Get track by URI should find correct track', () async {
      // Arrange: Create multiple test tracks
      final track1 = Track(
        title: 'Song 1',
        artist: 'Artist 1',
        album: 'Album 1',
        duration: const Duration(minutes: 3),
        uri: 'file:///test/song1.mp3',
        dateAdded: DateTime.now(),
      );

      final track2 = Track(
        title: 'Song 2',
        artist: 'Artist 2',
        album: 'Album 2',
        duration: const Duration(minutes: 4),
        uri: 'file:///test/song2.mp3',
        dateAdded: DateTime.now(),
      );

      // Insert tracks
      await repository.insertTrack(track1);
      await repository.insertTrack(track2);

      // Act: Get all tracks and find by URI
      final allTracks = await repository.getAllTracks();
      final foundTrack = allTracks.where((t) => t.uri == track2.uri).firstOrNull;

      // Assert: Verify correct track was found
      expect(foundTrack, isNotNull);
      expect(foundTrack!.title, 'Song 2');
      expect(foundTrack.artist, 'Artist 2');
      expect(foundTrack.uri, 'file:///test/song2.mp3');
    });

    test('Favorite tracks should be retrievable', () async {
      // Arrange: Create tracks with different favorite status
      final track1 = Track(
        title: 'Favorite Song',
        artist: 'Artist 1',
        album: 'Album 1',
        duration: const Duration(minutes: 3),
        uri: 'file:///test/fav.mp3',
        dateAdded: DateTime.now(),
        isFavorite: true,
      );

      final track2 = Track(
        title: 'Regular Song',
        artist: 'Artist 2',
        album: 'Album 2',
        duration: const Duration(minutes: 4),
        uri: 'file:///test/regular.mp3',
        dateAdded: DateTime.now(),
        isFavorite: false,
      );

      // Insert tracks
      await repository.insertTrack(track1);
      await repository.insertTrack(track2);

      // Act: Get favorite tracks
      final favorites = await repository.getFavoriteTracks();

      // Assert: Verify only favorite track is returned
      expect(favorites.length, 1);
      expect(favorites.first.title, 'Favorite Song');
      expect(favorites.first.isFavorite, true);
    });
  });
}
