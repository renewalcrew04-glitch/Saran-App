import 'package:flutter/material.dart';
import '../services/podcast_service.dart';
import '../models/podcast_model.dart';
import '../widgets/podcast_card.dart';
import 'podcast_detail_screen.dart';

class PodcastHomeScreen extends StatefulWidget {
  const PodcastHomeScreen({super.key});

  @override
  State<PodcastHomeScreen> createState() => _PodcastHomeScreenState();
}

class _PodcastHomeScreenState extends State<PodcastHomeScreen> {

  final PodcastService service = PodcastService();
  List<PodcastModel> podcasts = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      podcasts = await service.fetchPodcasts();
    } catch (_) {}

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Podcasts"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: podcasts.length,
              itemBuilder: (_, i) {

                final podcast = podcasts[i];

                return PodcastCard(
                  podcast: podcast,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PodcastDetailScreen(podcast: podcast),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}