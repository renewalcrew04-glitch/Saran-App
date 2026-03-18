import 'package:flutter/material.dart';
import 'dart:math';

/// Multi-ring animated glow widget.
/// Three concentric rings expand outward and fade when [active] is true.
class AIWaveRing extends StatefulWidget {
  final bool active;
  final double size;
  final Color color;

  const AIWaveRing({
    super.key,
    required this.active,
    this.size = 240,
    this.color = const Color(0xFF9B4DFF),
  });

  @override
  State<AIWaveRing> createState() => _AIWaveRingState();
}

class _AIWaveRingState extends State<AIWaveRing>
    with TickerProviderStateMixin {
  late final AnimationController _ring1;
  late final AnimationController _ring2;
  late final AnimationController _ring3;

  @override
  void initState() {
    super.initState();
    _ring1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _ring2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    )..repeat();
    _ring3 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _ring1.dispose();
    _ring2.dispose();
    _ring3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_ring1, _ring2, _ring3]),
      builder: (_, __) {
        final base = widget.size / 2;
        final expansion = widget.active ? 28.0 : 8.0;

        void drawRing(Canvas canvas, Size sz, AnimationController ctrl,
            double baseOpacity) {
          final t = ctrl.value;
          final radius = base + t * expansion;
          final opacity = (1.0 - t) * baseOpacity;
          if (opacity < 0.01) return;
          canvas.drawCircle(
            Offset(sz.width / 2, sz.height / 2),
            radius,
            Paint()
              ..color = widget.color.withOpacity(opacity.clamp(0.0, 1.0))
              ..style = PaintingStyle.stroke
              ..strokeWidth = widget.active ? 1.8 : 1.2,
          );
        }

        return CustomPaint(
          size: Size(widget.size + expansion * 2, widget.size + expansion * 2),
          painter: _MultiRingPainter(
            ring1: _ring1.value,
            ring2: _ring2.value,
            ring3: _ring3.value,
            base: base,
            expansion: expansion,
            active: widget.active,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _MultiRingPainter extends CustomPainter {
  final double ring1, ring2, ring3;
  final double base, expansion;
  final bool active;
  final Color color;

  const _MultiRingPainter({
    required this.ring1,
    required this.ring2,
    required this.ring3,
    required this.base,
    required this.expansion,
    required this.active,
    required this.color,
  });

  void _drawRing(Canvas canvas, Size size, double t, double baseOpacity) {
    final opacity = (1.0 - t) * baseOpacity;
    if (opacity < 0.01) return;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      base + t * expansion,
      Paint()
        ..color = color.withOpacity(opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = active ? 1.8 : 1.2,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawRing(canvas, size, ring1, active ? 0.75 : 0.30);
    _drawRing(canvas, size, ring2, active ? 0.55 : 0.20);
    _drawRing(canvas, size, ring3, active ? 0.35 : 0.12);
  }

  @override
  bool shouldRepaint(_MultiRingPainter old) =>
      old.ring1 != ring1 || old.ring2 != ring2 || old.ring3 != ring3;
}
