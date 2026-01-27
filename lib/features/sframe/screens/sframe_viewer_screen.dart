import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/sframe_model.dart';
import '../services/sframe_service.dart';
import '../utils/sframe_filters.dart';
import '../widgets/sframe_seen_modal.dart';

class SFrameViewerScreen extends StatefulWidget {
  final List<SFrame> frames;
  final int startIndex;

  const SFrameViewerScreen({
    super.key,
    required this.frames,
    required this.startIndex,
  });

  @override
  State<SFrameViewerScreen> createState() => _SFrameViewerScreenState();
}

class _SFrameViewerScreenState extends State<SFrameViewerScreen> {
  late int index;
  Timer? timer;
  bool paused = false;
  Duration? _videoDuration;

  final TextEditingController _replyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    index = widget.startIndex;
    _markViewed();
    _startTimer();
  }

  void _markViewed() {
    SFrameService.markViewed(widget.frames[index].id);
  }

  void _startTimer() {
    timer?.cancel();
    if (paused) return;

    final frame = widget.frames[index];

    if (frame.mediaType == "video" && _videoDuration != null) {
      timer = Timer(_videoDuration!, _next);
    } else {
      timer = Timer(const Duration(seconds: 5), _next);
    }
  }

  void _next() {
    if (index < widget.frames.length - 1) {
      setState(() {
        index++;
        _videoDuration = null;
      });
      _markViewed();
      _startTimer();
    } else {
      Navigator.pop(context);
    }
  }

  void _prev() {
    if (index > 0) {
      setState(() {
        index--;
        _videoDuration = null;
      });
      _markViewed();
      _startTimer();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    _replyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = widget.frames[index];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (d) {
          HapticFeedback.lightImpact();
          final w = MediaQuery.of(context).size.width;
          d.localPosition.dx > w / 2 ? _next() : _prev();
        },
        onLongPressStart: (_) {
          setState(() => paused = true);
          timer?.cancel();
        },
        onLongPressEnd: (_) {
          setState(() => paused = false);
          _startTimer();
        },
        child: Stack(
          children: [
            // ================= CONTENT =================
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: frame.mediaType == "text"
                    ? Padding(
                        key: ValueKey(frame.id),
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          frame.textContent ?? "",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : frame.mediaType == "photo"
                        ? ColorFiltered(
                            key: ValueKey(frame.id),
                            colorFilter: filterToColor(
                              parseSFrameFilter(frame.filter),
                            ) ??
                                const ColorFilter.mode(
                                  Colors.transparent,
                                  BlendMode.dst,
                                ),
                            child: CachedNetworkImage(
                              imageUrl: frame.mediaUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (_, __) =>
                                  const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                              errorWidget:
                                  (_, __, ___) => const Icon(
                                Icons.broken_image,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          )
                        : _VideoPlayer(
                            key: ValueKey(frame.id),
                            url: frame.mediaUrl!,
                            paused: paused,
                            onDuration: (d) {
                              _videoDuration = d;
                              _startTimer();
                            },
                          ),
              ),
            ),

            // ================= PROGRESS =================
Positioned(
  top: 40,
  left: 16,
  right: 16,
  child: Row(
    children: List.generate(
      widget.frames.length,
      (i) => Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          height: 2,
          color: i <= index ? Colors.white : Colors.white24,
        ),
      ),
    ),
  ),
),

            // ================= SEEN LIST =================
            Positioned(
              bottom: 90,
              right: 20,
              child: GestureDetector(
                onTap: () async {
                  final users =
                      await SFrameService.getSeenUsers(
                          frame.id);
                  showSeenModal(context, users);
                },
                child: const Icon(
                  Icons.remove_red_eye,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),

            // ================= REPLY =================
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyCtrl,
                        style: const TextStyle(
                            color: Colors.white),
                        decoration:
                            const InputDecoration(
                          hintText: "Reply…",
                          hintStyle: TextStyle(
                              color: Colors.white38),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send,
                          color: Colors.white),
                      onPressed: () {
                        final text =
                            _replyCtrl.text.trim();
                        if (text.isNotEmpty) {
                          SFrameService.sendReply(
                              frame.id, text);
                          _replyCtrl.clear();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ================= CLOSE =================
            Positioned(
              top: 40,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// VIDEO PLAYER WITH DURATION CALLBACK
// ======================================================
class _VideoPlayer extends StatefulWidget {
  final String url;
  final bool paused;
  final ValueChanged<Duration> onDuration;

  const _VideoPlayer({
    super.key,
    required this.url,
    required this.paused,
    required this.onDuration,
  });

  @override
  State<_VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<_VideoPlayer> {
  late VideoPlayerController controller;

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        widget.onDuration(controller.value.duration);
        setState(() {});
        controller.play();
      });
  }

  @override
  void didUpdateWidget(covariant _VideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.paused ? controller.pause() : controller.play();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const CircularProgressIndicator(
        color: Colors.white,
      );
    }
    return VideoPlayer(controller);
  }
}
