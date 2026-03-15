import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/podcast_model.dart';
import '../services/podcast_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/media_utils.dart';
import 'podcast_detail_screen.dart';

/// Lists podcasts created by the current user (creatorId == currentUser.uid), in 2-column grid.
class MyPodcastsScreen extends StatefulWidget {
  const MyPodcastsScreen({super.key});

  @override
  State<MyPodcastsScreen> createState() => _MyPodcastsScreenState();
}

class _MyPodcastsScreenState extends State<MyPodcastsScreen> {
  final PodcastService _service = PodcastService();
  List<PodcastModel> _podcasts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.fetchPodcasts();
      if (!mounted) return;
      final uid = context.read<AuthProvider>().user?.uid;
      final mine = uid != null
          ? list.where((p) => p.creatorId == uid).toList()
          : <PodcastModel>[];
      setState(() {
        _podcasts = mine;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e is Exception ? e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '') : 'Could not load.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Podcasts'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _error != null
                  ? LayoutBuilder(
                      builder: (_, c) => SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: c.maxHeight,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline, size: 48, color: scheme.error),
                                  const SizedBox(height: 16),
                                  Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
                                  const SizedBox(height: 16),
                                  TextButton(onPressed: _load, child: const Text('Retry')),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : _podcasts.isEmpty
                      ? LayoutBuilder(
                          builder: (_, c) => SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: c.maxHeight,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.podcasts_outlined, size: 64, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
                                    const SizedBox(height: 16),
                                    Text(
                                      'You haven\'t created any podcasts yet',
                                      style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _podcasts.length,
                          itemBuilder: (_, i) {
                            final podcast = _podcasts[i];
                            return _PodcastGridCard(
                              podcast: podcast,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PodcastDetailScreen(podcast: podcast),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
    );
  }
}

class _PodcastGridCard extends StatelessWidget {
  final PodcastModel podcast;
  final VoidCallback onTap;

  const _PodcastGridCard({required this.podcast, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: podcast.coverUrl.isNotEmpty
                    ? safeNetworkImage(
                        url: podcast.coverUrl,
                        fit: BoxFit.cover,
                        placeholderIcon: Icons.podcasts,
                      )
                    : Container(
                        color: scheme.surfaceContainerHighest,
                        child: const Icon(Icons.podcasts, size: 48),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    podcast.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${podcast.totalEpisodes} episodes',
                    style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
