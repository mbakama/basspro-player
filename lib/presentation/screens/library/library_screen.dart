import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../domain/entities/track.dart';
import '../../../domain/repositories/track_repository.dart';
import '../../../data/repositories/track_repository_impl.dart';
import '../../../data/datasources/database/database_service.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/utils/error_handler.dart';
import '../../widgets/add_to_playlist_dialog.dart';
import '../../widgets/error_display.dart';

/// Library screen displaying the user's local music collection.
/// 
/// Features:
/// - Tab bar for Songs/Artists/Albums views (currently only Songs implemented)
/// - Sort dropdown with multiple options
/// - Track list with artwork, title, artist, and duration
/// - Tap to play functionality (placeholder)
/// - Long-press context menu for actions
/// - Asynchronous data loading with loading indicators
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final TrackRepository _repository;
  SortOption _currentSortOption = SortOption.title;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Async data loading state
  List<Track> _tracks = [];
  bool _isLoading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_onSearchChanged);
    
    // Initialize repository
    final databaseService = DatabaseService();
    _repository = TrackRepositoryImpl(databaseService);
    
    // Load tracks asynchronously (non-blocking)
    _loadTracks();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// Load tracks from database asynchronously.
  /// 
  /// This method loads library data in the background and updates the UI
  /// when ready. Shows loading indicator while loading.
  Future<void> _loadTracks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tracks = await _repository.getAllTracks();
      
      if (mounted) {
        setState(() {
          _tracks = tracks;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      ErrorHandler.handle(e, stackTrace, 'LibraryScreen._loadTracks');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e;
        });
      }
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  List<Track> get _sortedTracks {
    // First filter by search query
    List<Track> tracks = _tracks;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      tracks = tracks.where((track) {
        return track.title.toLowerCase().contains(query) ||
            track.artist.toLowerCase().contains(query) ||
            track.album.toLowerCase().contains(query);
      }).toList();
    } else {
      tracks = List<Track>.from(_tracks);
    }

    // Then sort the filtered results
    switch (_currentSortOption) {
      case SortOption.title:
        tracks.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortOption.artist:
        tracks.sort((a, b) => a.artist.compareTo(b.artist));
        break;
      case SortOption.album:
        tracks.sort((a, b) => a.album.compareTo(b.album));
        break;
      case SortOption.date:
        tracks.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        break;
      case SortOption.duration:
        tracks.sort((a, b) => b.duration.compareTo(a.duration));
        break;
    }
    return tracks;
  }

  void _onTrackTap(Track track) {
    // TODO: Implement play functionality with audio service
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lecture de "${track.title}"'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showTrackContextMenu(BuildContext context, Track track) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('Ajouter à la playlist'),
              onTap: () {
                Navigator.pop(context);
                _showAddToPlaylistDialog(track);
              },
            ),
            ListTile(
              leading: Icon(
                track.isFavorite ? Icons.favorite : Icons.favorite_border,
              ),
              title: Text(
                track.isFavorite
                    ? 'Retirer des favoris'
                    : 'Ajouter aux favoris',
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      track.isFavorite
                          ? 'Retiré des favoris'
                          : 'Ajouté aux favoris',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddToPlaylistDialog(Track track) async {
    await showDialog(
      context: context,
      builder: (context) => AddToPlaylistDialog(track: track),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Rechercher...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 18),
              )
            : const Text('Bibliothèque'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chansons'),
            Tab(text: 'Artistes'),
            Tab(text: 'Albums'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Songs tab
          _buildSongsView(),
          // Artists tab (placeholder)
          _buildPlaceholderView('Artistes'),
          // Albums tab (placeholder)
          _buildPlaceholderView('Albums'),
        ],
      ),
    );
  }

  Widget _buildSongsView() {
    // Show loading indicator while loading tracks
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Chargement de la bibliothèque...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Show error message if loading failed
    if (_error != null) {
      return ErrorDisplay(
        error: _error!,
        onRetry: _loadTracks,
      );
    }

    return Column(
      children: [
        // Sort dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text(
                'Trier par:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<SortOption>(
                  value: _currentSortOption,
                  isExpanded: true,
                  underline: Container(),
                  items: const [
                    DropdownMenuItem(
                      value: SortOption.title,
                      child: Text('Titre'),
                    ),
                    DropdownMenuItem(
                      value: SortOption.artist,
                      child: Text('Artiste'),
                    ),
                    DropdownMenuItem(
                      value: SortOption.album,
                      child: Text('Album'),
                    ),
                    DropdownMenuItem(
                      value: SortOption.date,
                      child: Text('Date d\'ajout'),
                    ),
                    DropdownMenuItem(
                      value: SortOption.duration,
                      child: Text('Durée'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _currentSortOption = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Track list
        Expanded(
          child: _sortedTracks.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _sortedTracks.length,
                  itemBuilder: (context, index) {
                    final track = _sortedTracks[index];
                    return _buildTrackItem(track);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTrackItem(Track track) {
    return InkWell(
      onTap: () => _onTrackTap(track),
      onLongPress: () => _showTrackContextMenu(context, track),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Artwork thumbnail with caching
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: track.artworkUri != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedNetworkImage(
                        imageUrl: track.artworkUri!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.music_note, size: 32),
                        memCacheWidth: 112, // 2x for retina displays
                        memCacheHeight: 112,
                        maxWidthDiskCache: 200,
                        maxHeightDiskCache: 200,
                      ),
                    )
                  : const Icon(Icons.music_note, size: 32),
            ),
            const SizedBox(width: 12),
            // Track info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    track.artist,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Duration
            Text(
              FormatUtils.formatDuration(track.duration),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Aucun résultat',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune chanson ne correspond à "$_searchQuery"',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_music, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Aucune chanson',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Votre collection musicale apparaîtra ici',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderView(String viewName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            viewName == 'Artistes' ? Icons.person : Icons.album,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            viewName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Vue $viewName à implémenter',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// Sort options for the library
enum SortOption {
  title,
  artist,
  album,
  date,
  duration,
}
