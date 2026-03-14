import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    loadEpisodes();
  }

  Future<void> loadEpisodes() async {

    episodes = await service.fetchEpisodes(widget.podcast.id);

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.podcast.title),
      ),
      body: Column(
        children: [

          if (widget.podcast.coverUrl.isNotEmpty)
            Image.network(
              widget.podcast.coverUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(widget.podcast.description),
          ),

          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
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
          )
        ],
      ),
    );
  }
}