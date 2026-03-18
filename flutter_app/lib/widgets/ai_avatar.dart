import 'dart:math';
import 'package:flutter/material.dart';

/// Animated AI companion avatar.
///
/// Shows:
/// - gentle float (bob up/down)
/// - subtle breathe (scale in/out)
/// - pulsing glow rings that expand outward when active
/// - shimmer arc on the avatar circle
/// - state-aware ring color: green=listening, amber=thinking, blue=speaking
class AICompanionAvatar extends StatefulWidget {
  final bool isListening;
  final bool isLoading;
  final bool isSpeaking;
  final bool isFemale;

  const AICompanionAvatar({
    super.key,
    required this.isListening,
    required this.isLoading,
    required this.isSpeaking,
    required this.isFemale,
  });

  @override
  State<AICompanionAvatar> createState() => _AICompanionAvatarState();
}

class _AICompanionAvatarState extends State<AICompanionAvatar>
    with TickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final AnimationController _breatheCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _ring1Ctrl;
  late final AnimationController _ring2Ctrl;
  late final AnimationController _ring3Ctrl;

  late final Animation<double> _floatAnim;
  late final Animation<double> _breatheAnim;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();

    // Gentle float: bob up and down
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -9.0, end: 9.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    // Subtle breathe: scale in/out
    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _breatheAnim = Tween<double>(begin: 0.965, end: 1.035).animate(
      CurvedAnimation(parent: _breatheCtrl, curve: Curves.easeInOut),
    );

    // Glow intensity pulse
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    // 3 rings at different speeds (expand outward + fade)
    _ring1Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _ring2Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _ring3Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2900),
    )..repeat();
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _breatheCtrl.dispose();
    _glowCtrl.dispose();
    _ring1Ctrl.dispose();
    _ring2Ctrl.dispose();
    _ring3Ctrl.dispose();
    super.dispose();
  }

  Color get _activeColor {
    if (widget.isListening) return const Color(0xFF4FFFB0); // green
    if (widget.isLoading) return const Color(0xFFFFB347);   // amber
    if (widget.isSpeaking) return const Color(0xFF87CEEB);  // sky blue
    return const Color(0xFF9B4DFF);                          // purple (idle)
  }

  @override
  Widget build(BuildContext context) {
    final isActive =
        widget.isListening || widget.isLoading || widget.isSpeaking;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _floatCtrl,
        _breatheCtrl,
        _glowCtrl,
        _ring1Ctrl,
        _ring2Ctrl,
        _ring3Ctrl,
      ]),
      builder: (_, __) {
        final glowLevel =
            isActive ? 0.5 + _glowAnim.value * 0.5 : 0.2 + _glowAnim.value * 0.15;

        return Transform.translate(
          offset: Offset(0, _floatAnim.value),
          child: Transform.scale(
            scale: _breatheAnim.value,
            child: SizedBox(
              width: 300,
              height: 300,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // ── Ring 3: outermost, slowest ────────────────────────
                  CustomPaint(
                    size: const Size(300, 300),
                    painter: _RingPainter(
                      progress: _ring3Ctrl.value,
                      maxRadius: 145,
                      maxExpansion: isActive ? 32 : 8,
                      baseOpacity: isActive ? 0.32 : 0.10,
                      color: _activeColor,
                      strokeWidth: 1.0,
                    ),
                  ),

                  // ── Ring 2: medium ────────────────────────────────────
                  CustomPaint(
                    size: const Size(300, 300),
                    painter: _RingPainter(
                      progress: _ring2Ctrl.value,
                      maxRadius: 130,
                      maxExpansion: isActive ? 22 : 6,
                      baseOpacity: isActive ? 0.50 : 0.16,
                      color: const Color(0xFF9B4DFF),
                      strokeWidth: 1.5,
                    ),
                  ),

                  // ── Ring 1: innermost, fastest ────────────────────────
                  CustomPaint(
                    size: const Size(300, 300),
                    painter: _RingPainter(
                      progress: _ring1Ctrl.value,
                      maxRadius: 117,
                      maxExpansion: isActive ? 16 : 4,
                      baseOpacity: isActive ? 0.72 : 0.26,
                      color: const Color(0xFFB47AFF),
                      strokeWidth: 2.0,
                    ),
                  ),

                  // ── Avatar with glow ──────────────────────────────────
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED)
                              .withOpacity(glowLevel * 0.65),
                          blurRadius: 38,
                          spreadRadius: isActive ? 10 : 4,
                        ),
                        BoxShadow(
                          color: _activeColor.withOpacity(glowLevel * 0.25),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        widget.isFemale
                            ? 'assets/companions/female.png'
                            : 'assets/companions/male.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // ── Shimmer arc (top-left highlight) ─────────────────
                  CustomPaint(
                    size: const Size(220, 220),
                    painter: _ShimmerPainter(intensity: glowLevel),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Ring Painter ─────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final double maxRadius;
  final double maxExpansion;
  final double baseOpacity;
  final Color color;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.maxRadius,
    required this.maxExpansion,
    required this.baseOpacity,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = (1.0 - progress) * baseOpacity;
    if (opacity < 0.01) return;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      maxRadius + progress * maxExpansion,
      Paint()
        ..color = color.withOpacity(opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─── Shimmer Painter ──────────────────────────────────────────────────────────

class _ShimmerPainter extends CustomPainter {
  final double intensity;

  const _ShimmerPainter({required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    final paint = Paint()
      ..shader = SweepGradient(
        startAngle: -pi / 3,
        endAngle: pi / 2,
        colors: [
          Colors.white.withOpacity(intensity * 0.28),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi * 0.85,
      pi * 0.55,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) => old.intensity != intensity;
}
