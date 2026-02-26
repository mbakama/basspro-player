import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../../../domain/entities/stream_source.dart';
import '../../../domain/repositories/stream_repository.dart';
import '../../../data/repositories/stream_repository_impl.dart';
import '../../../data/datasources/database/database_service.dart';
import '../../../data/services/audio/audio_service_initializer.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/retry_handler.dart';
import '../../../core/errors/app_error.dart';
import '../../widgets/error_display.dart';
import 'stream_dialog.dart';

/// Streaming screen displaying online audio stream sources.
/// 
/// Features:
/// - Recently Played section with recent streams
/// - All Sources section with all stream sources
/// - Stream name, category, and favorite icon display
/// - Tap to play stream functionality (placeholder)
/// - Long-press context menu for edit/delete actions
/// - Add button to create new stream sources
class StreamingScreen extends StatefulWidget {
  const StreamingScreen({super.key});

  @override
  State<StreamingScreen> createState() => _StreamingScreenState();
}

class _StreamingScreenState extends State<StreamingScreen>
    with AutomaticKeepAliveClientMixin {
  late final StreamRepository _repository;
  List<StreamSource> _streams = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isBuffering = false;
  static const _logger = AppLoggers.audio;

  @override
  bool get wantKeepAlive => true; // Keep state when switching tabs

  @override
  void initState() {
    super.initState();
    // Initialize repository but don't load data yet
    final databaseService = DatabaseService();
    _repository = StreamRepositoryImpl(databaseService);
    // Data will be loaded when widget is first built (lazy loading)
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load streams lazily when screen is first displayed
    if (!_isInitialized) {
      _isInitialized = true;
      _loadStreams();
    }
  }

  Future<void> _loadStreams() async {
    if (_isLoading) return; // Prevent duplicate loads
    
    setState(() {
      _isLoading = true;
    });

    try {
      final streams = await _repository.getAllStreamSources();
      setState(() {
        _streams = streams;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      ErrorHandler.handle(e, stackTrace, 'StreamingScreen._loadStreams');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        showErrorSnackBar(context, e, onRetry: _loadStreams);
      }
    }
  }

  List<StreamSource> get _recentlyPlayedStreams {
    return _streams
        .where((stream) => stream.lastPlayedAt != null)
        .toList()
      ..sort((a, b) => b.lastPlayedAt!.compareTo(a.lastPlayedAt!));
  }

  List<StreamSource> get _allStreams {
    return List<StreamSource>.from(_streams)
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> _onStreamTap(StreamSource stream) async {
    final audioHandler = AudioServiceInitializer.audioHandler;
    
    if (audioHandler == null) {
      _logger.error('Audio handler not initialized');
      if (mounted) {
        final error = AudioError.initializationFailed('Service audio non disponible');
        showErrorSnackBar(context, error);
      }
      return;
    }

    try {
      _logger.info('Starting stream playback: ${stream.name} (${stream.url})');
      
      // Show buffering indicator
      setState(() {
        _isBuffering = true;
      });

      // Use retry handler with exponential backoff for stream connection
      await RetryHandler.retryStream(
        streamUrl: stream.url,
        connectFunction: () async {
          // Create MediaItem for the stream
          final mediaItem = MediaItem(
            id: stream.url,
            title: stream.name,
            artist: stream.category ?? 'Streaming',
            artUri: null, // No artwork for streams
            extras: {
              'streamId': stream.id,
              'isStream': true,
            },
          );

          // Set the stream as the queue and start playback
          await audioHandler.setQueue([mediaItem]);
          await audioHandler.play();
          
          return true;
        },
        maxAttempts: 5, // Try up to 5 times for streams
        onRetry: (attempt, delay) {
          _logger.info('Retrying stream connection (attempt $attempt) after ${delay.inSeconds}s');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Reconnexion... (tentative $attempt)'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
      );

      // Record stream playback in history
      await _repository.updateLastPlayed(stream.id!);
      
      // Reload streams to update recently played section
      await _loadStreams();

      // Hide buffering indicator after a short delay
      // (the audio handler will show its own buffering state)
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        setState(() {
          _isBuffering = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lecture de "${stream.name}"'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      _logger.info('Stream playback started successfully');
    } catch (e, stackTrace) {
      ErrorHandler.handle(e, stackTrace, 'StreamingScreen._onStreamTap');
      
      if (mounted) {
        setState(() {
          _isBuffering = false;
        });
        
        // Determine error type and create appropriate error
        Object displayError = e;
        if (e.toString().contains('SocketException') || 
            e.toString().contains('NetworkException')) {
          displayError = NetworkError.streamUnreachable(stream.url);
        } else if (e.toString().contains('TimeoutException')) {
          displayError = NetworkError.timeout();
        } else if (e.toString().contains('FormatException')) {
          displayError = NetworkError.invalidUrl(stream.url);
        }
        
        // Show error dialog with retry option and track name
        showErrorDialog(
          context,
          displayError,
          title: 'Erreur de lecture',
          onRetry: () => _onStreamTap(stream),
        );
        
        // Also show snackbar with stream name
        showErrorSnackBar(
          context,
          displayError,
          trackName: stream.name,
          onRetry: () => _onStreamTap(stream),
        );
      }
    }
  }

  void _showStreamContextMenu(BuildContext context, StreamSource stream) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Modifier'),
              onTap: () {
                Navigator.pop(context);
                _showEditStreamDialog(stream);
              },
            ),
            ListTile(
              leading: Icon(
                stream.isFavorite ? Icons.favorite : Icons.favorite_border,
              ),
              title: Text(
                stream.isFavorite
                    ? 'Retirer des favoris'
                    : 'Ajouter aux favoris',
              ),
              onTap: () async {
                Navigator.pop(context);
                await _toggleFavorite(stream);
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
                _confirmDeleteStream(stream);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(StreamSource stream) async {
    try {
      await _repository.toggleFavorite(stream.id!);
      await _loadStreams();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              stream.isFavorite
                  ? 'Retiré des favoris'
                  : 'Ajouté aux favoris',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      ErrorHandler.handle(e, stackTrace, 'StreamingScreen._toggleFavorite');
      if (mounted) {
        showErrorSnackBar(context, e);
      }
    }
  }

  void _confirmDeleteStream(StreamSource stream) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le flux'),
        content: Text(
          'Voulez-vous vraiment supprimer "${stream.name}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteStream(stream);
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

  Future<void> _deleteStream(StreamSource stream) async {
    try {
      await _repository.deleteStreamSource(stream.id!);
      await _loadStreams();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flux supprimé'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      ErrorHandler.handle(e, stackTrace, 'StreamingScreen._deleteStream');
      if (mounted) {
        showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _showAddStreamDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StreamDialog(repository: _repository),
    );

    if (result == true) {
      await _loadStreams();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flux ajouté avec succès'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _showEditStreamDialog(StreamSource stream) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StreamDialog(
        repository: _repository,
        streamToEdit: stream,
      ),
    );

    if (result == true) {
      await _loadStreams();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flux modifié avec succès'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _onAddStream() {
    _showAddStreamDialog();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Streaming'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _onAddStream,
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Chargement des sources...',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView(
                  children: [
                    // Recently Played section
                    if (_recentlyPlayedStreams.isNotEmpty) ...[
                      _buildSectionHeader('Récemment écoutés'),
                      ..._recentlyPlayedStreams
                          .map((stream) => _buildStreamItem(stream)),
                      const Divider(height: 32),
                    ],
                    // All Sources section
                    _buildSectionHeader('Toutes les sources'),
                    if (_allStreams.isEmpty)
                      _buildEmptyState()
                    else
                      ..._allStreams.map((stream) => _buildStreamItem(stream)),
                  ],
                ),
          // Buffering overlay
          if (_isBuffering)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Connexion au flux...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

  Widget _buildStreamItem(StreamSource stream) {
    return InkWell(
      onTap: () => _onStreamTap(stream),
      onLongPress: () => _showStreamContextMenu(context, stream),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Stream icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.radio,
                size: 32,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            // Stream info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          stream.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (stream.isFavorite) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.favorite,
                          size: 20,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (stream.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        stream.category!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.radio, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Aucune source de streaming',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ajoutez des flux radio ou podcasts',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
