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
import '../../../core/constants/app_colors.dart';
import '../../widgets/error_display.dart';
import 'stream_dialog.dart';

class StreamingScreen extends StatefulWidget {
  const StreamingScreen({super.key});

  @override
  State<StreamingScreen> createState() => _StreamingScreenState();
}

class _StreamingScreenState extends State<StreamingScreen> with AutomaticKeepAliveClientMixin {
  late final StreamRepository _repository;
  List<StreamSource> _streams = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isBuffering = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final databaseService = DatabaseService();
    _repository = StreamRepositoryImpl(databaseService);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _loadStreams();
    }
  }

  Future<void> _loadStreams() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final streams = await _repository.getAllStreamSources();
      setState(() { _streams = streams; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onStreamTap(StreamSource stream) async {
    final audioHandler = AudioServiceInitializer.audioHandler;
    if (audioHandler == null) return;

    try {
      setState(() => _isBuffering = true);
      await audioHandler.playMediaItem(MediaItem(
        id: stream.url,
        title: stream.name,
        artist: stream.category ?? 'Radio',
        extras: {'isStream': true},
      ));
      setState(() => _isBuffering = false);
    } catch (e) {
      setState(() => _isBuffering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Streaming'),
        actions: [
          IconButton(icon: const Icon(Icons.add_rounded), onPressed: () => _showAddStreamDialog()),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              if (_streams.where((s) => s.isFavorite).isNotEmpty) ...[
                _buildSectionHeader('Favoris'),
                ..._streams.where((s) => s.isFavorite).map((s) => _buildStreamCard(s, theme)),
                const SizedBox(height: 24),
              ],
              _buildSectionHeader('Toutes les sources'),
              if (_streams.isEmpty) _buildEmptyState()
              else ..._streams.map((s) => _buildStreamCard(s, theme)),
            ],
          ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
    );
  }

  Widget _buildStreamCard(StreamSource stream, ThemeData theme) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
      ),
      color: AppColors.darkSurface,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.darkPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.radio_rounded, color: AppColors.darkPrimary, size: 28),
        ),
        title: Text(stream.name, style: theme.textTheme.titleMedium),
        subtitle: stream.category != null 
          ? Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(stream.category!.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(color: AppColors.darkPrimary, letterSpacing: 1.0)),
            )
          : null,
        trailing: IconButton(
          icon: Icon(stream.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: stream.isFavorite ? AppColors.favoriteActive : Colors.white24),
          onPressed: () => _toggleFavorite(stream),
        ),
        onTap: () => _onStreamTap(stream),
        onLongPress: () => _showStreamContextMenu(context, stream),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(Icons.podcasts_rounded, size: 64, color: Colors.white10),
            const SizedBox(height: 16),
            Text('Aucune source', style: TextStyle(color: Colors.white54, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(StreamSource stream) async {
    try {
      await _repository.toggleFavorite(stream.id!);
      _loadStreams();
    } catch (e) {}
  }

  void _showStreamContextMenu(BuildContext context, StreamSource stream) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.edit_rounded), title: const Text('Modifier'), onTap: () { Navigator.pop(context); _showEditStreamDialog(stream); }),
            ListTile(leading: const Icon(Icons.delete_outline_rounded, color: Colors.red), title: const Text('Supprimer', style: TextStyle(color: Colors.red)), onTap: () { Navigator.pop(context); _confirmDeleteStream(stream); }),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteStream(StreamSource stream) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le flux'),
        content: Text('Voulez-vous vraiment supprimer "${stream.name}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(onPressed: () { Navigator.pop(context); _deleteStream(stream); }, child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Future<void> _deleteStream(StreamSource stream) async {
    try { await _repository.deleteStreamSource(stream.id!); _loadStreams(); } catch (e) {}
  }

  Future<void> _showAddStreamDialog() async {
    final result = await showDialog<bool>(context: context, builder: (context) => StreamDialog(repository: _repository));
    if (result == true) _loadStreams();
  }

  Future<void> _showEditStreamDialog(StreamSource stream) async {
    final result = await showDialog<bool>(context: context, builder: (context) => StreamDialog(repository: _repository, streamToEdit: stream));
    if (result == true) _loadStreams();
  }
}
