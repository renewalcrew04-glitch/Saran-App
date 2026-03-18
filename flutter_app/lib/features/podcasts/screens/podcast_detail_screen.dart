import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/media_utils.dart';
import '../models/podcast_model.dart';
import '../models/episode_model.dart';
import '../services/podcast_service.dart';
import '../widgets/episode_tile.dart';
import 'episode_player_screen.dart';
import 'add_episode_screen.dart';

class PodcastDetailScreen extends StatefulWidget {
  final PodcastModel podcast;

  const PodcastDetailScreen({super.key, required this.podcast});

  @override
  State<PodcastDetailScreen> createState() => _PodcastDetailScreenState();
}

class _PodcastDetailScreenState extends State<PodcastDetailScreen> {
  final PodcastService service = PodcastService();

  late PodcastModel _podcast;
  List<EpisodeModel> episodes = [];
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _podcast = widget.podcast;
    loadEpisodes();
  }

  Future<void> loadEpisodes() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });
    try {
      final list = await service.fetchEpisodes(_podcast.id);
      if (mounted) {
        setState(() {
          episodes = list;
          loading = false;
          errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          errorMessage = "Could not load episodes.";
        });
      }
    }
  }

  Future<void> _deletePodcast() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete podcast?'),
        content: Text(
          '“${widget.podcast.title}” and all its episodes will be permanently deleted. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await service.deletePodcast(_podcast.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Podcast deleted')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final msg = _podcastError(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  static String _podcastError(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      final data = e.response?.data;
      final serverMsg = data is Map ? data['message']?.toString() : null;
      if (serverMsg != null && serverMsg.isNotEmpty) return serverMsg;
      if (code == 404) return 'Podcast not found.';
      if (code == 403) return 'Not authorized.';
      if (code == 500) return 'Server error. Try again later.';
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
        return 'No connection. Try again.';
      }
    }
    final s = e.toString().replaceFirst('Exception: ', '');
    return s.length > 60 ? 'Something went wrong. Try again.' : s;
  }

  Future<void> _showEditDialog() async {
    final titleController = TextEditingController(text: _podcast.title);
    final descController = TextEditingController(text: _podcast.description);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit podcast'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved != true || !mounted) return;
    try {
      final updated = await service.updatePodcast(
        _podcast.id,
        title: titleController.text.trim(),
        description: descController.text.trim(),
      );
      if (mounted) setState(() => _podcast = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Podcast updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = _podcastError(e);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    final isCreator = _podcast.creatorId != null &&
        auth.user?.uid != null &&
        _podcast.creatorId == auth.user!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _podcast.title,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (isCreator) ...[
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Add episode',
              onPressed: () async {
                final added = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEpisodeScreen(podcast: _podcast),
                  ),
                );
                if (added == true && mounted) loadEpisodes();
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'More',
              onSelected: (value) {
                if (value == 'edit') _showEditDialog();
                if (value == 'delete') _deletePodcast();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 22), SizedBox(width: 12), Text('Edit')])),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 22), SizedBox(width: 12), Text('Delete')])),
              ],
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          if (_podcast.coverUrl.isNotEmpty)
            SizedBox(
              height: 200,
              width: double.infinity,
              child: safeNetworkImage(
                url: _podcast.coverUrl,
                height: 200,
                fit: BoxFit.cover,
                placeholderIcon: Icons.podcasts,
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _podcast.description,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),

          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: scheme.error),
                              const SizedBox(height: 16),
                              Text(
                                errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: scheme.onSurfaceVariant),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: loadEpisodes,
                                child: const Text("Retry"),
                              ),
                            ],
                          ),
                        ),
                      )
                    : episodes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.headphones_outlined,
                                  size: 64,
                                  color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No episodes yet",
                                  style: TextStyle(color: scheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: episodes.length,
                            itemBuilder: (_, i) {
                              final episode = episodes[i];
                              return EpisodeTile(
                                episode: episode,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EpisodePlayerScreen(episode: episode),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}