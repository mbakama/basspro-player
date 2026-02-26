import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../../../core/utils/format_utils.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/audio/audio_service_initializer.dart';
import '../../../domain/repositories/track_repository.dart';
import '../../../data/repositories/track_repository_impl.dart';
import '../../../data/datasources/database/database_service.dart';
import '../../../domain/entities/track.dart';
import '../../widgets/add_to_playlist_dialog.dart';

/// Full-screen Now Playing screen that displays the currently playing track
/// with large album artwork, playback controls, and additional actions.
/// 
/// Features:
/// - Large album artwork (300x300)
/// - Track title, artist, and album
/// - Seek bar with current position and total duration
/// - Main controls: shuffle, previous, play/pause, next, repeat
/// - Secondary actions: favorite, add to queue, open equalizer
/// - Swipe down to dismiss gesture
/// - Swipe left/right to skip tracks
class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  // Audio handler for playback control
  final _audioHandler = AudioServiceInitializer.audioHandler;
  
  // Repository for track operations
  late final TrackRepository _trackRepository;
  
  // Stream subscriptions
  StreamSubscription<PlaybackState>? _playbackStateSubscription;
  StreamSubscription<MediaItem?>? _mediaItemSubscription;
  
  // Current state
  bool _isPlaying = false;
  bool _isShuffle = false;
  AudioServiceRepeatMode _repeatMode = AudioServiceRepeatMode.none;
  bool _isFavorite = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isDraggingSeekBar = false;
  
  // Current media item and track
  MediaItem? _currentMediaItem;
  Track? _currentTrack;

  @override
  void initState() {
    super.initState();
    // Initialize repository
    final databaseService = DatabaseService();
    _trackRepository = TrackRepositoryImpl(databaseService);
    _setupListeners();
  }

  @override
  void dispose() {
    _playbackStateSubscription?.cancel();
    _mediaItemSubscription?.cancel();
    super.dispose();
  }

  /// Set up listeners for audio service streams
  void _setupListeners() {
    if (_audioHandler == null) return;

    // Listen to playback state changes
    _playbackStateSubscription = _audioHandler!.playbackState.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          _isShuffle = state.shuffleMode == AudioServiceShuffleMode.all;
          _repeatMode = state.repeatMode;
          
          // Update position only if not dragging seek bar
          if (!_isDraggingSeekBar) {
            _currentPosition = state.updatePosition;
          }
        });
      }
    });

    // Listen to media item changes
    _mediaItemSubscription = _audioHandler!.mediaItem.listen((item) {
      if (mounted) {
        setState(() {
          _currentMediaItem = item;
          _totalDuration = item?.duration ?? Duration.zero;
        });
        // Load track and favorite status from database
        _loadTrackFromMediaItem(item);
      }
    });
  }

  /// Load track from database using media item URI
  Future<void> _loadTrackFromMediaItem(MediaItem? item) async {
    if (item == null) {
      setState(() {
        _currentTrack = null;
        _isFavorite = false;
      });
      return;
    }

    try {
      // MediaItem ID is the track URI
      final uri = item.id;
      
      // Get all tracks and find by URI
      // Note: This is not optimal but works for now. A better solution would be
      // to add a getTrackByUri method to the repository.
      final allTracks = await _trackRepository.getAllTracks();
      final track = allTracks.where((t) => t.uri == uri).firstOrNull;
      
      if (mounted) {
        setState(() {
          _currentTrack = track;
          _isFavorite = track?.isFavorite ?? false;
        });
      }
    } catch (e) {
      // If track not found in database (e.g., streaming), just ignore
      if (mounted) {
        setState(() {
          _currentTrack = null;
          _isFavorite = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: GestureDetector(
        // Swipe down to dismiss
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
            Navigator.of(context).pop();
          }
        },
        // Swipe left/right to skip tracks
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! > 300) {
              // Swipe right - previous track
              _handlePrevious();
            } else if (details.primaryVelocity! < -300) {
              // Swipe left - next track
              _handleNext();
            }
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              // Top bar with back button and menu
              _buildTopBar(context),
              
              // Spacer
              const SizedBox(height: 20),
              
              // Album artwork
              _buildAlbumArtwork(context),
              
              // Spacer
              const SizedBox(height: 32),
              
              // Track info
              _buildTrackInfo(context),
              
              // Spacer
              const SizedBox(height: 24),
              
              // Seek bar
              _buildSeekBar(context),
              
              // Spacer
              const SizedBox(height: 32),
              
              // Main playback controls
              _buildMainControls(context),
              
              // Spacer
              const SizedBox(height: 24),
              
              // Secondary actions
              _buildSecondaryActions(context),
              
              // Bottom spacer
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, size: 32),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Retour',
          ),
          Text(
            'Lecture en cours',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show more options menu
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Menu d\'options'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Plus d\'options',
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArtwork(BuildContext context) {
    return Center(
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _currentMediaItem?.artUri != null
              ? CachedNetworkImage(
                  imageUrl: _currentMediaItem!.artUri.toString(),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(
                      color: Colors.grey[600],
                    ),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.album,
                    size: 120,
                    color: Colors.grey[600],
                  ),
                  memCacheWidth: 600, // 2x for retina displays
                  memCacheHeight: 600,
                  maxWidthDiskCache: 800,
                  maxHeightDiskCache: 800,
                )
              : Icon(
                  Icons.album,
                  size: 120,
                  color: Colors.grey[600],
                ),
        ),
      ),
    );
  }

  Widget _buildTrackInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          // Track title
          Text(
            _currentMediaItem?.title ?? 'Aucune piste',
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Artist name
          Text(
            _currentMediaItem?.artist ?? 'Artiste inconnu',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Album name
          Text(
            _currentMediaItem?.album ?? 'Album inconnu',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSeekBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          // Seek slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
              activeTrackColor: AppColors.playButtonActive,
              inactiveTrackColor: Colors.grey[700],
              thumbColor: AppColors.playButtonActive,
              overlayColor: AppColors.playButtonActive.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _currentPosition.inSeconds.toDouble().clamp(
                0.0,
                _totalDuration.inSeconds.toDouble().clamp(0.1, double.infinity),
              ),
              min: 0.0,
              max: _totalDuration.inSeconds.toDouble().clamp(0.1, double.infinity),
              onChanged: (value) {
                setState(() {
                  _isDraggingSeekBar = true;
                  _currentPosition = Duration(seconds: value.toInt());
                });
              },
              onChangeEnd: (value) {
                setState(() {
                  _isDraggingSeekBar = false;
                });
                // Seek to the new position
                _audioHandler?.seek(Duration(seconds: value.toInt()));
              },
            ),
          ),
          // Time labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  FormatUtils.formatDuration(_currentPosition),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  FormatUtils.formatDuration(_totalDuration),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Shuffle button
          IconButton(
            icon: Icon(
              Icons.shuffle,
              color: _isShuffle ? AppColors.shuffleActive : Colors.grey,
            ),
            iconSize: 28,
            onPressed: _handleShuffle,
            tooltip: 'Aléatoire',
          ),
          
          // Previous button
          IconButton(
            icon: const Icon(Icons.skip_previous),
            iconSize: 40,
            onPressed: _handlePrevious,
            tooltip: 'Précédent',
          ),
          
          // Play/Pause button (large)
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.playButtonActive,
              boxShadow: [
                BoxShadow(
                  color: AppColors.playButtonActive.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.black,
              ),
              iconSize: 40,
              onPressed: _handlePlayPause,
              tooltip: _isPlaying ? 'Pause' : 'Lecture',
            ),
          ),
          
          // Next button
          IconButton(
            icon: const Icon(Icons.skip_next),
            iconSize: 40,
            onPressed: _handleNext,
            tooltip: 'Suivant',
          ),
          
          // Repeat button
          IconButton(
            icon: Icon(
              _repeatMode == AudioServiceRepeatMode.one ? Icons.repeat_one : Icons.repeat,
              color: _repeatMode != AudioServiceRepeatMode.none ? AppColors.shuffleActive : Colors.grey,
            ),
            iconSize: 28,
            onPressed: _handleRepeat,
            tooltip: _getRepeatTooltip(),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Favorite button
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? AppColors.favoriteActive : Colors.grey,
            ),
            iconSize: 28,
            onPressed: _handleFavorite,
            tooltip: 'Favori',
          ),
          
          // Add to playlist button
          IconButton(
            icon: const Icon(Icons.queue_music),
            iconSize: 28,
            onPressed: _handleAddToQueue,
            tooltip: 'Ajouter à la playlist',
          ),
          
          // Equalizer button
          IconButton(
            icon: const Icon(Icons.equalizer),
            iconSize: 28,
            onPressed: _handleOpenEqualizer,
            tooltip: 'Égaliseur',
          ),
        ],
      ),
    );
  }

  // Control handlers - connected to audio service
  void _handlePlayPause() {
    if (_audioHandler == null) return;
    
    if (_isPlaying) {
      _audioHandler!.pause();
    } else {
      _audioHandler!.play();
    }
  }

  void _handlePrevious() {
    if (_audioHandler == null) return;
    _audioHandler!.skipToPrevious();
  }

  void _handleNext() {
    if (_audioHandler == null) return;
    _audioHandler!.skipToNext();
  }

  void _handleShuffle() {
    if (_audioHandler == null) return;
    
    final newShuffleMode = _isShuffle 
        ? AudioServiceShuffleMode.none 
        : AudioServiceShuffleMode.all;
    _audioHandler!.setShuffleMode(newShuffleMode);
  }

  void _handleRepeat() {
    if (_audioHandler == null) return;
    
    // Cycle through: none → all → one → none
    AudioServiceRepeatMode newMode;
    switch (_repeatMode) {
      case AudioServiceRepeatMode.none:
        newMode = AudioServiceRepeatMode.all;
        break;
      case AudioServiceRepeatMode.all:
        newMode = AudioServiceRepeatMode.one;
        break;
      case AudioServiceRepeatMode.one:
        newMode = AudioServiceRepeatMode.none;
        break;
      case AudioServiceRepeatMode.group:
        newMode = AudioServiceRepeatMode.none;
        break;
    }
    
    _audioHandler!.setRepeatMode(newMode);
  }

  void _handleFavorite() async {
    // Only allow favoriting local tracks (not streams)
    if (_currentTrack == null || _currentTrack!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de marquer ce contenu comme favori'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      // Toggle favorite in database
      await _trackRepository.toggleFavorite(_currentTrack!.id!);
      
      // Update local state
      setState(() {
        _isFavorite = !_isFavorite;
        _currentTrack = _currentTrack!.copyWith(isFavorite: _isFavorite);
      });

      // Show feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorite ? 'Ajouté aux favoris' : 'Retiré des favoris',
            ),
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
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _handleAddToQueue() async {
    // Only allow adding local tracks to playlists (not streams)
    if (_currentTrack == null || _currentTrack!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ajouter ce contenu à une playlist'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Show add to playlist dialog
    await showDialog<bool>(
      context: context,
      builder: (context) => AddToPlaylistDialog(track: _currentTrack!),
    );

    // Dialog handles showing success/error messages
  }

  void _handleOpenEqualizer() {
    // TODO: Navigate to equalizer screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ouvrir l\'égaliseur'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  String _getRepeatTooltip() {
    switch (_repeatMode) {
      case AudioServiceRepeatMode.none:
        return 'Répéter: Désactivé';
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        return 'Répéter: Tout';
      case AudioServiceRepeatMode.one:
        return 'Répéter: Un';
    }
  }
}
