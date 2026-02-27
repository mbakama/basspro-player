import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/scanner_provider.dart';
import '../../../data/services/library_scanner_service.dart';
import '../../../domain/entities/track.dart';
import '../../../domain/repositories/track_repository.dart';
import '../../../data/services/audio/audio_service_initializer.dart';
import '../../../data/services/audio/basspro_audio_handler.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/utils/media_item_mapper.dart';
import '../../widgets/add_to_playlist_dialog.dart';
import '../../widgets/artwork_image.dart';
import '../player/now_playing_screen.dart';
import '../../widgets/error_display.dart';
import '../../../data/datasources/database/database_service.dart';
import '../../../data/repositories/track_repository_impl.dart';
import '../../../core/constants/app_colors.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final TrackRepository _repository;
  SortOption _currentSortOption = SortOption.title;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  List<Track> _tracks = [];
  bool _isLoading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() => setState(() => _searchQuery = _searchController.text));
    final databaseService = DatabaseService();
    _repository = TrackRepositoryImpl(databaseService);
    _loadTracks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTracks() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final tracks = await _repository.getAllTracks();
      if (mounted) setState(() { _tracks = tracks; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e; });
    }
  }

  List<Track> get _sortedTracks {
    List<Track> tracks = _tracks;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      tracks = tracks.where((t) => t.title.toLowerCase().contains(query) || t.artist.toLowerCase().contains(query)).toList();
    } else {
      tracks = List<Track>.from(_tracks);
    }

    switch (_currentSortOption) {
      case SortOption.title: tracks.sort((a, b) => a.title.compareTo(b.title)); break;
      case SortOption.artist: tracks.sort((a, b) => a.artist.compareTo(b.artist)); break;
      case SortOption.date: tracks.sort((a, b) => b.dateAdded.compareTo(a.dateAdded)); break;
      case SortOption.duration: tracks.sort((a, b) => b.duration.compareTo(a.duration)); break;
      default: break;
    }
    return tracks;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Rechercher...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  style: const TextStyle(fontSize: 18),
                ),
              )
            : const Text('Bibliothèque'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () => setState(() => _isSearching = !_isSearching),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.darkPrimary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
          tabs: const [Tab(text: 'PISTES'), Tab(text: 'ARTISTES'), Tab(text: 'ALBUMS')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSongsView(theme), _buildPlaceholderView('Artistes'), _buildPlaceholderView('Albums')],
      ),
    );
  }

  Widget _buildSongsView(ThemeData theme) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorDisplay(error: _error!, onRetry: _loadTracks);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text('Trier par:', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.darkTextSecondary)),
              const SizedBox(width: 12),
              DropdownButton<SortOption>(
                value: _currentSortOption,
                underline: const SizedBox(),
                dropdownColor: AppColors.darkSurface,
                items: const [
                  DropdownMenuItem(value: SortOption.title, child: Text('Titre')),
                  DropdownMenuItem(value: SortOption.artist, child: Text('Artiste')),
                  DropdownMenuItem(value: SortOption.date, child: Text('Récent')),
                ],
                onChanged: (v) => setState(() => _currentSortOption = v!),
              ),
              const Spacer(),
              Text('${_sortedTracks.length} titres', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.darkPrimary)),
            ],
          ),
        ),
        Expanded(
          child: _sortedTracks.isEmpty ? _buildEmptyState() : ListView.builder(
            padding: const EdgeInsets.only(bottom: 180),
            itemCount: _sortedTracks.length,
            itemBuilder: (context, index) => _buildTrackItem(_sortedTracks[index], theme, index),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackItem(Track track, ThemeData theme, int index) {
    return ListTile(
      onTap: () {
        debugPrint('LibraryScreen: Click detected on "${track.title}" (index $index)');
        _playTrack(index);
      },
      onLongPress: () => _showTrackContextMenu(context, track),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 48, height: 48,
          color: Colors.white.withValues(alpha: 0.05),
          child: track.artworkUri != null 
            ? ArtworkImage.track(artworkUri: track.artworkUri, width: 48, height: 48)
            : const Icon(Icons.music_note_rounded, color: Colors.white24),
        ),
      ),
      title: Text(track.title, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(track.artist, style: theme.textTheme.bodySmall?.copyWith(color: Colors.white54), maxLines: 1),
      trailing: Text(FormatUtils.formatDuration(track.duration), style: theme.textTheme.labelSmall?.copyWith(color: Colors.white30)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.library_music_rounded, size: 80, color: Colors.white10),
          const SizedBox(height: 24),
          const Text(
            'Votre bibliothèque est vide',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Recherchez des fichiers audio sur votre appareil',
            style: TextStyle(color: Colors.white38, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _startScan,
            icon: const Icon(Icons.search_rounded),
            label: const Text('Lancer l\'analyse'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startScan() async {
    final scannerService = ref.read(libraryScannerServiceProvider);
    
    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('Analyse de la bibliothèque', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LinearProgressIndicator(color: AppColors.darkPrimary),
            const SizedBox(height: 16),
            StreamBuilder<ScanProgress>(
              stream: scannerService.scanProgressStream,
              builder: (context, snapshot) {
                final message = snapshot.data?.message ?? 'Préparation...';
                return Text(
                  message,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                );
              },
            ),
          ],
        ),
      ),
    );

    try {
      await scannerService.scanLibrary();
      // Reload tracks after scan
      await _loadTracks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'analyse: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        Navigator.pop(context); // Close dialog
      }
    }
  }

  Widget _buildPlaceholderView(String label) {
    return Center(child: Text(label, style: const TextStyle(color: Colors.white24)));
  }

  void _showTrackContextMenu(BuildContext context, Track track) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.playlist_add_rounded), title: const Text('Ajouter à la playlist'), onTap: () { Navigator.pop(context); _showAddToPlaylistDialog(track); }),
            ListTile(leading: Icon(track.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: track.isFavorite ? AppColors.favoriteActive : null), title: Text(track.isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris'), onTap: () { Navigator.pop(context); }),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddToPlaylistDialog(Track track) async {
    await showDialog(context: context, builder: (context) => AddToPlaylistDialog(track: track));
  }

  Future<void> _playTrack(int index) async {
    // Attendre que l'AudioService soit disponible avec timeout
    BassProAudioHandler? audioHandler;
    int attempts = 0;
    const maxAttempts = 20; // 20 tentatives max (10 secondes)
    
    while (attempts < maxAttempts) {
      audioHandler = AudioServiceInitializer.audioHandler;
      if (audioHandler != null) break;
      
      attempts++;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    if (audioHandler == null) {
      // Tenter de réinitialiser l'AudioService une fois
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tentative de réinitialisation du service audio...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      try {
        // Tenter une réinitialisation forcée
        audioHandler = await AudioServiceInitializer.forceReinitialize();
        await Future.delayed(const Duration(seconds: 1)); // Attendre que tout soit prêt
      } catch (e) {
        debugPrint('LibraryScreen: Failed to force reinitialize audio service: $e');
      }
    }
    
    if (audioHandler == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service audio indisponible. Redémarrez l\'application.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    final mediaItems = _sortedTracks.map((t) => t.toMediaItem()).toList();
    final selectedTrack = _sortedTracks[index];
    
    debugPrint('LibraryScreen: Attempting to play "${selectedTrack.title}"');
    
    try {
      debugPrint('LibraryScreen: Setting queue with ${mediaItems.length} items');
      await audioHandler.setQueue(mediaItems);
      
      debugPrint('LibraryScreen: Skipping to item $index');
      await audioHandler.skipToQueueItem(index);
      
      debugPrint('LibraryScreen: Starting playback');
      await audioHandler.play();
      
      // Navigate to Now Playing screen
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const NowPlayingScreen()),
        );
      }
    } catch (e) {
      debugPrint('LibraryScreen: Error playing track: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de lecture: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }
}

enum SortOption { title, artist, album, date, duration }
