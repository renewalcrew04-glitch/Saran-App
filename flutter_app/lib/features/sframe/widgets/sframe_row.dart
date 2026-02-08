import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../config/api_config.dart';
import '../../../providers/auth_provider.dart';
import '../services/sframe_service.dart';
import '../models/sframe_model.dart';

class SFrameRow extends StatelessWidget {
  final bool darkTheme;
  /// Called when user returns from create screen so the list can refresh.
  final VoidCallback? onStoryCreated;

  const SFrameRow({super.key, this.darkTheme = false, this.onStoryCreated});

  static const double _frameWidth = 72;
  static const double _frameHeight = 96;

  /// Create S-Frame tile (clean + calm)
  Widget _buildCreateFrame(BuildContext context) {
    final fg = darkTheme ? Colors.white : Colors.black;
    final mutedFg = fg.withOpacity(0.35);

    final addBg = darkTheme
        ? Colors.white.withOpacity(0.9)
        : Colors.black.withOpacity(0.9);
    final addFg = darkTheme ? Colors.black : Colors.white;

    return GestureDetector(
      onTap: () async {
        await context.push('/sframe-create');
        onStoryCreated?.call();
      },
      child: Container(
        width: _frameWidth,
        height: _frameHeight,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
        ),
        child: Stack(
          children: [
            CustomPaint(
              size: const Size(_frameWidth, _frameHeight),
              painter: _DashedRectPainter(color: mutedFg),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: addBg,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.add,
                      color: addFg,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
              ),
            ),
          ],
        ),
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

    final borderColor = darkTheme
        ? (seen ? Colors.grey.shade600 : Colors.white)
        : (seen ? Colors.grey : Colors.black);

    final iconColor = darkTheme ? Colors.white70 : Colors.black54;
    final displayName = f.ownerName ?? f.ownerUsername ?? 'Unknown';

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
            width: _frameWidth,
            height: _frameHeight,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: avatarToShow != null
                  ? Image.network(
                      ApiConfig.networkImageUrl(avatarToShow) ?? avatarToShow,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.person, color: iconColor, size: 36),
                    )
                  : Icon(Icons.person, color: iconColor, size: 36),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              width: _frameWidth + 16,
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
          height: 138,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            children: [
              _buildCreateFrame(context),
              if (isLoading)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: SizedBox(
                    width: _frameWidth,
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

class _DashedRectPainter extends CustomPainter {
  final Color color;

  _DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 5.0;
    const dashSpace = 5.0;
    const strokeWidth = 1.4;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      const Radius.circular(4),
    );

    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final len = dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, distance + len),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
