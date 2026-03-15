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
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: Icon(Icons.headphones, color: scheme.primary),
      title: Text(
        episode.title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      subtitle: Text(
        "${episode.listens} listens",
        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
      ),
      trailing: Icon(Icons.play_arrow, color: scheme.primary),
    );
  }
}