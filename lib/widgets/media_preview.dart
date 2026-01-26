import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MediaPreview extends StatefulWidget {
  final String path;
  final bool isVideo;

  const MediaPreview({
    super.key,
    required this.path,
    required this.isVideo,
  });

  @override
  State<MediaPreview> createState() => _MediaPreviewState();
}

class _MediaPreviewState extends State<MediaPreview> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();

    if (widget.isVideo) {
      _controller = VideoPlayerController.file(File(widget.path))
        ..initialize().then((_) {
          if (mounted) setState(() {});
          _controller?.setLooping(true);
          _controller?.play();
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVideo) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(widget.path),
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return Container(
        height: 220,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const CircularProgressIndicator(),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: VideoPlayer(_controller!),
      ),
    );
  }
}
