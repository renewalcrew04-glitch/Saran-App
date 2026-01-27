import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class VoiceWaveformWidget extends StatefulWidget {
  final String url;
  final bool isOwn;

  const VoiceWaveformWidget({
    super.key,
    required this.url,
    required this.isOwn,
  });

  @override
  State<VoiceWaveformWidget> createState() => _VoiceWaveformWidgetState();
}

class _VoiceWaveformWidgetState extends State<VoiceWaveformWidget> {
  final AudioPlayer _player = AudioPlayer();

  bool _loading = false;
  bool _playing = false;
  double _progress = 0;

  Duration? _duration;

  @override
  void initState() {
    super.initState();

    _player.playerStateStream.listen((state) {
      final playing = state.playing;
      if (mounted) setState(() => _playing = playing);
    });

    _player.positionStream.listen((pos) {
      if (_duration == null || _duration!.inMilliseconds == 0) return;
      final p = pos.inMilliseconds / _duration!.inMilliseconds;
      if (mounted) setState(() => _progress = p.clamp(0, 1));
    });

    _player.durationStream.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    _player.processingStateStream.listen((s) {
      if (s == ProcessingState.completed) {
        _player.seek(Duration.zero);
        _player.pause();
        if (mounted) setState(() => _progress = 0);
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    try {
      if (_loading) return;

      if (_player.audioSource == null) {
        setState(() => _loading = true);
        await _player.setUrl(widget.url);
        setState(() => _loading = false);
        await _player.play();
        return;
      }

      if (_playing) {
        await _player.pause();
      } else {
        await _player.play();
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.isOwn ? Colors.white : Colors.black;
    final baseWave = widget.isOwn ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.15);
    final progressWave = widget.isOwn ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: _togglePlay,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _loading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: iconColor,
                  ),
                )
              : Icon(
                  _playing ? Icons.pause : Icons.play_arrow,
                  size: 18,
                  color: iconColor,
                ),
          const SizedBox(width: 10),
          Container(
            width: 120,
            height: 4,
            decoration: BoxDecoration(
              color: baseWave,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: _progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: progressWave,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
