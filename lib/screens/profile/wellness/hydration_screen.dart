import 'dart:math';
import 'package:flutter/material.dart';
import 'package:saran_app/services/hydration_service.dart';
import 'package:saran_app/services/wellness_streak_service.dart';

class HydrationScreen extends StatefulWidget {
  const HydrationScreen({super.key});

  @override
  State<HydrationScreen> createState() => _HydrationScreenState();
}

class _HydrationScreenState extends State<HydrationScreen>
    with SingleTickerProviderStateMixin {
  int count = 0;
  int goal = 8;

  bool loading = true;
  bool markedToday = false;

  late final AnimationController _controller;
  late Animation<double> _fillAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fillAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get progress {
    if (goal <= 0) return 0;
    return (count / goal).clamp(0.0, 1.0);
  }

  Future<void> _load() async {
    final data = await HydrationService.loadToday();
    goal = data["goal"] ?? 8;
    count = data["count"] ?? 0;

    if (!mounted) return;
    setState(() => loading = false);

    _animateTo(progress);
  }

  Future<void> _save() async {
    await HydrationService.saveToday(goal: goal, count: count);
  }

  void _animateTo(double target) {
    final current = _fillAnim.value;
    _fillAnim = Tween<double>(begin: current, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward(from: 0);
  }

  Future<void> _maybeMarkWellness() async {
    if (markedToday) return;

    // mark wellness only once per open session
    // (it will handle streak rules inside WellnessStreakService)
    await WellnessStreakService.markCompleted(
      activityId: "hydration",
      activityTitle: "Hydration Tap",
    );
    markedToday = true;
  }

  Future<void> _tapBottle() async {
    if (count >= goal) return;

    setState(() {
      count += 1;
    });

    await _maybeMarkWellness();
    await _save();
    _animateTo(progress);
  }

  Future<void> _inc() async {
    if (count >= goal) return;
    setState(() => count += 1);
    await _maybeMarkWellness();
    await _save();
    _animateTo(progress);
  }

  Future<void> _dec() async {
    if (count <= 0) return;
    setState(() => count -= 1);
    await _save();
    _animateTo(progress);
  }

  Future<void> _goalPlus() async {
    if (goal >= 15) return;
    setState(() => goal += 1);
    await _save();
    _animateTo(progress);
  }

  Future<void> _goalMinus() async {
    if (goal <= 4) return;
    setState(() => goal -= 1);

    // if goal reduced below count -> clamp count
    if (count > goal) {
      count = goal;
    }

    await _save();
    _animateTo(progress);
  }

  @override
  Widget build(BuildContext context) {
    final done = count >= goal;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Hydration Tap"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Header count
                  Text(
                    "$count / $goal",
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w300,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    done ? "Goal reached 🎉" : "Tap the bottle to drink water",
                    style: TextStyle(
                      fontSize: 13,
                      color: done ? Colors.black : Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Bottle
                  Expanded(
                    child: Center(
                      child: GestureDetector(
                        onTap: _tapBottle,
                        child: AnimatedBuilder(
                          animation: _fillAnim,
                          builder: (context, _) {
                            return CustomPaint(
                              size: const Size(200, 320),
                              painter: _BottlePainter(fill: _fillAnim.value),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _MiniButton(
                          title: "−",
                          onTap: _dec,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniButton(
                          title: "+",
                          onTap: _inc,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Goal controls
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFEDEDED)),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          "Goal",
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        _IconSmallButton(
                          icon: Icons.remove,
                          onTap: _goalMinus,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "$goal",
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _IconSmallButton(
                          icon: Icons.add,
                          onTap: _goalPlus,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: const Color(0xFFEDEDED),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _MiniButton({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: const BorderSide(color: Color(0xFFEDEDED)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _IconSmallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconSmallButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: Colors.black,
          side: const BorderSide(color: Color(0xFFEDEDED)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}

/// Custom bottle painter with animated fill (0.0 to 1.0)
class _BottlePainter extends CustomPainter {
  final double fill;

  _BottlePainter({required this.fill});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // bottle outer
    final outerPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final bottleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.08, w * 0.56, h * 0.84),
      const Radius.circular(32),
    );

    // neck
    final neckRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.35, h * 0.02, w * 0.30, h * 0.10),
      const Radius.circular(18),
    );

    // draw outlines
    canvas.drawRRect(neckRect, outerPaint);
    canvas.drawRRect(bottleRect, outerPaint);

    // inner fill clip (inside bottle)
    final inner = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.24, h * 0.10, w * 0.52, h * 0.80),
      const Radius.circular(28),
    );

    final clipPath = Path()..addRRect(inner);

    canvas.save();
    canvas.clipPath(clipPath);

    // water fill
    final fillHeight = inner.height * fill;
    final topY = inner.bottom - fillHeight;

    final waterPaint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(inner.left, topY, inner.width, fillHeight),
      waterPaint,
    );

    // wave effect
    final wavePaint = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..style = PaintingStyle.fill;

    final wavePath = Path();
    final waveY = topY + 8;

    wavePath.moveTo(inner.left, waveY);

    for (double x = inner.left; x <= inner.right; x += 8) {
      final y = waveY + sin(x / 14) * 3;
      wavePath.lineTo(x, y);
    }

    wavePath.lineTo(inner.right, inner.bottom);
    wavePath.lineTo(inner.left, inner.bottom);
    wavePath.close();

    canvas.drawPath(wavePath, wavePaint);

    canvas.restore();

    // small label
    final textPainter = TextPainter(
      text: const TextSpan(
        text: "Tap",
        style: TextStyle(
          color: Colors.black54,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset((w - textPainter.width) / 2, h * 0.92),
    );
  }

  @override
  bool shouldRepaint(covariant _BottlePainter oldDelegate) {
    return oldDelegate.fill != fill;
  }
}
