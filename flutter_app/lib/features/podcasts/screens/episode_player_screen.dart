import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/episode_model.dart';

class EpisodePlayerScreen extends StatefulWidget {
  final EpisodeModel episode;

  const EpisodePlayerScreen({super.key, required this.episode});

  @override
  State<EpisodePlayerScreen> createState() => _EpisodePlayerScreenState();
}

class _EpisodePlayerScreenState extends State<EpisodePlayerScreen> {
  final AudioPlayer player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    player.setUrl(widget.episode.audioUrl);
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  String format(Duration d) {
    return "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.episode.title)),
      body: Column(
        children: [
          const SizedBox(height: 30),

          if (widget.episode.coverUrl.isNotEmpty)
          Image.network(widget.episode.coverUrl, height: 250, fit: BoxFit.cover,),

          const SizedBox(height: 30),

          Text(
            widget.episode.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 30),

          StreamBuilder<Duration>(
            stream: player.positionStream,
            builder: (_, snapshot) {
              final position = snapshot.data ?? Duration.zero;

              return StreamBuilder<Duration?>(
                stream: player.durationStream,
                builder: (_, snap2) {
                  final duration = snap2.data ?? Duration.zero;

                  return Column(
                    children: [
                      Slider(
                        value: position.inSeconds.toDouble(),
                        max: duration.inSeconds.toDouble(),
                        onChanged: (v) {
                          player.seek(Duration(seconds: v.toInt()));
                        },
                      ),

                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(format(position)),
                            Text(format(duration)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 40,
                icon: const Icon(Icons.replay_10),
                onPressed: () {
                  player.seek(player.position - const Duration(seconds: 10));
                },
              ),

              StreamBuilder<PlayerState>(
                stream: player.playerStateStream,
                builder: (_, snapshot) {
                  final playing = snapshot.data?.playing ?? false;

                  return IconButton(
                    iconSize: 60,
                    icon: Icon(
                        playing ? Icons.pause_circle : Icons.play_circle),
                    onPressed: () {
                      playing ? player.pause() : player.play();
                    },
                  );
                },
              ),

              IconButton(
                iconSize: 40,
                icon: const Icon(Icons.forward_10),
                onPressed: () {
                  player.seek(player.position + const Duration(seconds: 10));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}