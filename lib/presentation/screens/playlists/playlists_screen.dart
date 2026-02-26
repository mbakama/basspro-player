import 'package:flutter/material.dart';
import '../../../domain/entities/playlist.dart';
import '../../../domain/repositories/playlist_repository.dart';
import '../../../data/repositories/playlist_repository_impl.dart';
import '../../../data/datasources/database/database_service.dart';
import 'playlist_detail_screen.dart';

/// Playlists screen displaying smart playlists and user-created playlists.
/// 
/// Features:
/// - Smart Playlists section (Favoris, Récemment ajoutés, Les plus écoutés)
/// - My Playlists section with user-created playlists
/// - Playlist name and track count display
/// - Tap to view playlist details (placeholder)
/// - Long-press for rename/delete options (user playlists only)
/// - Create button to add new playlists
/// 
/// Requirements: 15.5, 17.1, 17.2, 17.3, 17.5
class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen>
    with AutomaticKeepAliveClientMixin {
  late final PlaylistRepository _repository;
  List<Playlist> _userPlaylists = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  // Smart playlist track counts (placeholder values for now)
  int _favoritesCount = 0;
  int _recentlyAddedCount = 0;
  int _mostPlayedCount = 0;

  @override
  bool get wantKeepAlive => true; // Keep state when switching tabs

  @override
  void initState() {
    super.initState();
    // Initialize repository but don't load data yet
    final databaseService = DatabaseService();
    _repository = PlaylistRepositoryImpl(databaseService);
    // Data will be loaded when widget is first built (lazy loading)
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load playlists lazily when screen is first displayed
    if (!_isInitialized) {
      _isInitialized = true;
      _loadPlaylists();
    }
  }

  Future<void> _loadPlaylists() async {
    if (_isLoading) return; // Prevent duplicate loads
    
    setState(() {
      _isLoading = true;
    });

    try {
      final playlists = await _repository.getAllPlaylists();
      
      // Load track counts for each playlist
      final playlistsWithCounts = <Playlist>[];
      for (final playlist in playlists) {
        playlistsWithCounts.add(playlist);
      }
      
      setState(() {
        _userPlaylists = playlistsWithCounts;
        _isLoading = false;
      });
      
      // Load smart playlist counts (placeholder for now)
      // TODO: Implement actual counts from repository
      setState(() {
        _favoritesCount = 0;
        _recentlyAddedCount = 0;
        _mostPlayedCount = 0;
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

  Future<int> _getPlaylistTrackCount(int playlistId) async {
    try {
      return await _repository.getPlaylistTrackCount(playlistId);
    } catch (e) {
      return 0;
    }
  }

  void _onPlaylistTap(String playlistName, {int? playlistId}) {
    if (playlistId != null) {
      // Navigate to playlist detail screen for user playlists
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlaylistDetailScreen(
            playlistId: playlistId,
            playlistName: playlistName,
          ),
        ),
      ).then((_) {
        // Reload playlists when returning from detail screen
        _loadPlaylists();
      });
    } else {
      // TODO: Implement smart playlist detail screens
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ouverture de "$playlistName"'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showPlaylistContextMenu(BuildContext context, Playlist playlist) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Renommer'),
              onTap: () {
                Navigator.pop(context);
                _showRenamePlaylistDialog(playlist);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDeletePlaylist(playlist);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreatePlaylistDialog() async {
    final nameController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer une playlist'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nom de la playlist',
            hintText: 'Ma playlist',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Le nom ne peut pas être vide'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      await _createPlaylist(nameController.text.trim());
    }
  }

  Future<void> _createPlaylist(String name) async {
    try {
      final playlist = Playlist(
        name: name,
        createdAt: DateTime.now(),
      );
      
      await _repository.insertPlaylist(playlist);
      await _loadPlaylists();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playlist "$name" créée'),
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

  Future<void> _showRenamePlaylistDialog(Playlist playlist) async {
    final nameController = TextEditingController(text: playlist.name);
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renommer la playlist'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nom de la playlist',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Le nom ne peut pas être vide'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Renommer'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      await _renamePlaylist(playlist, nameController.text.trim());
    }
  }

  Future<void> _renamePlaylist(Playlist playlist, String newName) async {
    try {
      final updatedPlaylist = playlist.copyWith(name: newName);
      await _repository.updatePlaylist(updatedPlaylist);
      await _loadPlaylists();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playlist renommée en "$newName"'),
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

  void _confirmDeletePlaylist(Playlist playlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la playlist'),
        content: Text(
          'Voulez-vous vraiment supprimer "${playlist.name}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePlaylist(playlist);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePlaylist(Playlist playlist) async {
    try {
      await _repository.deletePlaylist(playlist.id!);
      await _loadPlaylists();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playlist "${playlist.name}" supprimée'),
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
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreatePlaylistDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Chargement des playlists...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView(
              children: [
                // Smart Playlists section
                _buildSectionHeader('Playlists intelligentes'),
                _buildSmartPlaylistItem(
                  icon: Icons.favorite,
                  iconColor: Colors.red,
                  title: 'Favoris',
                  trackCount: _favoritesCount,
                ),
                _buildSmartPlaylistItem(
                  icon: Icons.access_time,
                  iconColor: Colors.blue,
                  title: 'Récemment ajoutés',
                  trackCount: _recentlyAddedCount,
                ),
                _buildSmartPlaylistItem(
                  icon: Icons.trending_up,
                  iconColor: Colors.green,
                  title: 'Les plus écoutés',
                  trackCount: _mostPlayedCount,
                ),
                
                const Divider(height: 32),
                
                // My Playlists section
                _buildSectionHeader('Mes playlists'),
                if (_userPlaylists.isEmpty)
                  _buildEmptyState()
                else
                  ..._userPlaylists.map((playlist) => _buildUserPlaylistItem(playlist)),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildSmartPlaylistItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required int trackCount,
  }) {
    return InkWell(
      onTap: () => _onPlaylistTap(title),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 32,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 12),
            // Playlist info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$trackCount ${trackCount <= 1 ? 'piste' : 'pistes'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildUserPlaylistItem(Playlist playlist) {
    return FutureBuilder<int>(
      future: _getPlaylistTrackCount(playlist.id!),
      builder: (context, snapshot) {
        final trackCount = snapshot.data ?? 0;
        
        return InkWell(
          onTap: () => _onPlaylistTap(playlist.name, playlistId: playlist.id),
          onLongPress: () => _showPlaylistContextMenu(context, playlist),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Playlist icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.playlist_play,
                    size: 32,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                // Playlist info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$trackCount ${trackCount <= 1 ? 'piste' : 'pistes'}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.playlist_play, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Aucune playlist',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Créez votre première playlist',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
