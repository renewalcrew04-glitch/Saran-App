import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../config/api_config.dart';
import '../../../providers/auth_provider.dart';
import '../services/sframe_service.dart';
import '../models/sframe_model.dart';

class SFrameRow extends StatelessWidget {
  final bool darkTheme;
  /// Called when user returns from create screen so the list can refresh (Instagram-style: see your story right away).
  final VoidCallback? onStoryCreated;

  const SFrameRow({super.key, this.darkTheme = false, this.onStoryCreated});

  static const double _frameWidth = 72;
  static const double _frameHeight = 96;

  /// Always show the create S-Frame slot (dashed). On error/empty, show only this — no big error block.
  Widget _buildCreateFrame(BuildContext context) {
    final fg = darkTheme ? Colors.white : Colors.black;
    final addBg = darkTheme ? Colors.white : Colors.black;
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
          color: Colors.transparent,
        ),
        child: Stack(
          children: [
            CustomPaint(
              size: const Size(_frameWidth, _frameHeight),
              painter: _DashedRectPainter(color: fg),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: addBg,
                    child: Icon(Icons.add, color: addFg, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "S-Frame",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: fg,
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

  /// Order so current user's story is first (right after create), then others.
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
    // Use current user's avatar for my story, otherwise use frame's ownerAvatar (from API)
    final avatarToShow = (isMe && avatarUrl != null && avatarUrl.isNotEmpty)
        ? avatarUrl
        : (f.ownerAvatar != null && f.ownerAvatar!.isNotEmpty ? f.ownerAvatar : null);
    final viewIds = f.views.map((v) => v.toString()).toList();
    final seen = currentUid != null && viewIds.contains(currentUid);
    final borderColor = darkTheme
        ? (seen ? Colors.grey.shade600 : Colors.white)
        : (seen ? Colors.grey : Colors.black);
    final iconColor = darkTheme ? Colors.white70 : Colors.black54;

    final displayName = f.ownerName ?? f.ownerUsername ?? 'Unknown';
    return GestureDetector(
      onTap: () async {
        // Combined list so tapping right on last story of user 1 goes to first story of user 2
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
                      width: _frameWidth,
                      height: _frameHeight,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(Icons.person, color: iconColor, size: 36),
                      ),
                    )
                  : Center(
                      child: Icon(Icons.person, color: iconColor, size: 36),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 0, bottom: 8),
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
                  padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
                  child: SizedBox(
                    width: _frameWidth,
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: darkTheme ? Colors.white70 : null,
                        ),
                      ),
                    ),
                  ),
                )
              else
                ...onePerUser.asMap().entries.map((entry) {
                  final i = entry.key;
                  final f = entry.value;
                  final userFrames = allFrames
                      .where((x) => x.uid == f.uid)
                      .toList()
                      .reversed
                      .toList();
                  final startIndexInCombined = i < startIndices.length ? startIndices[i] : 0;
                  return _buildStoryBubble(
                    context,
                    f: f,
                    userFrames: userFrames,
                    allFramesCombined: allFramesCombined,
                    startIndexInCombined: startIndexInCombined,
                    currentUid: currentUid,
                    avatarUrl: isMe(f.uid, currentUid) ? avatarUrl : null,
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

  _DashedRectPainter({this.color = Colors.black});

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    const strokeWidth = 2.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2,
          size.width - strokeWidth, size.height - strokeWidth),
      const Radius.circular(4),
    );
    final path = Path()..addRRect(rrect);

    void drawDashedPath(Path path) {
      for (final metric in path.computeMetrics()) {
        var distance = 0.0;
        while (distance < metric.length) {
          final length = (distance + dashWidth > metric.length)
              ? metric.length - distance
              : dashWidth;
          final extractPath = metric.extractPath(distance, distance + length);
          canvas.drawPath(extractPath, paint);
          distance += length + dashSpace;
        }
      }
    }
    drawDashedPath(path);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
