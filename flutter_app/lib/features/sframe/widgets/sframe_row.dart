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
        width: 90,
        height: 94,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
        ),
        child: Stack(
          children: [
            CustomPaint(
              size: const Size(90, 94),
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
    required String? currentUid,
    required String? avatarUrl,
    required bool darkTheme,
  }) {
    final isMe = currentUid != null && f.uid == currentUid;
    final viewIds = f.views.map((v) => v.toString()).toList();
    final seen = currentUid != null && viewIds.contains(currentUid);
    final borderColor = darkTheme
        ? (seen ? Colors.grey.shade600 : Colors.white)
        : (seen ? Colors.grey : Colors.black);
    final iconColor = darkTheme ? Colors.white70 : Colors.black54;

    return GestureDetector(
      onTap: () async {
        final result = await context.push<bool>(
          '/sframe-viewer',
          extra: {
            'frames': userFrames,
            'startIndex': 0,
          },
        );
        if (result == true) onStoryCreated?.call();
      },
      child: Container(
        width: 90,
        height: 94,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: isMe && avatarUrl != null && avatarUrl.isNotEmpty
              ? Image.network(
                  ApiConfig.networkImageUrl(avatarUrl) ?? avatarUrl,
                  fit: BoxFit.cover,
                  width: 90,
                  height: 94,
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(Icons.person, color: iconColor, size: 36),
                  ),
                )
              : Center(
                  child: Icon(Icons.person, color: iconColor, size: 36),
                ),
        ),
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
        if (!snapshot.hasError && snapshot.hasData) {
          final frames = snapshot.data ?? [];
          allFrames = frames;
          final map = <String, SFrame>{};
          for (final f in frames) {
            if (!map.containsKey(f.uid)) map[f.uid] = f;
          }
          onePerUser = _orderWithMeFirst(map.values.toList(), currentUid);
        }

        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            children: [
              _buildCreateFrame(context),
              if (isLoading)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
                  child: SizedBox(
                    width: 90,
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
                ...onePerUser.map((f) {
                  final userFrames = allFrames
                      .where((x) => x.uid == f.uid)
                      .toList()
                      .reversed
                      .toList();
                  return _buildStoryBubble(
                    context,
                    f: f,
                    userFrames: userFrames,
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
      const Radius.circular(10),
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
