import 'package:flutter/material.dart';
import '../../../utils/media_utils.dart';
import '../models/podcast_model.dart';

class PodcastCard extends StatelessWidget {
  final PodcastModel podcast;
  final VoidCallback onTap;

  const PodcastCard({
    super.key,
    required this.podcast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: podcast.coverUrl.isNotEmpty
            ? SizedBox(
                width: 60,
                height: 60,
                child: safeNetworkImage(
                  url: podcast.coverUrl,
                  width: 60,
                  height: 60,
                  placeholderIcon: Icons.podcasts,
                ),
              )
            : Container(
                width: 60,
                height: 60,
                color: scheme.surfaceContainerHighest,
                child: const Icon(Icons.podcasts),
              ),
      ),
      title: Text(
        podcast.title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      subtitle: Text(
        "${podcast.totalEpisodes} episodes",
        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
      ),
    );
  }
}