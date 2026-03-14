import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class PodcastMiniPlayer extends StatelessWidget {

  final AudioPlayer player;
  final String title;

  const PodcastMiniPlayer({
    super.key,
    required this.player,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {

    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 60,
      color: scheme.surfaceContainerHighest,
      child: Row(
        children: [

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          StreamBuilder<PlayerState>(
            stream: player.playerStateStream,
            builder: (_, snapshot) {

              final playing = snapshot.data?.playing ?? false;

              return IconButton(
                icon: Icon(
                  playing ? Icons.pause : Icons.play_arrow,
                ),
                onPressed: () {
                  playing ? player.pause() : player.play();
                },
              );
            },
          ),
        ],
      ),
    );
  }
}