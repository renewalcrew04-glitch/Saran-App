import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  @override
  Widget build(BuildContext context) {
    final uid = "me"; // TEMP placeholder

    return FutureBuilder<List<SFrame>>(
      future: SFrameService.loadFrames(),
      builder: (context, snapshot) {
        // Always show at least the create S-Frame row — never a full-screen error.
        List<SFrame> list = [];
        if (!snapshot.hasError && snapshot.hasData) {
          final frames = snapshot.data ?? [];
          final map = <String, SFrame>{};
          for (final f in frames) {
            map[f.uid] = f;
          }
          list = map.values.toList();
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
                ...list.asMap().entries.map((entry) {
                  final f = entry.value;
                  final seen = f.views.contains(uid);
                  final borderColor = darkTheme
                      ? (seen ? Colors.grey.shade600 : Colors.white)
                      : (seen ? Colors.grey : Colors.black);
                  return GestureDetector(
                    onTap: () {
                      context.push(
                        '/sframe-viewer',
                        extra: {
                          'frames': list,
                          'startIndex': entry.key,
                        },
                      );
                    },
                    child: Container(
                      width: 90,
                      height: 94,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: borderColor,
                          width: 2,
                        ),
                      ),
                      child: Icon(Icons.person, color: darkTheme ? Colors.white70 : Colors.black54),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
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
