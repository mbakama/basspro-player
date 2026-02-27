import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'dart:async';
import '../../../core/utils/format_utils.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/audio/audio_service_initializer.dart';
import '../../../domain/repositories/track_repository.dart';
import '../../../data/repositories/track_repository_impl.dart';
import '../../../data/datasources/database/database_service.dart';
import '../../../domain/entities/track.dart';
import '../../widgets/add_to_playlist_dialog.dart';
import '../../widgets/artwork_image.dart';
import 'equalizer_screen.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  final _audioHandler = AudioServiceInitializer.audioHandler;
  late final TrackRepository _trackRepository;
  
  StreamSubscription<PlaybackState>? _playbackStateSubscription;
  StreamSubscription<MediaItem?>? _mediaItemSubscription;
  Timer? _positionTimer;
  
  bool _isPlaying = false;
  bool _isShuffle = false;
  AudioServiceRepeatMode _repeatMode = AudioServiceRepeatMode.none;
  bool _isFavorite = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isDraggingSeekBar = false;
  
  MediaItem? _currentMediaItem;
  Track? _currentTrack;

  @override
  void initState() {
    super.initState();
    final databaseService = DatabaseService();
    _trackRepository = TrackRepositoryImpl(databaseService);
    _setupListeners();
  }

  @override
  void dispose() {
    _playbackStateSubscription?.cancel();
    _mediaItemSubscription?.cancel();
    _positionTimer?.cancel();
    super.dispose();
  }

  void _setupListeners() {
    if (_audioHandler == null) return;

    _playbackStateSubscription = _audioHandler!.playbackState.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.playing;
        _isShuffle = state.shuffleMode == AudioServiceShuffleMode.all;
        _repeatMode = state.repeatMode;
        if (!_isDraggingSeekBar) {
          // state.position est la position interpolée (précise à l'instant T)
          _currentPosition = state.position;
        }
      });
      // Démarrer/arrêter le timer selon l'état de lecture
      if (state.playing) {
        _startPositionTimer();
      } else {
        _stopPositionTimer();
      }
    });

    _mediaItemSubscription = _audioHandler!.mediaItem.listen((item) {
      if (mounted) {
        setState(() {
          _currentMediaItem = item;
          _totalDuration = item?.duration ?? Duration.zero;
        });
        _loadTrackFromMediaItem(item);
      }
    });
  }

  /// Démarre un timer périodique pour mettre à jour la position toutes les 500ms.
  void _startPositionTimer() {
    if (_positionTimer?.isActive == true) return; // déjà actif
    _positionTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted || _isDraggingSeekBar || _audioHandler == null) return;
      
      final state = _audioHandler!.playbackState.value;
      Duration pos = state.position;
      
      if (state.playing && state.processingState == AudioProcessingState.ready) {
        final diff = DateTime.now().difference(state.updateTime);
        pos += diff * state.speed;
      }
      
      // Clamp to total duration
      if (pos > _totalDuration) pos = _totalDuration;
      if (pos < Duration.zero) pos = Duration.zero;

      if (_currentPosition.inSeconds != pos.inSeconds) {
        setState(() {
          _currentPosition = pos;
        });
      }
    });
  }

  /// Arrête le timer de position.
  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  Future<void> _loadTrackFromMediaItem(MediaItem? item) async {
    if (item == null) {
      if (mounted) setState(() { _currentTrack = null; _isFavorite = false; });
      return;
    }
    try {
      final allTracks = await _trackRepository.getAllTracks();
      final track = allTracks.where((t) => t.uri == item.id).firstOrNull;
      if (mounted) {
        setState(() {
          _currentTrack = track;
          _isFavorite = track?.isFavorite ?? false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _currentTrack = null; _isFavorite = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! > 500) Navigator.of(context).pop();
        },
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 500) {
            _handlePrevious();
          } else if (details.primaryVelocity! < -500) {
            _handleNext();
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.darkSurface, AppColors.darkBackground],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTopBar(context),
                  const SizedBox(height: 20),
                  _buildAlbumArtwork(context),
                  const SizedBox(height: 30),
                  _buildTrackInfo(context, theme),
                  const SizedBox(height: 40),
                  _buildSeekBar(context, theme),
                  const SizedBox(height: 24),
                  _buildMainControls(context, theme),
                  const SizedBox(height: 30),
                  _buildSecondaryActions(context, theme),
                  const SizedBox(height: 24),
                ],
              ),
            ),
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
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Text(
            'Lecture en cours',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArtwork(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(_currentMediaItem?.id),
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.width * 0.7,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkPrimary.withValues(alpha: 0.1),
              blurRadius: 40,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: _currentMediaItem?.artUri != null
              ? ArtworkImage.track(
                  artworkUri: _currentMediaItem!.artUri.toString(),
                  width: 280,
                  height: 280,
                )
              : Container(
                  color: Colors.white10,
                  child: const Icon(Icons.music_note_rounded, size: 100, color: Colors.white24),
                ),
        ),
      ),
    );
  }

  Widget _buildTrackInfo(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        children: [
          Text(
            _currentMediaItem?.title ?? 'Aucune piste',
            style: theme.textTheme.displayLarge?.copyWith(fontSize: 26),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.fade,
          ),
          const SizedBox(height: 8),
          Text(
            _currentMediaItem?.artist ?? 'Artiste inconnu',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.darkPrimary.withValues(alpha: 0.8),
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSeekBar(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          SliderTheme(
            data: theme.sliderTheme.copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              activeTrackColor: AppColors.darkPrimary,
              inactiveTrackColor: Colors.white10,
            ),
            child: Slider(
              value: _currentPosition.inSeconds.toDouble().clamp(0.0, _totalDuration.inSeconds.toDouble().clamp(0.1, double.infinity)),
              min: 0.0,
              max: _totalDuration.inSeconds.toDouble().clamp(0.1, double.infinity),
              onChanged: (value) {
                setState(() {
                  _isDraggingSeekBar = true;
                  _currentPosition = Duration(seconds: value.toInt());
                });
              },
              onChangeEnd: (value) {
                setState(() { _isDraggingSeekBar = false; });
                _audioHandler?.seek(Duration(seconds: value.toInt()));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(FormatUtils.formatDuration(_currentPosition), style: theme.textTheme.labelSmall),
                Text(FormatUtils.formatDuration(_totalDuration), style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainControls(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(Icons.shuffle_rounded, color: _isShuffle ? AppColors.darkPrimary : Colors.white54),
          onPressed: _handleShuffle,
        ),
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded, size: 48),
          onPressed: _handlePrevious,
        ),
        GestureDetector(
          onTap: _handlePlayPause,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.black,
              size: 50,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.skip_next_rounded, size: 48),
          onPressed: _handleNext,
        ),
        IconButton(
          icon: Icon(
            _repeatMode == AudioServiceRepeatMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
            color: _repeatMode != AudioServiceRepeatMode.none ? AppColors.darkPrimary : Colors.white54,
          ),
          onPressed: _handleRepeat,
        ),
      ],
    );
  }

  Widget _buildSecondaryActions(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: _isFavorite ? AppColors.favoriteActive : Colors.white54),
            onPressed: _handleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.playlist_add_rounded, color: Colors.white54),
            onPressed: _handleAddToQueue,
          ),
          IconButton(
            icon: const Icon(Icons.equalizer_rounded, color: Colors.white54),
            onPressed: _handleOpenEqualizer,
          ),
        ],
      ),
    );
  }

  void _handlePlayPause() => _isPlaying ? _audioHandler?.pause() : _audioHandler?.play();
  void _handlePrevious() => _audioHandler?.skipToPrevious();
  void _handleNext() => _audioHandler?.skipToNext();
  void _handleShuffle() => _audioHandler?.setShuffleMode(_isShuffle ? AudioServiceShuffleMode.none : AudioServiceShuffleMode.all);
  void _handleRepeat() {
    AudioServiceRepeatMode newMode;
    switch (_repeatMode) {
      case AudioServiceRepeatMode.none: newMode = AudioServiceRepeatMode.all; break;
      case AudioServiceRepeatMode.all: newMode = AudioServiceRepeatMode.one; break;
      default: newMode = AudioServiceRepeatMode.none; break;
    }
    _audioHandler?.setRepeatMode(newMode);
  }

  void _handleFavorite() async {
    if (_currentTrack?.id == null) return;
    try {
      await _trackRepository.toggleFavorite(_currentTrack!.id!);
      setState(() { _isFavorite = !_isFavorite; });
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  void _handleAddToQueue() async {
    if (_currentTrack == null) return;
    await showDialog(context: context, builder: (context) => AddToPlaylistDialog(track: _currentTrack!));
  }

  void _handleOpenEqualizer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EqualizerScreen(),
    );
  }
}
