import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';
import '../../../core/errors/app_error.dart';

/// Database service for managing local data persistence using SQLite
/// 
/// Handles all database operations including:
/// - Database initialization and schema creation
/// - CRUD operations for all entity types
/// - Query optimization with indexes
/// - Transaction management
class DatabaseService {
  static DatabaseService? _instance;
  static Database? _database;
  static const _logger = AppLoggers.database;

  DatabaseService._();

  /// Singleton instance
  factory DatabaseService() {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  /// Get database instance, initializing if necessary
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database with schema
  Future<Database> _initDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, AppConstants.dbName);

      _logger.info('Initializing database at: $path');

      return await openDatabase(
        path,
        version: AppConstants.dbVersion,
        onCreate: _onCreate,
        onConfigure: _onConfigure,
      );
    } catch (e) {
      _logger.error('Failed to initialize database', e);
      rethrow;
    }
  }

  /// Configure database settings
  Future<void> _onConfigure(Database db) async {
    // Enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Handle database errors and convert to AppError
  T _handleDatabaseError<T>(
    String operation,
    String entity,
    Object error,
    StackTrace stackTrace,
  ) {
    _logger.error('Database error during $operation for $entity', error, stackTrace);
    
    // Check for specific error types
    if (error is DatabaseException) {
      if (error.isUniqueConstraintError()) {
        throw DatabaseError(
          message: '$entity existe déjà',
          details: 'Un élément avec ces informations existe déjà',
          stackTrace: stackTrace,
        );
      } else if (error.isNoSuchTableError()) {
        throw DatabaseError.corruption('Table $entity introuvable');
      } else if (error.isSyntaxError()) {
        throw DatabaseError.queryFailed('Erreur de syntaxe SQL');
      }
    }
    
    // Generic database error based on operation
    switch (operation) {
      case 'insert':
        throw DatabaseError.insertFailed(entity, error.toString());
      case 'update':
        throw DatabaseError.updateFailed(entity, error.toString());
      case 'delete':
        throw DatabaseError.deleteFailed(entity, error.toString());
      case 'query':
        throw DatabaseError.queryFailed(error.toString());
      default:
        throw DatabaseError(
          message: 'Erreur de base de données',
          details: error.toString(),
          stackTrace: stackTrace,
        );
    }
  }

  /// Create database schema
  Future<void> _onCreate(Database db, int version) async {
    try {
      _logger.info('Creating database schema version $version');

      // Create tracks table
      await db.execute('''
        CREATE TABLE tracks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          artist TEXT NOT NULL,
          album TEXT NOT NULL,
          duration INTEGER NOT NULL,
          uri TEXT NOT NULL UNIQUE,
          artwork_uri TEXT,
          date_added INTEGER NOT NULL,
          play_count INTEGER DEFAULT 0,
          last_played_at INTEGER,
          is_favorite INTEGER DEFAULT 0
        )
      ''');

      // Create indexes for tracks table
      await db.execute(
        'CREATE INDEX idx_tracks_artist ON tracks(artist)',
      );
      await db.execute(
        'CREATE INDEX idx_tracks_album ON tracks(album)',
      );
      await db.execute(
        'CREATE INDEX idx_tracks_title ON tracks(title)',
      );
      await db.execute(
        'CREATE INDEX idx_tracks_play_count ON tracks(play_count DESC)',
      );
      await db.execute(
        'CREATE INDEX idx_tracks_last_played ON tracks(last_played_at DESC)',
      );
      await db.execute(
        'CREATE INDEX idx_tracks_is_favorite ON tracks(is_favorite)',
      );
      await db.execute(
        'CREATE INDEX idx_tracks_date_added ON tracks(date_added DESC)',
      );

      _logger.info('Created tracks table with indexes');

      // Create playlists table
      await db.execute('''
        CREATE TABLE playlists (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');

      // Create index for playlists
      await db.execute(
        'CREATE INDEX idx_playlists_name ON playlists(name)',
      );

      _logger.info('Created playlists table with indexes');

      // Create playlist_tracks junction table
      await db.execute('''
        CREATE TABLE playlist_tracks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          playlist_id INTEGER NOT NULL,
          track_id INTEGER NOT NULL,
          order_index INTEGER NOT NULL,
          FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE,
          FOREIGN KEY (track_id) REFERENCES tracks(id) ON DELETE CASCADE,
          UNIQUE(playlist_id, track_id)
        )
      ''');

      // Create index for playlist_tracks
      await db.execute(
        'CREATE INDEX idx_playlist_tracks_playlist ON playlist_tracks(playlist_id, order_index)',
      );

      _logger.info('Created playlist_tracks table with indexes');

      // Create stream_sources table
      await db.execute('''
        CREATE TABLE stream_sources (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          url TEXT NOT NULL,
          category TEXT,
          is_favorite INTEGER DEFAULT 0,
          created_at INTEGER NOT NULL,
          last_played_at INTEGER
        )
      ''');

      // Create index for stream_sources
      await db.execute(
        'CREATE INDEX idx_stream_sources_last_played ON stream_sources(last_played_at DESC)',
      );
      await db.execute(
        'CREATE INDEX idx_stream_sources_is_favorite ON stream_sources(is_favorite)',
      );

      _logger.info('Created stream_sources table with indexes');

      // Create eq_presets table
      await db.execute('''
        CREATE TABLE eq_presets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          bands_json TEXT NOT NULL,
          preamp REAL NOT NULL,
          sub_bass REAL NOT NULL,
          bass REAL NOT NULL,
          virtualizer REAL DEFAULT 0,
          limiter_enabled INTEGER DEFAULT 1,
          created_at INTEGER NOT NULL,
          is_builtin INTEGER DEFAULT 0
        )
      ''');

      _logger.info('Created eq_presets table');

      // Create settings table
      await db.execute('''
        CREATE TABLE settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');

      _logger.info('Created settings table');

      _logger.info('Database schema created successfully');
    } catch (e) {
      _logger.error('Failed to create database schema', e);
      rethrow;
    }
  }

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _logger.info('Database connection closed');
    }
  }

  /// Delete database (for testing purposes)
  Future<void> deleteDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, AppConstants.dbName);
      await databaseFactory.deleteDatabase(path);
      _database = null;
      _logger.info('Database deleted');
    } catch (e) {
      _logger.error('Failed to delete database', e);
      rethrow;
    }
  }

  // ============================================================================
  // Track CRUD Operations
  // ============================================================================

  /// Insert a new track into the database
  /// Returns the ID of the inserted track
  Future<int> insertTrack(Map<String, dynamic> track) async {
    try {
      final db = await database;
      final id = await db.insert(
        'tracks',
        track,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _logger.info('Inserted track with ID: $id');
      return id;
    } catch (e, stackTrace) {
      return _handleDatabaseError('insert', 'piste', e, stackTrace);
    }
  }

  /// Insert multiple tracks in a single transaction for better performance
  /// Returns the number of tracks successfully inserted
  Future<int> insertTracksBatch(List<Map<String, dynamic>> tracks) async {
    if (tracks.isEmpty) return 0;

    try {
      final db = await database;
      int insertedCount = 0;

      await db.transaction((txn) async {
        final batch = txn.batch();
        
        for (final track in tracks) {
          batch.insert(
            'tracks',
            track,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        
        final results = await batch.commit(noResult: false);
        insertedCount = results.length;
      });

      _logger.info('Batch inserted $insertedCount tracks');
      return insertedCount;
    } catch (e) {
      _logger.error('Failed to batch insert tracks', e);
      rethrow;
    }
  }

  /// Get a track by ID
  /// Returns null if track not found
  Future<Map<String, dynamic>?> getTrack(int id) async {
    try {
      final db = await database;
      final results = await db.query(
        'tracks',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      _logger.error('Failed to get track with ID: $id', e);
      rethrow;
    }
  }

  /// Get all tracks from the database
  /// Returns list of tracks ordered by title
  Future<List<Map<String, dynamic>>> getAllTracks() async {
    try {
      final db = await database;
      final results = await db.query(
        'tracks',
        orderBy: 'title ASC',
      );
      _logger.info('Retrieved ${results.length} tracks');
      return results;
    } catch (e) {
      _logger.error('Failed to get all tracks', e);
      rethrow;
    }
  }

  /// Update an existing track
  /// Returns the number of rows affected
  Future<int> updateTrack(int id, Map<String, dynamic> track) async {
    try {
      final db = await database;
      final count = await db.update(
        'tracks',
        track,
        where: 'id = ?',
        whereArgs: [id],
      );
      _logger.info('Updated track with ID: $id');
      return count;
    } catch (e) {
      _logger.error('Failed to update track with ID: $id', e);
      rethrow;
    }
  }

  /// Delete a track by ID
  /// Returns the number of rows affected
  Future<int> deleteTrack(int id) async {
    try {
      final db = await database;
      final count = await db.delete(
        'tracks',
        where: 'id = ?',
        whereArgs: [id],
      );
      _logger.info('Deleted track with ID: $id');
      return count;
    } catch (e) {
      _logger.error('Failed to delete track with ID: $id', e);
      rethrow;
    }
  }

  /// Search tracks by query across title, artist, and album
  /// Returns list of matching tracks
  Future<List<Map<String, dynamic>>> searchTracks(String query) async {
    try {
      final db = await database;
      final searchPattern = '%$query%';
      final results = await db.query(
        'tracks',
        where: 'title LIKE ? OR artist LIKE ? OR album LIKE ?',
        whereArgs: [searchPattern, searchPattern, searchPattern],
        orderBy: 'title ASC',
      );
      _logger.info('Found ${results.length} tracks matching query: $query');
      return results;
    } catch (e) {
      _logger.error('Failed to search tracks with query: $query', e);
      rethrow;
    }
  }

  /// Get all favorite tracks
  /// Returns list of tracks where is_favorite = 1
  Future<List<Map<String, dynamic>>> getFavoriteTracks() async {
    try {
      final db = await database;
      final results = await db.query(
        'tracks',
        where: 'is_favorite = ?',
        whereArgs: [1],
        orderBy: 'title ASC',
      );
      _logger.info('Retrieved ${results.length} favorite tracks');
      return results;
    } catch (e) {
      _logger.error('Failed to get favorite tracks', e);
      rethrow;
    }
  }

  /// Get recently played tracks
  /// Returns list of tracks ordered by last_played_at descending
  Future<List<Map<String, dynamic>>> getRecentlyPlayed(int limit) async {
    try {
      final db = await database;
      final results = await db.query(
        'tracks',
        where: 'last_played_at IS NOT NULL',
        orderBy: 'last_played_at DESC',
        limit: limit,
      );
      _logger.info('Retrieved ${results.length} recently played tracks');
      return results;
    } catch (e) {
      _logger.error('Failed to get recently played tracks', e);
      rethrow;
    }
  }

  /// Get most played tracks
  /// Returns list of tracks ordered by play_count descending
  Future<List<Map<String, dynamic>>> getMostPlayed(int limit) async {
    try {
      final db = await database;
      final results = await db.query(
        'tracks',
        where: 'play_count > ?',
        whereArgs: [0],
        orderBy: 'play_count DESC',
        limit: limit,
      );
      _logger.info('Retrieved ${results.length} most played tracks');
      return results;
    } catch (e) {
      _logger.error('Failed to get most played tracks', e);
      rethrow;
    }
  }

  // ============================================================================
  // Playlist CRUD Operations
  // ============================================================================

  /// Insert a new playlist into the database
  /// Returns the ID of the inserted playlist
  Future<int> insertPlaylist(Map<String, dynamic> playlist) async {
    try {
      final db = await database;
      final id = await db.insert(
        'playlists',
        playlist,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _logger.info('Inserted playlist with ID: $id');
      return id;
    } catch (e) {
      _logger.error('Failed to insert playlist', e);
      rethrow;
    }
  }

  /// Get a playlist by ID
  /// Returns null if playlist not found
  Future<Map<String, dynamic>?> getPlaylist(int id) async {
    try {
      final db = await database;
      final results = await db.query(
        'playlists',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      _logger.error('Failed to get playlist with ID: $id', e);
      rethrow;
    }
  }

  /// Get all playlists from the database
  /// Returns list of playlists ordered by name
  Future<List<Map<String, dynamic>>> getAllPlaylists() async {
    try {
      final db = await database;
      final results = await db.query(
        'playlists',
        orderBy: 'name ASC',
      );
      _logger.info('Retrieved ${results.length} playlists');
      return results;
    } catch (e) {
      _logger.error('Failed to get all playlists', e);
      rethrow;
    }
  }

  /// Update an existing playlist
  /// Returns the number of rows affected
  Future<int> updatePlaylist(int id, Map<String, dynamic> playlist) async {
    try {
      final db = await database;
      final count = await db.update(
        'playlists',
        playlist,
        where: 'id = ?',
        whereArgs: [id],
      );
      _logger.info('Updated playlist with ID: $id');
      return count;
    } catch (e) {
      _logger.error('Failed to update playlist with ID: $id', e);
      rethrow;
    }
  }

  /// Delete a playlist by ID
  /// Also deletes all associated playlist_tracks entries (CASCADE)
  /// Returns the number of rows affected
  Future<int> deletePlaylist(int id) async {
    try {
      final db = await database;
      final count = await db.delete(
        'playlists',
        where: 'id = ?',
        whereArgs: [id],
      );
      _logger.info('Deleted playlist with ID: $id');
      return count;
    } catch (e) {
      _logger.error('Failed to delete playlist with ID: $id', e);
      rethrow;
    }
  }

  /// Add a track to a playlist with specified order index
  /// Returns the ID of the inserted playlist_track entry
  Future<int> addTrackToPlaylist(
    int playlistId,
    int trackId,
    int orderIndex,
  ) async {
    try {
      final db = await database;
      final id = await db.insert(
        'playlist_tracks',
        {
          'playlist_id': playlistId,
          'track_id': trackId,
          'order_index': orderIndex,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _logger.info(
        'Added track $trackId to playlist $playlistId at index $orderIndex',
      );
      return id;
    } catch (e) {
      _logger.error(
        'Failed to add track $trackId to playlist $playlistId',
        e,
      );
      rethrow;
    }
  }

  /// Remove a track from a playlist
  /// Returns the number of rows affected
  Future<int> removeTrackFromPlaylist(int playlistId, int trackId) async {
    try {
      final db = await database;
      final count = await db.delete(
        'playlist_tracks',
        where: 'playlist_id = ? AND track_id = ?',
        whereArgs: [playlistId, trackId],
      );
      _logger.info('Removed track $trackId from playlist $playlistId');
      return count;
    } catch (e) {
      _logger.error(
        'Failed to remove track $trackId from playlist $playlistId',
        e,
      );
      rethrow;
    }
  }

  /// Reorder tracks in a playlist
  /// Updates order_index for tracks from oldIndex to newIndex
  Future<void> reorderPlaylistTracks(
    int playlistId,
    int oldIndex,
    int newIndex,
  ) async {
    try {
      final db = await database;

      await db.transaction((txn) async {
        // Get all tracks in the playlist ordered by order_index
        final tracks = await txn.query(
          'playlist_tracks',
          where: 'playlist_id = ?',
          whereArgs: [playlistId],
          orderBy: 'order_index ASC',
        );

        if (oldIndex < 0 ||
            oldIndex >= tracks.length ||
            newIndex < 0 ||
            newIndex >= tracks.length) {
          throw ArgumentError('Invalid index for reordering');
        }

        // Remove the track from old position
        final movedTrack = tracks.removeAt(oldIndex);

        // Insert at new position
        tracks.insert(newIndex, movedTrack);

        // Update all order_index values
        for (int i = 0; i < tracks.length; i++) {
          await txn.update(
            'playlist_tracks',
            {'order_index': i},
            where: 'id = ?',
            whereArgs: [tracks[i]['id']],
          );
        }
      });

      _logger.info(
        'Reordered tracks in playlist $playlistId from $oldIndex to $newIndex',
      );
    } catch (e) {
      _logger.error(
        'Failed to reorder tracks in playlist $playlistId',
        e,
      );
      rethrow;
    }
  }

  /// Get all tracks in a playlist ordered by order_index
  /// Returns list of tracks with their playlist order
  Future<List<Map<String, dynamic>>> getPlaylistTracks(int playlistId) async {
    try {
      final db = await database;
      final results = await db.rawQuery('''
        SELECT t.*, pt.order_index
        FROM tracks t
        INNER JOIN playlist_tracks pt ON t.id = pt.track_id
        WHERE pt.playlist_id = ?
        ORDER BY pt.order_index ASC
      ''', [playlistId]);
      _logger.info('Retrieved ${results.length} tracks for playlist $playlistId');
      return results;
    } catch (e) {
      _logger.error('Failed to get tracks for playlist $playlistId', e);
      rethrow;
    }
  }

  // ============================================================================
  // StreamSource CRUD Operations
  // ============================================================================

  /// Insert a new stream source into the database
  /// Returns the ID of the inserted stream source
  Future<int> insertStreamSource(Map<String, dynamic> streamSource) async {
    try {
      final db = await database;
      final id = await db.insert(
        'stream_sources',
        streamSource,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _logger.info('Inserted stream source with ID: $id');
      return id;
    } catch (e) {
      _logger.error('Failed to insert stream source', e);
      rethrow;
    }
  }

  /// Get a stream source by ID
  /// Returns null if stream source not found
  Future<Map<String, dynamic>?> getStreamSource(int id) async {
    try {
      final db = await database;
      final results = await db.query(
        'stream_sources',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      _logger.error('Failed to get stream source with ID: $id', e);
      rethrow;
    }
  }

  /// Get all stream sources from the database
  /// Returns list of stream sources ordered by name
  Future<List<Map<String, dynamic>>> getAllStreamSources() async {
    try {
      final db = await database;
      final results = await db.query(
        'stream_sources',
        orderBy: 'name ASC',
      );
      _logger.info('Retrieved ${results.length} stream sources');
      return results;
    } catch (e) {
      _logger.error('Failed to get all stream sources', e);
      rethrow;
    }
  }

  /// Update an existing stream source
  /// Returns the number of rows affected
  Future<int> updateStreamSource(
    int id,
    Map<String, dynamic> streamSource,
  ) async {
    try {
      final db = await database;
      final count = await db.update(
        'stream_sources',
        streamSource,
        where: 'id = ?',
        whereArgs: [id],
      );
      _logger.info('Updated stream source with ID: $id');
      return count;
    } catch (e) {
      _logger.error('Failed to update stream source with ID: $id', e);
      rethrow;
    }
  }

  /// Delete a stream source by ID
  /// Returns the number of rows affected
  Future<int> deleteStreamSource(int id) async {
    try {
      final db = await database;
      final count = await db.delete(
        'stream_sources',
        where: 'id = ?',
        whereArgs: [id],
      );
      _logger.info('Deleted stream source with ID: $id');
      return count;
    } catch (e) {
      _logger.error('Failed to delete stream source with ID: $id', e);
      rethrow;
    }
  }

  /// Get all favorite stream sources
  /// Returns list of stream sources where is_favorite = 1
  Future<List<Map<String, dynamic>>> getFavoriteStreams() async {
    try {
      final db = await database;
      final results = await db.query(
        'stream_sources',
        where: 'is_favorite = ?',
        whereArgs: [1],
        orderBy: 'name ASC',
      );
      _logger.info('Retrieved ${results.length} favorite stream sources');
      return results;
    } catch (e) {
      _logger.error('Failed to get favorite stream sources', e);
      rethrow;
    }
  }

  /// Get recently played stream sources
  /// Returns list of stream sources ordered by last_played_at descending
  Future<List<Map<String, dynamic>>> getRecentlyPlayedStreams(
    int limit,
  ) async {
    try {
      final db = await database;
      final results = await db.query(
        'stream_sources',
        where: 'last_played_at IS NOT NULL',
        orderBy: 'last_played_at DESC',
        limit: limit,
      );
      _logger.info('Retrieved ${results.length} recently played stream sources');
      return results;
    } catch (e) {
      _logger.error('Failed to get recently played stream sources', e);
      rethrow;
    }
  }

  // ============================================================================
  // EqPreset CRUD Operations
  // ============================================================================

  /// Insert a new equalizer preset into the database
  /// Returns the ID of the inserted preset
  Future<int> insertEqPreset(Map<String, dynamic> preset) async {
    try {
      final db = await database;
      final id = await db.insert(
        'eq_presets',
        preset,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _logger.info('Inserted EQ preset with ID: $id');
      return id;
    } catch (e) {
      _logger.error('Failed to insert EQ preset', e);
      rethrow;
    }
  }

  /// Get an equalizer preset by ID
  /// Returns null if preset not found
  Future<Map<String, dynamic>?> getEqPreset(int id) async {
    try {
      final db = await database;
      final results = await db.query(
        'eq_presets',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      _logger.error('Failed to get EQ preset with ID: $id', e);
      rethrow;
    }
  }

  /// Get all equalizer presets from the database
  /// Returns list of presets ordered by name
  Future<List<Map<String, dynamic>>> getAllEqPresets() async {
    try {
      final db = await database;
      final results = await db.query(
        'eq_presets',
        orderBy: 'name ASC',
      );
      _logger.info('Retrieved ${results.length} EQ presets');
      return results;
    } catch (e) {
      _logger.error('Failed to get all EQ presets', e);
      rethrow;
    }
  }

  /// Update an existing equalizer preset
  /// Returns the number of rows affected
  Future<int> updateEqPreset(int id, Map<String, dynamic> preset) async {
    try {
      final db = await database;
      final count = await db.update(
        'eq_presets',
        preset,
        where: 'id = ?',
        whereArgs: [id],
      );
      _logger.info('Updated EQ preset with ID: $id');
      return count;
    } catch (e) {
      _logger.error('Failed to update EQ preset with ID: $id', e);
      rethrow;
    }
  }

  /// Delete an equalizer preset by ID
  /// Returns the number of rows affected
  Future<int> deleteEqPreset(int id) async {
    try {
      final db = await database;
      final count = await db.delete(
        'eq_presets',
        where: 'id = ?',
        whereArgs: [id],
      );
      _logger.info('Deleted EQ preset with ID: $id');
      return count;
    } catch (e) {
      _logger.error('Failed to delete EQ preset with ID: $id', e);
      rethrow;
    }
  }

  // ============================================================================
  // Settings Operations
  // ============================================================================

  /// Get a setting value by key
  /// Returns null if setting not found
  Future<String?> getSetting(String key) async {
    try {
      final db = await database;
      final results = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );
      return results.isNotEmpty ? results.first['value'] as String : null;
    } catch (e) {
      _logger.error('Failed to get setting with key: $key', e);
      rethrow;
    }
  }

  /// Set a setting value by key
  /// Creates or updates the setting
  Future<void> setSetting(String key, String value) async {
    try {
      final db = await database;
      await db.insert(
        'settings',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _logger.info('Set setting: $key = $value');
    } catch (e) {
      _logger.error('Failed to set setting with key: $key', e);
      rethrow;
    }
  }
}
