import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/services/audio/audio_service_initializer.dart';
import '../screens/player/now_playing_screen.dart';

/// Mini player widget that appears at the bottom of the screen when audio is playing.
/// 
/// This widget displays:
/// - Small album artwork thumbnail
/// - Track title and artist (truncated if needed)
/// - Previous, play/pause, and next buttons
/// - Tap anywhere to expand to Now Playing screen
/// - Slide-up animation when playback starts
/// - Hides when no audio is playing
/// 
/// Requirements: 1.3, 1.4
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audioHandler = AudioServiceInitializer.audioHandler;
    
    // If audio handler is not initialized, don't show mini player
    if (audioHandler == null) {
      return const SizedBox.shrink();
    }

    // Listen to both playback state and media item
    return StreamBuilder<PlaybackState>(
      stream: audioHandler.playbackState,
      builder: (context, playbackSnapshot) {
        final playbackState = playbackSnapshot.data;
        final isPlaying = playbackState?.playing ?? false;
        final processingState = playbackState?.processingState ?? AudioProcessingState.idle;
        
        // Hide mini player when no audio is loaded or when idle
        final shouldShow = processingState != AudioProcessingState.idle &&
                          processingState != AudioProcessingState.completed;
        
        return StreamBuilder<MediaItem?>(
          stream: audioHandler.mediaItem,
          builder: (context, mediaSnapshot) {
            final mediaItem = mediaSnapshot.data;
            
            // Hide if no media item
            if (!shouldShow || mediaItem == null) {
              return const SizedBox.shrink();
            }

            // Slide-up animation when playback starts
            return AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              offset: shouldShow ? Offset.zero : const Offset(0, 1),
              curve: Curves.easeOut,
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // Navigate to Now Playing screen
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const NowPlayingScreen(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          // Album artwork
                          _buildArtwork(mediaItem),
                          const SizedBox(width: 12),
                          // Track info
                          Expanded(
                            child: _buildTrackInfo(mediaItem),
                          ),
                          // Playback controls
                          IconButton(
                            icon: const Icon(Icons.skip_previous),
                            onPressed: () => audioHandler.skipToPrevious(),
                          ),
                          IconButton(
                            icon: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                            ),
                            onPressed: () {
                              if (isPlaying) {
                                audioHandler.pause();
                              } else {
                                audioHandler.play();
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next),
                            onPressed: () => audioHandler.skipToNext(),
                          ),
                        ],
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

  /// Build album artwork widget
  Widget _buildArtwork(MediaItem mediaItem) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: mediaItem.artUri != null
            ? CachedNetworkImage(
                imageUrl: mediaItem.artUri.toString(),
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.music_note, color: Colors.grey),
                memCacheWidth: 96, // 2x for retina displays
                memCacheHeight: 96,
                maxWidthDiskCache: 150,
                maxHeightDiskCache: 150,
              )
            : const Icon(Icons.music_note, color: Colors.grey),
      ),
    );
  }

  /// Build track info widget (title and artist)
  Widget _buildTrackInfo(MediaItem mediaItem) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mediaItem.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          mediaItem.artist ?? 'Artiste inconnu',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
