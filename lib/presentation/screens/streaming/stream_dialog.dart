import 'package:flutter/material.dart';
import '../../../domain/entities/stream_source.dart';
import '../../../domain/repositories/stream_repository.dart';
import '../../../domain/usecases/stream/add_stream_source_use_case.dart';
import '../../../domain/usecases/stream/update_stream_source_use_case.dart';

/// Dialog for adding or editing a stream source.
///
/// Features:
/// - Text fields for name, URL, and optional category
/// - URL format validation (must start with http:// or https://)
/// - Name validation (non-empty)
/// - Pre-filled values for edit mode
/// - Save to database via repository
/// - French UI labels
class StreamDialog extends StatefulWidget {
  final StreamRepository repository;
  final StreamSource? streamToEdit;

  const StreamDialog({
    super.key,
    required this.repository,
    this.streamToEdit,
  });

  @override
  State<StreamDialog> createState() => _StreamDialogState();
}

class _StreamDialogState extends State<StreamDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;
  late final TextEditingController _categoryController;
  bool _isLoading = false;

  bool get _isEditMode => widget.streamToEdit != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.streamToEdit?.name ?? '',
    );
    _urlController = TextEditingController(
      text: widget.streamToEdit?.url ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.streamToEdit?.category ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le nom est requis';
    }
    return null;
  }

  String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'L\'URL est requise';
    }

    final trimmedUrl = value.trim();
    if (!trimmedUrl.startsWith('http://') &&
        !trimmedUrl.startsWith('https://')) {
      return 'L\'URL doit commencer par http:// ou https://';
    }

    try {
      Uri.parse(trimmedUrl);
    } catch (e) {
      return 'Format d\'URL invalide';
    }

    return null;
  }

  Future<void> _saveStream() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isEditMode) {
        // Update existing stream
        final updateUseCase = UpdateStreamSourceUseCase(widget.repository);
        final updatedStream = widget.streamToEdit!.copyWith(
          name: _nameController.text.trim(),
          url: _urlController.text.trim(),
          category: _categoryController.text.trim().isEmpty
              ? null
              : _categoryController.text.trim(),
        );
        await updateUseCase(updatedStream);
      } else {
        // Add new stream
        final addUseCase = AddStreamSourceUseCase(widget.repository);
        await addUseCase(
          name: _nameController.text.trim(),
          url: _urlController.text.trim(),
          category: _categoryController.text.trim().isEmpty
              ? null
              : _categoryController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditMode ? 'Modifier le flux' : 'Ajouter un flux'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du flux',
                  hintText: 'Ex: Radio Jazz FM',
                  border: OutlineInputBorder(),
                ),
                validator: _validateName,
                enabled: !_isLoading,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'URL du flux',
                  hintText: 'https://example.com/stream',
                  border: OutlineInputBorder(),
                ),
                validator: _validateUrl,
                enabled: !_isLoading,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Catégorie (optionnel)',
                  hintText: 'Ex: Jazz, Podcast, Rock',
                  border: OutlineInputBorder(),
                ),
                enabled: !_isLoading,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _saveStream(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _saveStream,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditMode ? 'Modifier' : 'Ajouter'),
        ),
      ],
    );
  }
}
