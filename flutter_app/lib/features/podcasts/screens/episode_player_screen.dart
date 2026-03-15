import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../utils/media_utils.dart';
import '../models/episode_model.dart';

class EpisodePlayerScreen extends StatefulWidget {
  final EpisodeModel episode;

  const EpisodePlayerScreen({super.key, required this.episode});

  @override
  State<EpisodePlayerScreen> createState() => _EpisodePlayerScreenState();
}

class _EpisodePlayerScreenState extends State<EpisodePlayerScreen> {
  final AudioPlayer player = AudioPlayer();

  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAudio();
  }

  Future<void> _loadAudio() async {
    if (widget.episode.audioUrl.isEmpty) {
      setState(() {
        _loading = false;
        _errorMessage = "No audio URL";
      });
      return;
    }
    try {
      await player.setUrl(widget.episode.audioUrl);
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = "Could not load audio";
        });
      }
    }
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.episode.title,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),

          if (widget.episode.coverUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: safeNetworkImage(
                    url: widget.episode.coverUrl,
                    height: 250,
                    fit: BoxFit.cover,
                    placeholderIcon: Icons.podcasts,
                  ),
                ),
              ),
            )
          else
            Container(
              height: 250,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.podcasts, size: 64, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
            ),

          const SizedBox(height: 30),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              widget.episode.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 30),

          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: scheme.error),
                textAlign: TextAlign.center,
              ),
            )
          else
            StreamBuilder<Duration>(
              stream: player.positionStream,
              builder: (_, snapshot) {
                final position = snapshot.data ?? Duration.zero;

                return StreamBuilder<Duration?>(
                  stream: player.durationStream,
                  builder: (_, snap2) {
                    final duration = snap2.data ?? Duration.zero;
                    final durationSec = duration.inSeconds;
                    final positionSec = position.inSeconds;
                    final maxSec = durationSec > 0 ? durationSec.toDouble() : 1.0;
                    final valueSec = positionSec.clamp(0, durationSec).toDouble();

                    return Column(
                      children: [
                        Slider(
                          value: valueSec,
                          max: maxSec,
                          onChanged: durationSec > 0
                              ? (v) {
                                  player.seek(Duration(seconds: v.toInt()));
                                }
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(format(position), style: TextStyle(color: scheme.onSurfaceVariant)),
                              Text(format(duration), style: TextStyle(color: scheme.onSurfaceVariant)),
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
                onPressed: _loading ? null : () {
                  player.seek(player.position - const Duration(seconds: 10));
                },
              ),
              StreamBuilder<PlayerState>(
                stream: player.playerStateStream,
                builder: (_, snapshot) {
                  final playing = snapshot.data?.playing ?? false;
                  final processing = snapshot.data?.processingState == ProcessingState.loading;

                  return IconButton(
                    iconSize: 60,
                    icon: processing || _loading
                        ? SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.primary,
                            ),
                          )
                        : Icon(
                            playing ? Icons.pause_circle : Icons.play_circle,
                            color: scheme.primary,
                          ),
                    onPressed: _loading || processing
                        ? null
                        : () {
                            playing ? player.pause() : player.play();
                          },
                  );
                },
              ),
              IconButton(
                iconSize: 40,
                icon: const Icon(Icons.forward_10),
                onPressed: _loading ? null : () {
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