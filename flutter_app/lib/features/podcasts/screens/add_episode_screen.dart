import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/podcast_model.dart';
import '../services/podcast_service.dart';
import '../../../services/upload_service.dart';

class AddEpisodeScreen extends StatefulWidget {
  final PodcastModel podcast;

  const AddEpisodeScreen({super.key, required this.podcast});

  @override
  State<AddEpisodeScreen> createState() => _AddEpisodeScreenState();
}

class _AddEpisodeScreenState extends State<AddEpisodeScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final PodcastService _service = PodcastService();
  final UploadService _uploadService = UploadService();

  File? _audioFile;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null && mounted) {
      setState(() => _audioFile = File(result.files.single.path!));
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final description = _descController.text.trim();

    if (title.isEmpty) {
      setState(() => _error = 'Enter episode title');
      return;
    }
    if (_audioFile == null) {
      setState(() => _error = 'Pick an audio file');
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      final audioUrl = await _uploadService.uploadMedia(_audioFile!.path);
      if (!mounted) return;

      await _service.createEpisode(
        podcastId: widget.podcast.id,
        title: title,
        description: description,
        audioUrl: audioUrl,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e is Exception ? e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '') : 'Could not add episode';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Episode'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Episode title',
                hintText: 'Episode 1',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'What this episode is about',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            const Text('Audio file', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _loading ? null : _pickAudio,
              child: Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
                ),
                child: _audioFile != null
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.audiotrack, size: 32, color: scheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _audioFile!.path.split(RegExp(r'[/\\]')).last,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 13, color: scheme.onSurface),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file, size: 32, color: scheme.onSurfaceVariant),
                          const SizedBox(height: 6),
                          Text(
                            'Tap to pick audio (mp3, m4a, etc.)',
                            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: scheme.error, fontSize: 14)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add Episode'),
            ),
          ],
        ),
      ),
    );
  }
}
