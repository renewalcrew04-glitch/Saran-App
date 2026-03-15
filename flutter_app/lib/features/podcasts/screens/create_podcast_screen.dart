import 'package:flutter/material.dart';
import '../services/podcast_service.dart';

class CreatePodcastScreen extends StatefulWidget {
  const CreatePodcastScreen({super.key});

  @override
  State<CreatePodcastScreen> createState() => _CreatePodcastScreenState();
}

class _CreatePodcastScreenState extends State<CreatePodcastScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _coverUrlController = TextEditingController();
  final PodcastService _service = PodcastService();

  String _category = 'general';
  bool _loading = false;
  String? _error;

  static const List<String> _categories = [
    'general',
    'tech',
    'business',
    'health',
    'entertainment',
    'education',
    'other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _coverUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final description = _descController.text.trim();
    final coverUrl = _coverUrlController.text.trim();

    if (title.isEmpty) {
      setState(() => _error = 'Enter a title');
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      await _service.createPodcast(
        title: title,
        description: description,
        category: _category,
        coverUrl: coverUrl,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e is Exception ? e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '') : 'Could not create podcast';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Podcast'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'My Podcast',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'What your podcast is about',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((c) {
                return DropdownMenuItem(value: c, child: Text(c));
              }).toList(),
              onChanged: (v) => setState(() => _category = v ?? 'general'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _coverUrlController,
              decoration: const InputDecoration(
                labelText: 'Cover image URL (optional)',
                hintText: 'https://...',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: scheme.error, fontSize: 14),
              ),
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
                  : const Text('Create Podcast'),
            ),
          ],
        ),
      ),
    );
  }
}
