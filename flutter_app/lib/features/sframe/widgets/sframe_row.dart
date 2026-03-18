import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../config/api_config.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/media_utils.dart';
import '../services/sframe_service.dart';
import '../models/sframe_model.dart';

class SFrameRow extends StatelessWidget {
  final bool darkTheme;
  /// Called when user returns from create screen so the list can refresh.
  final VoidCallback? onStoryCreated;

  const SFrameRow({super.key, this.darkTheme = false, this.onStoryCreated});

  static const double _frameSize = 64; // circle diameter

 Widget _buildCreateFrame(BuildContext context, {String? userAvatarUrl}) {
  final mutedFg = darkTheme
      ? Colors.white.withOpacity(0.40)
      : Colors.black.withOpacity(0.40);

  final avatarUrl = userAvatarUrl != null && userAvatarUrl.isNotEmpty
      ? (ApiConfig.networkImageUrl(userAvatarUrl) ?? userAvatarUrl)
      : null;

  return GestureDetector(
    onTap: () async {
      await context.push('/sframe-create');
      onStoryCreated?.call();
    },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: _frameSize,
          height: _frameSize,
          margin: const EdgeInsets.all(6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Dashed circle border background
              CustomPaint(
                size: const Size(_frameSize, _frameSize),
                painter: _DashedCirclePainter(color: mutedFg),
              ),
              // Profile photo if available
              if (avatarUrl != null)
                ClipOval(
                  child: Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox.shrink();
                    },
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              // "+" icon in center
              Center(
                child: Icon(
                  Icons.add,
                  color: darkTheme ? Colors.white70 : Colors.black54,
                  size: 22,
                ),
              ),
            ],
          ),
        ),

        /// TEXT BELOW
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: SizedBox(
            width: _frameSize + 16,
            child: Text(
              "Your S-Frame",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: darkTheme ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  static List<SFrame> _orderWithMeFirst(List<SFrame> onePerUser, String? myUid) {
    if (myUid == null || myUid.isEmpty) return onePerUser;
    final mine = onePerUser.where((f) => f.uid == myUid).toList();
    final others = onePerUser.where((f) => f.uid != myUid).toList();
    return [...mine, ...others];
  }

  Widget _buildStoryBubble(
    BuildContext context, {
    required SFrame f,
    required List<SFrame> userFrames,
    required List<SFrame> allFramesCombined,
    required int startIndexInCombined,
    required String? currentUid,
    required String? avatarUrl,
    required bool darkTheme,
  }) {
    final isMe = currentUid != null && f.uid == currentUid;
    final avatarToShow = (isMe && avatarUrl != null && avatarUrl.isNotEmpty)
        ? avatarUrl
        : (f.ownerAvatar != null && f.ownerAvatar!.isNotEmpty
            ? f.ownerAvatar
            : null);

    final viewIds = f.views.map((v) => v.toString()).toList();
    final seen = currentUid != null && viewIds.contains(currentUid);

    final iconColor = darkTheme ? Colors.white70 : Colors.black54;
    final displayName = f.ownerName ?? f.ownerUsername ?? 'Unknown';

    // Ring gradient colors: unseen = vibrant gradient, seen = grey
    final ringColors = seen
        ? [Colors.grey.shade600, Colors.grey.shade700]
        : [
            const Color(0xFFFFD700),
            const Color(0xFFFF8C00),
            const Color(0xFFFF4500),
          ];

    return GestureDetector(
      onTap: () async {
        final result = await context.push<bool>(
          '/sframe-viewer',
          extra: {
            'frames': allFramesCombined,
            'startIndex': startIndexInCombined,
          },
        );
        if (result == true) onStoryCreated?.call();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: _frameSize + 6,
            height: _frameSize + 6,
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: ringColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(2.5),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: darkTheme ? const Color(0xFF0D1120) : Colors.white,
              ),
              padding: const EdgeInsets.all(2),
              child: ClipOval(
                child: avatarToShow != null
                    ? Image.network(
                        ApiConfig.networkImageUrl(avatarToShow) ?? avatarToShow,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.person, color: iconColor, size: 30),
                      )
                    : _buildInitialBubble(displayName, darkTheme),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: SizedBox(
              width: _frameSize + 16,
              child: Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: darkTheme ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a colorful circle with the user's initial when no avatar is available.
  Widget _buildInitialBubble(String displayName, bool darkTheme) {
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    // Deterministic color based on initial
    final colors = _initialColors[initial.codeUnitAt(0) % _initialColors.length];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 22,
          height: 1,
        ),
      ),
    );
  }

  static const List<List<Color>> _initialColors = [
    [Color(0xFF8B5CF6), Color(0xFFEC4899)], // purple-pink
    [Color(0xFF06B6D4), Color(0xFF3B82F6)], // cyan-blue
    [Color(0xFF10B981), Color(0xFF059669)], // green
    [Color(0xFFF59E0B), Color(0xFFEF4444)], // amber-red
    [Color(0xFF6366F1), Color(0xFF8B5CF6)], // indigo-purple
    [Color(0xFF14B8A6), Color(0xFF0EA5E9)], // teal-sky
    [Color(0xFFF97316), Color(0xFFEF4444)], // orange-red
    [Color(0xFFEC4899), Color(0xFF8B5CF6)], // pink-purple
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentUid = auth.user?.uid;
    final avatarUrl = auth.user?.avatar;

    return FutureBuilder<List<SFrame>>(
      future: SFrameService.loadFrames(),
      builder: (context, snapshot) {
        List<SFrame> allFrames = [];
        List<SFrame> onePerUser = [];
        List<SFrame> allFramesCombined = [];
        List<int> startIndices = [];

        if (!snapshot.hasError && snapshot.hasData) {
          final frames = snapshot.data ?? [];
          allFrames = frames;

          final map = <String, SFrame>{};
          for (final f in frames) {
            if (!map.containsKey(f.uid)) map[f.uid] = f;
          }

          onePerUser = _orderWithMeFirst(map.values.toList(), currentUid);

          startIndices = [0];
          for (final f in onePerUser) {
            final ufs = allFrames
                .where((x) => x.uid == f.uid)
                .toList()
                .reversed
                .toList();
            allFramesCombined.addAll(ufs);
            startIndices.add(allFramesCombined.length);
          }
        }

        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            children: [
              _buildCreateFrame(context, userAvatarUrl: avatarUrl),
              if (isLoading)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: SizedBox(
                    width: _frameSize,
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                )
              else
                ...onePerUser.asMap().entries.map((entry) {
                  final i = entry.key;
                  final f = entry.value;
                  final startIndex =
                      i < startIndices.length ? startIndices[i] : 0;

                  return _buildStoryBubble(
                    context,
                    f: f,
                    userFrames: const [],
                    allFramesCombined: allFramesCombined,
                    startIndexInCombined: startIndex,
                    currentUid: currentUid,
                    avatarUrl:
                        isMe(f.uid, currentUid) ? avatarUrl : null,
                    darkTheme: darkTheme,
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  static bool isMe(String? frameUid, String? currentUid) {
    return currentUid != null && frameUid == currentUid;
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;

  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const dashCount = 16;
    const strokeWidth = 1.5;
    const gapFraction = 0.35; // fraction of each dash that is gap

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth;

    const totalAngle = 2 * 3.141592653589793;
    final dashAngle = (totalAngle / dashCount) * (1 - gapFraction);
    final gapAngle = (totalAngle / dashCount) * gapFraction;

    double startAngle = -3.141592653589793 / 2;
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
      startAngle += dashAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
