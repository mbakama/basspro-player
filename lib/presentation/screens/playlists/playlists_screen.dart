import 'package:flutter/material.dart';
import '../../../domain/entities/playlist.dart';
import '../../../domain/repositories/playlist_repository.dart';
import '../../../data/repositories/playlist_repository_impl.dart';
import '../../../data/datasources/database/database_service.dart';
import '../../../core/constants/app_colors.dart';
import 'playlist_detail_screen.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> with AutomaticKeepAliveClientMixin {
  late final PlaylistRepository _repository;
  List<Playlist> _userPlaylists = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final databaseService = DatabaseService();
    _repository = PlaylistRepositoryImpl(databaseService);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _loadPlaylists();
    }
  }

  Future<void> _loadPlaylists() async {
    setState(() => _isLoading = true);
    try {
      final playlists = await _repository.getAllPlaylists();
      setState(() { _userPlaylists = playlists; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        actions: [
          IconButton(icon: const Icon(Icons.playlist_add_rounded), onPressed: _showCreatePlaylistDialog),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              _buildSectionHeader('Automatiques'),
              _buildSmartItem(Icons.favorite_rounded, 'Favoris', AppColors.favoriteActive, theme),
              _buildSmartItem(Icons.history_rounded, 'Récents', AppColors.darkPrimary, theme),
              _buildSmartItem(Icons.trending_up_rounded, 'Meilleures', AppColors.darkSecondary, theme),
              const SizedBox(height: 24),
              _buildSectionHeader('Mes Playlists'),
              if (_userPlaylists.isEmpty) _buildEmptyState()
              else ..._userPlaylists.map((p) => _buildPlaylistItem(p, theme)),
            ],
          ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(title.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white24, letterSpacing: 1.2)),
    );
  }

  Widget _buildSmartItem(IconData icon, String title, Color color, ThemeData theme) {
    return ListTile(
      leading: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(title, style: theme.textTheme.titleMedium),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white12),
      onTap: () {},
    );
  }

  Widget _buildPlaylistItem(Playlist playlist, ThemeData theme) {
    return ListTile(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => PlaylistDetailScreen(playlistId: playlist.id!, playlistName: playlist.name))),
      onLongPress: () => _showPlaylistContextMenu(context, playlist),
      leading: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.playlist_play_rounded, color: Colors.white30),
      ),
      title: Text(playlist.name, style: theme.textTheme.titleMedium),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white12),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Aucune playlist utilisateur', style: TextStyle(color: Colors.white12))));
  }

  void _showPlaylistContextMenu(BuildContext context, Playlist playlist) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.edit_rounded), title: const Text('Renommer'), onTap: () { Navigator.pop(context); _showRenamePlaylistDialog(playlist); }),
            ListTile(leading: const Icon(Icons.delete_outline_rounded, color: Colors.red), title: const Text('Supprimer', style: TextStyle(color: Colors.red)), onTap: () { Navigator.pop(context); _confirmDeletePlaylist(playlist); }),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreatePlaylistDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle playlist'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Nom')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ANNULER')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('CRÉER')),
        ],
      ),
    );
    if (result == true && controller.text.isNotEmpty) {
      await _repository.insertPlaylist(Playlist(name: controller.text, createdAt: DateTime.now()));
      _loadPlaylists();
    }
  }

  Future<void> _showRenamePlaylistDialog(Playlist playlist) async {
    final controller = TextEditingController(text: playlist.name);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renommer'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ANNULER')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('RENOMMER')),
        ],
      ),
    );
    if (result == true && controller.text.isNotEmpty) {
      await _repository.updatePlaylist(playlist.copyWith(name: controller.text));
      _loadPlaylists();
    }
  }

  void _confirmDeletePlaylist(Playlist playlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('Supprimer la playlist "${playlist.name}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ANNULER')),
          TextButton(onPressed: () { Navigator.pop(context); _deletePlaylist(playlist); }, child: const Text('SUPPRIMER', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Future<void> _deletePlaylist(Playlist playlist) async {
    await _repository.deletePlaylist(playlist.id!);
    _loadPlaylists();
  }
}
