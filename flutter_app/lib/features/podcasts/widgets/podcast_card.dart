import 'package:flutter/material.dart';
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

    return ListTile(
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: podcast.coverUrl.isNotEmpty
            ? Image.network(
                podcast.coverUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              )
            : const Icon(Icons.podcasts),
      ),
      title: Text(podcast.title),
      subtitle: Text("${podcast.totalEpisodes} episodes"),
    );
  }
}