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
  Timer? _progressTimer;
  bool paused = false;
  Duration? _videoDuration;
  double _currentProgress = 0.0;
  DateTime _storyStartedAt = DateTime.now();

  final TextEditingController _replyCtrl = TextEditingController();
  bool _replyHasText = false;

  @override
  void initState() {
    super.initState();
    index = widget.startIndex;
    _markViewed();
    _storyStartedAt = DateTime.now();
    _startTimer();
    _startProgressUpdates();
  }

  void _markViewed() {
    SFrameService.markViewed(widget.frames[index].id);
  }

  /// Current user's block in the combined list: [startOfBlock, endOfBlock] (inclusive).
  void _currentUserBlock(int currentIndex, void Function(int start, int end) out) {
    if (widget.frames.isEmpty) return;
    final uid = widget.frames[currentIndex].uid;
    int start = currentIndex;
    while (start > 0 && widget.frames[start - 1].uid == uid) {
      start--;
    }
    int end = currentIndex;
    while (end < widget.frames.length - 1 && widget.frames[end + 1].uid == uid) {
      end++;
    }
    out(start, end);
  }

  Duration get _currentStoryDuration {
    final frame = widget.frames[index];
    if (frame.mediaType == "video" && _videoDuration != null) {
      return _videoDuration!;
    }
    return const Duration(seconds: 5);
  }

  void _startProgressUpdates() {
    _progressTimer?.cancel();
    _storyStartedAt = DateTime.now();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted || paused) return;
      final elapsed = DateTime.now().difference(_storyStartedAt);
      final duration = _currentStoryDuration;
      final progress = duration.inMilliseconds > 0
          ? (elapsed.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
          : 1.0;
      if (!mounted) return;
      setState(() => _currentProgress = progress);
    });
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
    _progressTimer?.cancel();
    if (!mounted) return;
    if (index < widget.frames.length - 1) {
      setState(() {
        index++;
        _videoDuration = null;
        _currentProgress = 0.0;
      });
      _storyStartedAt = DateTime.now();
      _markViewed();
      _startTimer();
      _startProgressUpdates();
    } else {
      timer?.cancel();
      _progressTimer?.cancel();
      if (mounted) Navigator.pop(context);
    }
  }

  void _prev() {
    _progressTimer?.cancel();
    if (index > 0) {
      setState(() {
        index--;
        _videoDuration = null;
        _currentProgress = 0.0;
      });
      _storyStartedAt = DateTime.now();
      _markViewed();
      _startTimer();
      _startProgressUpdates();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    _progressTimer?.cancel();
    _replyCtrl.dispose();
    super.dispose();
  }

  Widget _buildStoryAvatar(String? ownerAvatar) {
    final url = ownerAvatar != null && ownerAvatar.isNotEmpty
        ? (ApiConfig.networkImageUrl(ownerAvatar) ?? ownerAvatar)
        : null;
    if (url == null) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.white24,
        child: const Icon(Icons.person, color: Colors.white70, size: 24),
      );
    }
    return ClipOval(
      child: Image.network(
        url,
        fit: BoxFit.cover,
        width: 40,
        height: 40,
        errorBuilder: (_, __, ___) => Container(
          width: 40,
          height: 40,
          color: Colors.white24,
          child: const Icon(Icons.person, color: Colors.white70, size: 24),
        ),
      ),
    );
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
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Echos (Likes)',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border_rounded, color: Colors.white.withValues(alpha: 0.4), size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'No likes yet',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (index < 0 || index >= widget.frames.length) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ),
      );
    }
    final frame = widget.frames[index];
    final auth = context.watch<AuthProvider>();
    final currentUid = auth.user?.uid ?? '';
    final isOwnStory = currentUid.isNotEmpty && frame.uid == currentUid;

    const topBarHeight = 100.0;
    const bottomBarHeight = 140.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onLongPressStart: (_) {
          setState(() => paused = true);
          timer?.cancel();
          _progressTimer?.cancel();
        },
        onLongPressEnd: (_) {
          setState(() => paused = false);
          _storyStartedAt = DateTime.now();
          _startTimer();
          _startProgressUpdates();
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

            // ================= SEGMENTED PROGRESS BAR (one segment per story for current user only) =================
            Positioned(
              top: 44,
              left: 16,
              right: 16,
              child: Builder(
                builder: (context) {
                  int blockStart = index;
                  int blockEnd = index;
                  _currentUserBlock(index, (s, e) {
                    blockStart = s;
                    blockEnd = e;
                  });
                  final segmentCount = blockEnd - blockStart + 1;
                  final indexInBlock = index - blockStart;
                  return Row(
                    children: List.generate(segmentCount, (i) {
                      final isCurrent = i == indexInBlock;
                      final isPast = i < indexInBlock;
                      final progress = isPast ? 1.0 : (isCurrent ? _currentProgress.clamp(0.0, 1.0) : 0.0);
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: i < segmentCount - 1 ? 4 : 0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(1),
                            child: SizedBox(
                              height: 2,
                              child: Stack(
                                children: [
                                  SizedBox.expand(child: Container(color: Colors.white24)),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      return Container(
                                        width: constraints.maxWidth * progress,
                                        height: 2,
                                        color: Colors.white,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),

            // ================= LEFT / RIGHT TAP ZONES: tap left = previous, tap right = next =================
            Positioned(
              top: topBarHeight,
              left: 0,
              right: 0,
              bottom: bottomBarHeight,
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _prev();
                      },
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _next();
                      },
                    ),
                  ),
                ],
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
                    _buildStoryAvatar(frame.ownerAvatar),
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

            // ================= ECHOS (heart) – only for viewers (not own story); above reply box =================
            if (!isOwnStory)
              Positioned(
                bottom: 88,
                left: 0,
                right: 0,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // TODO: call API to send echo/like when backend supports it
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Echo sent'), duration: Duration(seconds: 1)),
                        );
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: const Icon(Icons.favorite_border, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                ),
              ),

            // ================= VIEWS (who viewed) – only for story owner =================
            if (isOwnStory)
              Positioned(
                bottom: 88,
                right: 16,
                child: GestureDetector(
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
              ),

            // ================= REPLY (story comments) =================
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyCtrl,
                        onChanged: (_) => setState(() => _replyHasText = _replyCtrl.text.trim().isNotEmpty),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                        decoration: InputDecoration(
                          hintText: "Reply to ${frame.ownerName ?? 'story'}…",
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    Material(
                      color: _replyHasText
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(22),
                      child: InkWell(
                        onTap: () {
                          final text = _replyCtrl.text.trim();
                          if (text.isNotEmpty) {
                            SFrameService.sendReply(frame.id, text);
                            _replyCtrl.clear();
                            setState(() => _replyHasText = false);
                          }
                        },
                        borderRadius: BorderRadius.circular(22),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.send_rounded,
                            color: _replyHasText ? Colors.black : Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
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
