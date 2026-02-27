import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../../../domain/entities/track.dart';
import '../../../domain/repositories/playlist_repository.dart';
import '../../../data/repositories/playlist_repository_impl.dart';
import '../../../data/datasources/database/database_service.dart';
import '../../../data/services/audio/audio_service_initializer.dart';
import '../../../core/utils/format_utils.dart';
import '../../widgets/artwork_image.dart';

/// Playlist detail screen displaying tracks in a playlist with management options.
/// 
/// Features:
/// - Display playlist name and track count
/// - Show list of tracks in playlist with order
/// - Drag-to-reorder functionality using ReorderableListView
/// - Swipe-to-delete track from playlist using Dismissible
/// - Play playlist button (FAB) to load all tracks into queue
/// - Empty state when playlist has no tracks
/// 
/// Requirements: 16.2, 16.3, 16.4, 16.5
class PlaylistDetailScreen extends StatefulWidget {
  final int playlistId;
  final String playlistName;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    required this.playlistName,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  late final PlaylistRepository _repository;
  List<Track> _tracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize repository
    final databaseService = DatabaseService();
    _repository = PlaylistRepositoryImpl(databaseService);
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tracks = await _repository.getPlaylistTracks(widget.playlistId);
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reorderTracks(int oldIndex, int newIndex) async {
    // Adjust newIndex if moving down
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    // Update UI immediately for smooth experience
    setState(() {
      final track = _tracks.removeAt(oldIndex);
      _tracks.insert(newIndex, track);
    });

    try {
      // Update database
      await _repository.reorderPlaylistTracks(
        widget.playlistId,
        oldIndex,
        newIndex,
      );
    } catch (e) {
      // Revert on error
      await _loadTracks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de réorganisation: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeTrack(Track track) async {
    try {
      await _repository.removeTrackFromPlaylist(
        widget.playlistId,
        track.id!,
      );
      
      // Remove from local list
      setState(() {
        _tracks.removeWhere((t) => t.id == track.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${track.title} retiré de la playlist'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _playPlaylist() async {
    if (_tracks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La playlist est vide'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Get audio handler
    final audioHandler = AudioServiceInitializer.audioHandler;
    
    if (audioHandler == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service audio non initialisé'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Convert tracks to MediaItems
      final mediaItems = _tracks.map((track) {
        return MediaItem(
          id: track.uri,
          title: track.title,
          artist: track.artist,
          album: track.album,
          duration: track.duration,
          artUri: track.artworkUri != null ? Uri.parse(track.artworkUri!) : null,
          extras: {
            'trackId': track.id,
            'isStream': false,
          },
        );
      }).toList();

      // Set queue and start playback
      await audioHandler.setQueue(mediaItems);
      await audioHandler.play();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lecture de ${_tracks.length} piste${_tracks.length > 1 ? 's' : ''}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de lecture: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.playlistName),
            Text(
              FormatUtils.formatTrackCount(_tracks.length),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tracks.isEmpty
              ? _buildEmptyState()
              : ReorderableListView.builder(
                  itemCount: _tracks.length,
                  onReorder: _reorderTracks,
                  itemBuilder: (context, index) {
                    final track = _tracks[index];
                    return _buildTrackItem(track, index);
                  },
                ),
      floatingActionButton: _tracks.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _playPlaylist,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Lire'),
            )
          : null,
    );
  }

  Widget _buildTrackItem(Track track, int index) {
    return Dismissible(
      key: Key('track_${track.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        // Show confirmation dialog
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Retirer de la playlist'),
            content: Text(
              'Voulez-vous retirer "${track.title}" de cette playlist ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Retirer'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _removeTrack(track);
      },
      child: ListTile(
        key: Key('tile_${track.id}'),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Order number
            SizedBox(
              width: 32,
              child: Text(
                '${index + 1}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 8),
            // Album artwork or placeholder with caching
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: track.artworkUri != null
                  ? ArtworkImage.track(artworkUri: track.artworkUri, width: 48, height: 48)
                  : const Icon(Icons.music_note_rounded),
            ),
          ],
        ),
        title: Text(
          track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          track.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              FormatUtils.formatDuration(track.duration),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(width: 8),
            // Drag handle
            const Icon(Icons.drag_handle, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Playlist vide',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ajoutez des pistes à cette playlist depuis la bibliothèque',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
