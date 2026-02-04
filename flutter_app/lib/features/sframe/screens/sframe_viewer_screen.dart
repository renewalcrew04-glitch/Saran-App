import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../config/api_config.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../screens/profile/user_profile_screen.dart';
import '../models/sframe_model.dart';
import '../services/sframe_service.dart';
import '../utils/sframe_filters.dart';
import '../widgets/sframe_seen_modal.dart';

String _timeAgo(DateTime? date) {
  if (date == null) return '';
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inDays > 0) return '${diff.inDays}d';
  if (diff.inHours > 0) return '${diff.inHours}h';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m';
  if (diff.inSeconds > 0) return '${diff.inSeconds}s';
  return 'now';
}

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

  Future<void> _onDeleteStory(SFrame frame) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete story?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This story will be removed. This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await SFrameService.deleteFrame(frame.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  void _showLikedModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Echos (Likes)',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No likes yet',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final frame = widget.frames[index];
    final auth = context.watch<AuthProvider>();
    final currentUid = auth.user?.uid ?? '';
    final isOwnStory = currentUid.isNotEmpty && frame.uid == currentUid;

    final size = MediaQuery.of(context).size;
    const topBarHeight = 100.0;
    const bottomBarHeight = 140.0;
    const headerRightWidth = 80.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (d) {
          final pos = d.localPosition;
          // Don't advance/close when tapping header, options, heart/eye, or reply bar
          if (pos.dy < topBarHeight) return;
          if (pos.dy > size.height - bottomBarHeight) return;
          if (pos.dx > size.width - headerRightWidth && pos.dy < topBarHeight) return;
          HapticFeedback.lightImpact();
          final w = size.width;
          if (pos.dx > w / 2) {
            _next();
          } else {
            _prev();
          }
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

            // ================= PROGRESS BARS (top) =================
            Positioned(
              top: 44,
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

            // ================= HEADER: Avatar + Name + Time (tap to open profile) =================
            Positioned(
              top: 56,
              left: 16,
              right: 80,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (frame.uid.isEmpty) return;
                  final user = User(
                    uid: frame.uid,
                    username: frame.ownerUsername ?? '',
                    email: '',
                    name: frame.ownerName ?? 'Unknown',
                    avatar: frame.ownerAvatar,
                    profileCompleted: false,
                    verified: false,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserProfileScreen(user: user),
                    ),
                  );
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white24,
                      backgroundImage: frame.ownerAvatar != null &&
                              frame.ownerAvatar!.isNotEmpty
                          ? NetworkImage(
                              ApiConfig.networkImageUrl(frame.ownerAvatar!) ?? frame.ownerAvatar!,
                            )
                          : null,
                      child: frame.ownerAvatar == null || frame.ownerAvatar!.isEmpty
                          ? const Icon(Icons.person, color: Colors.white70, size: 24)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            frame.ownerName ?? 'Unknown',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (frame.createdAt != null)
                            Text(
                              _timeAgo(frame.createdAt),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ================= ECHOS (likes) + VIEWS – only for story owner =================
            if (isOwnStory)
              Positioned(
                bottom: 90,
                right: 16,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Echos (likes) – tap to see who liked
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _showLikedModal(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.favorite_border, color: Colors.white, size: 22),
                            const SizedBox(width: 4),
                            Text(
                              '0',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // View count + eye – tap to see who viewed
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        final users = await SFrameService.getSeenUsers(frame.id);
                        if (!context.mounted) return;
                        showSeenModal(context, users);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.remove_red_eye, color: Colors.white, size: 22),
                          const SizedBox(width: 4),
                          Text(
                            '${frame.viewCount}',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Reply…",
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.transparent,
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isOwnStory)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz, color: Colors.white, size: 28),
                        color: Colors.grey[900],
                        onSelected: (value) {
                          if (value == 'delete') _onDeleteStory(frame);
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, color: Colors.white70, size: 22),
                                SizedBox(width: 12),
                                Text('Delete story', style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
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
    controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
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
