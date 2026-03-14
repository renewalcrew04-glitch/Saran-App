import 'package:flutter/material.dart';
import '../models/episode_model.dart';

class EpisodeTile extends StatelessWidget {

  final EpisodeModel episode;
  final VoidCallback onTap;

  const EpisodeTile({
    super.key,
    required this.episode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return ListTile(
      onTap: onTap,
      leading: const Icon(Icons.headphones),
      title: Text(episode.title),
      subtitle: Text("${episode.listens} listens"),
      trailing: const Icon(Icons.play_arrow),
    );
  }
}