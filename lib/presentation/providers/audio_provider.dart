import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/audio/audio_service_initializer.dart';
import '../../data/services/audio/basspro_audio_handler.dart';

/// Provider for the global AudioHandler instance.
/// This allows the UI to interact with the background audio service.
final audioHandlerProvider = Provider<BassProAudioHandler?>((ref) {
  return AudioServiceInitializer.audioHandler;
});

/// Stream provider for the current playback state.
final playbackStateProvider = StreamProvider<PlaybackState>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  if (handler == null) return const Stream.empty();
  return handler.playbackState;
});

/// Stream provider for the currently playing media item.
final currentMediaItemProvider = StreamProvider<MediaItem?>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  if (handler == null) return const Stream.empty();
  return handler.mediaItem;
});
