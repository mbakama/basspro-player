import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../equalizer_service.dart';
import '../../../core/utils/logger.dart';
import '../../../core/errors/app_error.dart';

/// Audio handler for BassPro Player that extends BaseAudioHandler
/// to enable background playback and system integration.
///
/// This handler manages:
/// - Audio playback using just_audio's AudioPlayer
/// - Equalizer integration for audio processing
/// - Playback state broadcasting to UI
/// - Media controls (play, pause, skip, seek)
/// - Shuffle and repeat modes
/// - Audio focus handling and interruptions
/// - Background playback with notification controls
///
/// The handler integrates with Android's MediaSession to provide:
/// - Lock screen controls
/// - Notification area controls
/// - Headphone/Bluetooth button support
class BassProAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player;
  final EqualizerService _equalizerService;
  static const _logger = AppLoggers.audio;

  // Subscriptions for cleanup
  final List<StreamSubscription> _subscriptions = [];

  // Current playback state
  bool _isShuffleEnabled = false;
  LoopMode _repeatMode = LoopMode.off;

  /// Get the equalizer service for audio processing controls
  EqualizerService get equalizerService => _equalizerService;

  BassProAudioHandler(this._player, this._equalizerService) {
    _init();
  }

  /// Initialize the audio handler and set up listeners
  void _init() {
    _logger.info('Initializing BassProAudioHandler');

    // Listen to player state changes
    _subscriptions.add(
      _player.playerStateStream.listen(
        _handlePlayerStateChange,
        onError: _handlePlayerError,
      ),
    );

    // Listen to position changes
    _subscriptions.add(
      _player.positionStream.listen(_handlePositionChange),
    );

    // Listen to current index changes (for queue navigation)
    _subscriptions.add(
      _player.currentIndexStream.listen(_handleCurrentIndexChange),
    );

    // Listen to sequence state changes (for queue updates)
    _subscriptions.add(
      _player.sequenceStateStream.listen(_handleSequenceStateChange),
    );

    // Listen to duration changes
    _subscriptions.add(
      _player.durationStream.listen(_handleDurationChange),
    );

    // Initialize playback state
    _updatePlaybackState();

    _logger.info('BassProAudioHandler initialized');
  }

  /// Handle player errors (corrupted files, unsupported formats, etc.)
  void _handlePlayerError(Object error, StackTrace stackTrace) {
    debugPrint('BassProAudioHandler: PLAYER ERROR: $error');
    _logger.error('Player error occurred', error, stackTrace);
    
    // Get current track name for error notification
    final currentItem = mediaItem.value;
    final trackName = currentItem?.title ?? 'Piste inconnue';
    
    // Determine error type and handle accordingly
    String errorMessage = 'Erreur de lecture';
    
    if (error.toString().contains('Unable to extract metadata')) {
      errorMessage = 'Fichier audio corrompu';
    } else if (error.toString().contains('Unsupported')) {
      errorMessage = 'Format audio non pris en charge';
    } else if (error.toString().contains('FileNotFoundException') || 
               error.toString().contains('No such file')) {
      errorMessage = 'Fichier audio introuvable';
    } else if (error.toString().contains('NetworkException') ||
               error.toString().contains('SocketException')) {
      errorMessage = 'Erreur de connexion réseau';
    }
    
    // Include track name in error message
    final fullErrorMessage = '$errorMessage\nPiste: $trackName';
    
    // Update playback state to show error
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
        errorMessage: fullErrorMessage,
      ),
    );
    
    // Try to skip to next track if available
    if (_player.hasNext) {
      _logger.info('Skipping to next track due to playback error: $trackName');
      skipToNext().catchError((e) {
        _logger.error('Failed to skip to next track after error', e);
      });
    } else {
      _logger.warning('No next track available after error on: $trackName');
    }
  }

  /// Handle player state changes and broadcast to UI
  void _handlePlayerStateChange(PlayerState state) {
    debugPrint('BassProAudioHandler: Player state changed: ${state.processingState}, playing: ${state.playing}');
    _logger.debug('Player state changed: ${state.processingState}, playing: ${state.playing}');
    _updatePlaybackState();
  }

  /// Handle position changes
  void _handlePositionChange(Duration position) {
    // Position updates are handled by playbackState stream
    // This is just for logging if needed
  }

  /// Handle current index changes (track changes)
  void _handleCurrentIndexChange(int? index) {
    if (index != null) {
      _logger.debug('Current track index changed to: $index');
      _updateMediaItem();
    }
  }

  /// Handle sequence state changes (queue changes)
  void _handleSequenceStateChange(SequenceState? state) {
    if (state != null) {
      _logger.debug('Sequence state changed, current index: ${state.currentIndex}');
      _updateQueue();
    }
  }

  /// Handle duration changes
  void _handleDurationChange(Duration? duration) {
    if (duration != null) {
      _logger.debug('Duration changed: $duration');
      _updatePlaybackState();
    }
  }

  /// Apply equalizer settings to the audio player
  /// This should be called when equalizer settings change
  Future<void> applyEqualizerSettings() async {
    try {
      _logger.debug('Applying equalizer settings to audio player');
      // The equalizer service is already connected to the player
      // This method can be used to trigger equalizer updates if needed
    } catch (e) {
      _logger.error('Failed to apply equalizer settings', e);
    }
  }

  /// Update and broadcast the current playback state
  void _updatePlaybackState() {
    final playerState = _player.playerState;
    final position = _player.position;

    // Determine processing state
    final processingState = _getProcessingState(playerState.processingState);

    // Determine available controls based on state
    final controls = _getAvailableControls(playerState.playing);

    // Create playback state
    playbackState.add(
      PlaybackState(
        controls: controls,
        systemActions: {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: processingState,
        playing: playerState.playing,
        updatePosition: position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _player.currentIndex,
        shuffleMode: _isShuffleEnabled
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        repeatMode: _getAudioServiceRepeatMode(_repeatMode),
      ),
    );
  }

  /// Convert just_audio ProcessingState to audio_service AudioProcessingState
  AudioProcessingState _getProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  /// Get available media controls based on playback state
  List<MediaControl> _getAvailableControls(bool isPlaying) {
    return [
      MediaControl.skipToPrevious,
      if (isPlaying) MediaControl.pause else MediaControl.play,
      MediaControl.skipToNext,
      MediaControl.stop,
    ];
  }

  /// Convert just_audio LoopMode to audio_service AudioServiceRepeatMode
  AudioServiceRepeatMode _getAudioServiceRepeatMode(LoopMode mode) {
    switch (mode) {
      case LoopMode.off:
        return AudioServiceRepeatMode.none;
      case LoopMode.all:
        return AudioServiceRepeatMode.all;
      case LoopMode.one:
        return AudioServiceRepeatMode.one;
    }
  }

  /// Update the current media item
  void _updateMediaItem() {
    final currentIndex = _player.currentIndex;
    if (currentIndex != null && currentIndex < queue.value.length) {
      mediaItem.add(queue.value[currentIndex]);
    }
  }

  /// Update the queue
  void _updateQueue() {
    final sequence = _player.sequence;
    if (sequence != null) {
      final items = sequence.map((source) {
        // Extract MediaItem from the audio source tag
        if (source.tag is MediaItem) {
          return source.tag as MediaItem;
        }
        // Fallback if tag is not a MediaItem
        return MediaItem(
          id: source.toString(),
          title: 'Unknown',
        );
      }).toList();

      queue.add(items);
    }
  }

  // ========== Playback Control Methods ==========

  @override
  Future<void> play() async {
    try {
      _logger.info('Play requested');
      debugPrint('BassProAudioHandler: play() called');
      await _player.play();
      _updatePlaybackState();
    } catch (e) {
      _logger.error('Failed to play', e);
      throw AudioError.playbackFailed('Failed to play: $e');
    }
  }

  @override
  Future<void> pause() async {
    try {
      _logger.info('Pause requested');
      await _player.pause();
      _updatePlaybackState();
    } catch (e) {
      _logger.error('Failed to pause', e);
      throw AudioError.playbackFailed('Failed to pause: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      _logger.info('Stop requested');
      await _player.stop();
      _updatePlaybackState();
    } catch (e) {
      _logger.error('Failed to stop', e);
      throw AudioError.playbackFailed('Failed to stop: $e');
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      _logger.debug('Seek requested to: $position');
      await _player.seek(position);
      _updatePlaybackState();
    } catch (e) {
      _logger.error('Failed to seek', e);
      throw AudioError.playbackFailed('Failed to seek: $e');
    }
  }

  @override
  Future<void> skipToNext() async {
    try {
      _logger.info('Skip to next requested');
      if (_player.hasNext) {
        await _player.seekToNext();
        _updatePlaybackState();
        _updateMediaItem();
      } else {
        _logger.warning('No next track available');
      }
    } catch (e) {
      _logger.error('Failed to skip to next', e);
      throw AudioError.playbackFailed('Failed to skip to next: $e');
    }
  }

  @override
  Future<void> skipToPrevious() async {
    try {
      _logger.info('Skip to previous requested');
      
      // If we're more than 3 seconds into the track, restart it
      if (_player.position.inSeconds > 3) {
        await _player.seek(Duration.zero);
      } else if (_player.hasPrevious) {
        await _player.seekToPrevious();
      } else {
        // Restart current track if no previous track
        await _player.seek(Duration.zero);
      }
      
      _updatePlaybackState();
      _updateMediaItem();
    } catch (e) {
      _logger.error('Failed to skip to previous', e);
      throw AudioError.playbackFailed('Failed to skip to previous: $e');
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    try {
      debugPrint('BassProAudioHandler: skipToQueueItem($index) requested');
      if (index >= 0 && index < (_player.sequence?.length ?? 0)) {
        await _player.seek(Duration.zero, index: index);
        _updatePlaybackState();
        _updateMediaItem();
        debugPrint('BassProAudioHandler: Skip to $index successful');
      } else {
        debugPrint('BassProAudioHandler: Invalid queue index: $index (Queue length: ${_player.sequence?.length})');
        _logger.warning('Invalid queue index: $index');
      }
    } catch (e) {
      _logger.error('Failed to skip to queue item', e);
      throw AudioError.playbackFailed('Failed to skip to queue item: $e');
    }
  }

  // ========== Shuffle and Repeat Mode Methods ==========

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    try {
      final enabled = shuffleMode == AudioServiceShuffleMode.all;
      _logger.info('Set shuffle mode: $enabled');
      
      _isShuffleEnabled = enabled;
      await _player.setShuffleModeEnabled(enabled);
      
      _updatePlaybackState();
    } catch (e) {
      _logger.error('Failed to set shuffle mode', e);
      throw AudioError.playbackFailed('Failed to set shuffle mode: $e');
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    try {
      _logger.info('Set repeat mode: $repeatMode');
      
      final loopMode = _getLoopMode(repeatMode);
      _repeatMode = loopMode;
      await _player.setLoopMode(loopMode);
      
      _updatePlaybackState();
    } catch (e) {
      _logger.error('Failed to set repeat mode', e);
      throw AudioError.playbackFailed('Failed to set repeat mode: $e');
    }
  }

  /// Convert audio_service AudioServiceRepeatMode to just_audio LoopMode
  LoopMode _getLoopMode(AudioServiceRepeatMode mode) {
    switch (mode) {
      case AudioServiceRepeatMode.none:
        return LoopMode.off;
      case AudioServiceRepeatMode.all:
        return LoopMode.all;
      case AudioServiceRepeatMode.one:
        return LoopMode.one;
      case AudioServiceRepeatMode.group:
        return LoopMode.all; // Treat group as all
    }
  }

  // ========== Queue Management Methods ==========

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    try {
      _logger.info('Add queue item: ${mediaItem.title}');
      
      final audioSource = _createAudioSource(mediaItem);
      
      // Get the current playlist
      final playlist = _player.audioSource;
      if (playlist is ConcatenatingAudioSource) {
        await playlist.add(audioSource);
        _updateQueue();
      } else {
        _logger.warning('Cannot add to queue: audio source is not a playlist');
      }
    } catch (e) {
      _logger.error('Failed to add queue item', e);
      throw AudioError.playbackFailed('Failed to add queue item: $e');
    }
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    try {
      _logger.info('Add ${mediaItems.length} queue items');
      
      final audioSources = mediaItems.map(_createAudioSource).toList();
      
      // Get the current playlist
      final playlist = _player.audioSource;
      if (playlist is ConcatenatingAudioSource) {
        await playlist.addAll(audioSources);
        _updateQueue();
      } else {
        _logger.warning('Cannot add to queue: audio source is not a playlist');
      }
    } catch (e) {
      _logger.error('Failed to add queue items', e);
      throw AudioError.playbackFailed('Failed to add queue items: $e');
    }
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    try {
      _logger.info('Remove queue item at index: $index');
      
      final playlist = _player.audioSource;
      if (playlist is ConcatenatingAudioSource) {
        if (index >= 0 && index < playlist.length) {
          await playlist.removeAt(index);
          _updateQueue();
        } else {
          _logger.warning('Invalid queue index: $index');
        }
      } else {
        _logger.warning('Cannot remove from queue: audio source is not a playlist');
      }
    } catch (e) {
      _logger.error('Failed to remove queue item', e);
      throw AudioError.playbackFailed('Failed to remove queue item: $e');
    }
  }

  /// Set the entire queue with a list of media items
  /// This replaces the current queue with the new items
  Future<void> setQueue(List<MediaItem> mediaItems) async {
    try {
      _logger.info('Set queue with ${mediaItems.length} items');
      debugPrint('BassProAudioHandler: setQueue called with ${mediaItems.length} items');
      
      // Create audio sources from media items
      final audioSources = mediaItems.map(_createAudioSource).toList();
      
      // Create a new concatenating audio source
      final playlist = ConcatenatingAudioSource(
        children: audioSources,
        useLazyPreparation: true,
      );
      
      // Set the audio source on the player
      await _player.setAudioSource(playlist);
      
      // Update queue and media item
      _updateQueue();
      _updateMediaItem();
      _updatePlaybackState();
    } catch (e) {
      _logger.error('Failed to set queue', e);
      throw AudioError.playbackFailed('Failed to set queue: $e');
    }
  }

  /// Clear all items from the queue
  Future<void> clearQueue() async {
    try {
      _logger.info('Clear queue requested');
      
      final playlist = _player.audioSource;
      if (playlist is ConcatenatingAudioSource) {
        await playlist.clear();
        _updateQueue();
        _updatePlaybackState();
      } else {
        _logger.warning('Cannot clear queue: audio source is not a playlist');
      }
    } catch (e) {
      _logger.error('Failed to clear queue', e);
      throw AudioError.playbackFailed('Failed to clear queue: $e');
    }
  }

  /// Reorder a queue item from one index to another
  /// This is useful for drag-and-drop functionality
  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    try {
      _logger.info('Reorder queue item from $oldIndex to $newIndex');
      
      final playlist = _player.audioSource;
      if (playlist is ConcatenatingAudioSource) {
        if (oldIndex >= 0 && oldIndex < playlist.length &&
            newIndex >= 0 && newIndex < playlist.length) {
          await playlist.move(oldIndex, newIndex);
          _updateQueue();
        } else {
          _logger.warning('Invalid queue indices: oldIndex=$oldIndex, newIndex=$newIndex');
        }
      } else {
        _logger.warning('Cannot reorder queue: audio source is not a playlist');
      }
    } catch (e) {
      _logger.error('Failed to reorder queue', e);
      throw AudioError.playbackFailed('Failed to reorder queue: $e');
    }
  }

  /// Create an audio source from a media item
  AudioSource _createAudioSource(MediaItem mediaItem) {
    debugPrint('BassProAudioHandler: Creating AudioSource for "${mediaItem.title}" (ID/URI: ${mediaItem.id})');
    final uri = Uri.parse(mediaItem.id);
    
    // Check if it's a local file or streaming URL
    if (uri.scheme == 'file' || uri.scheme == 'content') {
      // Local file
      return AudioSource.uri(uri, tag: mediaItem);
    } else if (uri.scheme == 'http' || uri.scheme == 'https') {
      // Streaming URL
      return AudioSource.uri(uri, tag: mediaItem);
    } else {
      // Fallback to treating as URI
      return AudioSource.uri(uri, tag: mediaItem);
    }
  }

  // ========== Audio Focus Handling ==========

  @override
  Future<void> onTaskRemoved() async {
    try {
      _logger.info('Task removed, stopping playback');
      await stop();
    } catch (e) {
      _logger.error('Error handling task removed', e);
    }
  }

  // Audio focus is automatically handled by audio_service
  // The system will pause/duck audio as needed based on other apps

  // ========== Cleanup ==========

  /// Dispose resources and clean up
  Future<void> dispose() async {
    _logger.info('Disposing BassProAudioHandler');
    
    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    
    // Stop playback
    await _player.stop();
    
    _logger.info('BassProAudioHandler disposed');
  }
}
