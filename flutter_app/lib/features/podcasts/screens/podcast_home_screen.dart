import 'package:flutter/material.dart';
import '../services/podcast_service.dart';
import '../models/podcast_model.dart';
import '../widgets/podcast_card.dart';
import 'podcast_detail_screen.dart';
import 'create_podcast_screen.dart';

class PodcastHomeScreen extends StatefulWidget {
  const PodcastHomeScreen({super.key});

  @override
  State<PodcastHomeScreen> createState() => _PodcastHomeScreenState();
}

class _PodcastHomeScreenState extends State<PodcastHomeScreen> {
  final PodcastService service = PodcastService();
  List<PodcastModel> podcasts = [];
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });
    try {
      final list = await service.fetchPodcasts();
      if (mounted) {
        setState(() {
          podcasts = list;
          loading = false;
          errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          errorMessage = e is Exception ? e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '') : "Could not load podcasts. Pull to retry.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Podcasts"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreatePodcastScreen(),
                  ),
                );
                if (mounted) load();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: scheme.onPrimary, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      "Host",
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: errorMessage != null
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
                                  Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: scheme.error,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: scheme.onSurfaceVariant),
                                  ),
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: load,
                                    child: const Text("Retry"),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : podcasts.isEmpty
                      ? LayoutBuilder(
                          builder: (_, c) => SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: c.maxHeight,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.podcasts_outlined,
                                      size: 64,
                                      color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "No podcasts yet",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
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
            ),
    );
  }
}