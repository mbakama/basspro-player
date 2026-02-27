import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../../data/services/audio/audio_service_initializer.dart';
import '../../core/utils/format_utils.dart';
import '../screens/player/now_playing_screen.dart';
import 'artwork_image.dart';

/// Mini player widget - Premium Glassmorphism Edition
class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  Timer? _timer;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final handler = AudioServiceInitializer.audioHandler;
      if (handler == null) return;
      
      final state = handler.playbackState.value;
      Duration newPos = state.position;
      
      if (state.playing && state.processingState == AudioProcessingState.ready) {
        final diff = DateTime.now().difference(state.updateTime);
        newPos += diff * state.speed;
      }
      
      // Don't go beyond duration if known
      final currentMedia = handler.mediaItem.value;
      if (currentMedia?.duration != null && newPos > currentMedia!.duration!) {
        newPos = currentMedia.duration!;
      }

      if (_position.inSeconds != newPos.inSeconds) {
        if (mounted) {
          setState(() {
            _position = newPos;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final audioHandler = AudioServiceInitializer.audioHandler;
    final theme = Theme.of(context);
    
    if (audioHandler == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      initialData: audioHandler.mediaItem.value,
      builder: (context, mediaSnapshot) {
        final mediaItem = mediaSnapshot.data;

        if (mediaItem == null) {
          return const SizedBox.shrink();
        }

        final total = mediaItem.duration ?? Duration.zero;

        return StreamBuilder<PlaybackState>(
          stream: audioHandler.playbackState,
          initialData: audioHandler.playbackState.value,
          builder: (context, playbackSnapshot) {
            final playbackState = playbackSnapshot.data;
            final isPlaying = playbackState?.playing ?? false;

            return Container(
              key: const ValueKey('mini_player_container'),
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 72,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const NowPlayingScreen()),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Row(
                            children: [
                              _buildArtwork(mediaItem),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTrackInfo(mediaItem, theme, _position, total),
                              ),
                              IconButton(
                                icon: const Icon(Icons.skip_previous_rounded),
                                onPressed: () => audioHandler.skipToPrevious(),
                              ),
                              _buildPlayPauseButton(audioHandler, isPlaying, theme),
                              IconButton(
                                icon: const Icon(Icons.skip_next_rounded),
                                onPressed: () => audioHandler.skipToNext(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlayPauseButton(dynamic audioHandler, bool isPlaying, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: theme.colorScheme.primary,
        ),
        onPressed: () => isPlaying ? audioHandler.pause() : audioHandler.play(),
      ),
    );
  }

  Widget _buildArtwork(MediaItem mediaItem) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ArtworkImage.track(
          artworkUri: mediaItem.artUri?.toString(),
          width: 44,
          height: 44,
        ),
      ),
    );
  }

  Widget _buildTrackInfo(
    MediaItem mediaItem,
    ThemeData theme,
    Duration position,
    Duration total,
  ) {
    final positionStr = FormatUtils.formatDuration(position);
    final totalStr = FormatUtils.formatDuration(total);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mediaItem.title,
          style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          mediaItem.artist ?? 'Artiste inconnu',
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '$positionStr / $totalStr',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
