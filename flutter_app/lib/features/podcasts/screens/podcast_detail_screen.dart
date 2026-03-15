import 'package:flutter/material.dart';
import '../../../utils/media_utils.dart';
import '../models/podcast_model.dart';
import '../models/episode_model.dart';
import '../services/podcast_service.dart';
import '../widgets/episode_tile.dart';
import 'episode_player_screen.dart';

class PodcastDetailScreen extends StatefulWidget {
  final PodcastModel podcast;

  const PodcastDetailScreen({super.key, required this.podcast});

  @override
  State<PodcastDetailScreen> createState() => _PodcastDetailScreenState();
}

class _PodcastDetailScreenState extends State<PodcastDetailScreen> {
  final PodcastService service = PodcastService();

  List<EpisodeModel> episodes = [];
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadEpisodes();
  }

  Future<void> loadEpisodes() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });
    try {
      final list = await service.fetchEpisodes(widget.podcast.id);
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.podcast.title,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          if (widget.podcast.coverUrl.isNotEmpty)
            SizedBox(
              height: 200,
              width: double.infinity,
              child: safeNetworkImage(
                url: widget.podcast.coverUrl,
                height: 200,
                fit: BoxFit.cover,
                placeholderIcon: Icons.podcasts,
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.podcast.description,
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