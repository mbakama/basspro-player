import '../../domain/entities/playlist.dart';
import '../../domain/entities/track.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../datasources/database/database_service.dart';

/// Implementation of PlaylistRepository using DatabaseService.
///
/// This class provides concrete implementations of all playlist-related
/// data operations including playlist management and track associations.
/// It delegates to the DatabaseService and converts between database maps
/// and domain entities.
class PlaylistRepositoryImpl implements PlaylistRepository {
  final DatabaseService _databaseService;

  PlaylistRepositoryImpl(this._databaseService);

  @override
  Future<int> insertPlaylist(Playlist playlist) async {
    final map = playlist.toMap();
    map.remove('id'); // Remove id for insertion
    return await _databaseService.insertPlaylist(map);
  }

  @override
  Future<Playlist?> getPlaylist(int id) async {
    final map = await _databaseService.getPlaylist(id);
    return map != null ? Playlist.fromMap(map) : null;
  }

  @override
  Future<List<Playlist>> getAllPlaylists() async {
    final maps = await _databaseService.getAllPlaylists();
    return maps.map((map) => Playlist.fromMap(map)).toList();
  }

  @override
  Future<void> updatePlaylist(Playlist playlist) async {
    if (playlist.id == null) {
      throw ArgumentError('Playlist must have an id to be updated');
    }
    final map = playlist.toMap();
    map.remove('id'); // Remove id from update map
    await _databaseService.updatePlaylist(playlist.id!, map);
  }

  @override
  Future<void> deletePlaylist(int id) async {
    await _databaseService.deletePlaylist(id);
  }

  @override
  Future<void> addTrackToPlaylist(
    int playlistId,
    int trackId,
    int orderIndex,
  ) async {
    await _databaseService.addTrackToPlaylist(playlistId, trackId, orderIndex);
  }

  @override
  Future<void> removeTrackFromPlaylist(int playlistId, int trackId) async {
    await _databaseService.removeTrackFromPlaylist(playlistId, trackId);
  }

  @override
  Future<void> reorderPlaylistTracks(
    int playlistId,
    int oldIndex,
    int newIndex,
  ) async {
    await _databaseService.reorderPlaylistTracks(
      playlistId,
      oldIndex,
      newIndex,
    );
  }

  @override
  Future<List<Track>> getPlaylistTracks(int playlistId) async {
    final maps = await _databaseService.getPlaylistTracks(playlistId);
    return maps.map((map) => Track.fromMap(map)).toList();
  }

  @override
  Future<int> getPlaylistTrackCount(int playlistId) async {
    final tracks = await getPlaylistTracks(playlistId);
    return tracks.length;
  }
}
