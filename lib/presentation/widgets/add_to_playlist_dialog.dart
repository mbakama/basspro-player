import 'package:flutter/material.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/entities/track.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../../data/repositories/playlist_repository_impl.dart';
import '../../data/datasources/database/database_service.dart';

/// Dialog for adding a track to a playlist.
/// 
/// Features:
/// - Displays a list of all user playlists
/// - Allows user to select a playlist
/// - Adds the track to the selected playlist
/// - Shows success/error messages
/// - Validates playlist selection
/// 
/// Requirements: 15.1, 15.2, 15.3, 16.1
class AddToPlaylistDialog extends StatefulWidget {
  final Track track;

  const AddToPlaylistDialog({
    super.key,
    required this.track,
  });

  @override
  State<AddToPlaylistDialog> createState() => _AddToPlaylistDialogState();
}

class _AddToPlaylistDialogState extends State<AddToPlaylistDialog> {
  late final PlaylistRepository _repository;
  List<Playlist> _playlists = [];
  bool _isLoading = true;
  String? _error;
  Playlist? _selectedPlaylist;

  @override
  void initState() {
    super.initState();
    // Initialize repository
    final databaseService = DatabaseService();
    _repository = PlaylistRepositoryImpl(databaseService);
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final playlists = await _repository.getAllPlaylists();
      setState(() {
        _playlists = playlists;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur de chargement: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _addTrackToPlaylist() async {
    if (_selectedPlaylist == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une playlist'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Get the current track count to determine the order index
      final trackCount = await _repository.getPlaylistTrackCount(_selectedPlaylist!.id!);
      
      // Add track to playlist with the next order index
      await _repository.addTrackToPlaylist(
        _selectedPlaylist!.id!,
        widget.track.id!,
        trackCount, // This will be the next position (0-indexed)
      );

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ajouté à "${_selectedPlaylist!.name}"'),
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter à la playlist'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _loadPlaylists,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                : _playlists.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.playlist_play, size: 48, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text(
                              'Aucune playlist',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Créez une playlist d\'abord',
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _playlists.length,
                        itemBuilder: (context, index) {
                          final playlist = _playlists[index];
                          final isSelected = _selectedPlaylist?.id == playlist.id;
                          
                          return ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                                    : Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.playlist_play,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                            title: Text(playlist.name),
                            subtitle: FutureBuilder<int>(
                              future: _repository.getPlaylistTrackCount(playlist.id!),
                              builder: (context, snapshot) {
                                final count = snapshot.data ?? 0;
                                return Text(
                                  '$count ${count <= 1 ? 'piste' : 'pistes'}',
                                  style: const TextStyle(color: Colors.grey),
                                );
                              },
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color: Theme.of(context).colorScheme.primary,
                                  )
                                : null,
                            selected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedPlaylist = playlist;
                              });
                            },
                          );
                        },
                      ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _playlists.isEmpty ? null : _addTrackToPlaylist,
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}
