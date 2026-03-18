import 'dart:math';
import 'package:flutter/material.dart';
import 'package:saran_app/services/hydration_service.dart';
import 'package:saran_app/services/wellness_streak_service.dart';

// ── Brand tokens ───────────────────────────────────────────────────────────────
const _kBg        = Color(0xFF060B14);
const _kSurface   = Color(0xFF0D1120);
const _kCard      = Color(0xFF111827);
const _kBorder    = Color(0xFF1E2535);
const _kPrimary   = Color(0xFFFF8132);
const _kPrimaryLt = Color(0xFFFF9D5C);
const _kText      = Color(0xFFF1F5F9);
const _kMuted     = Color(0xFF64748B);
const _kSubtext   = Color(0xFF94A3B8);
const _kWater     = Color(0xFF0891B2);
const _kWaterLt   = Color(0xFF38BDF8);

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

  double get progress => goal <= 0 ? 0 : (count / goal).clamp(0.0, 1.0);

  Future<void> _load() async {
    final data = await HydrationService.loadToday();
    goal = data['goal'] ?? 8;
    count = data['count'] ?? 0;
    if (!mounted) return;
    setState(() => loading = false);
    _animateTo(progress);
  }

  Future<void> _save() async =>
      HydrationService.saveToday(goal: goal, count: count);

  void _animateTo(double target) {
    final current = _fillAnim.value;
    _fillAnim =
        Tween<double>(begin: current, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward(from: 0);
  }

  Future<void> _markWellness() async {
    if (markedToday) return;
    await WellnessStreakService.markCompleted(
        activityId: 'hydration', activityTitle: 'Hydration Tap');
    markedToday = true;
  }

  Future<void> _tap() async {
    if (count >= goal) return;
    setState(() => count += 1);
    await _markWellness();
    await _save();
    _animateTo(progress);
  }

  Future<void> _inc() async {
    if (count >= goal) return;
    setState(() => count += 1);
    await _markWellness();
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
    if (count > goal) count = goal;
    await _save();
    _animateTo(progress);
  }

  @override
  Widget build(BuildContext context) {
    final done = count >= goal;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: _kSubtext, size: 20),
                  ),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hydration Tap',
                        style: TextStyle(
                          color: _kText,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Daily water tracker',
                        style: TextStyle(color: _kSubtext, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            loading
                ? const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                          color: _kPrimary, strokeWidth: 2.5),
                    ),
                  )
                : Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
                      child: Column(
                        children: [
                          // Status card
                          Container(
                            padding: const EdgeInsets.fromLTRB(
                                20, 18, 20, 20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: done
                                    ? [
                                        const Color(0xFF0F766E),
                                        const Color(0xFF0D4F4A)
                                      ]
                                    : [
                                        const Color(0xFF1E3A5F),
                                        const Color(0xFF0D1120),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: done
                                    ? const Color(0xFF14B8A6)
                                    : _kWater,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$count / $goal',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 40,
                                        fontWeight: FontWeight.w300,
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      done
                                          ? '🎉 Goal reached!'
                                          : '${goal - count} more to go',
                                      style: TextStyle(
                                        color: Colors.white
                                            .withOpacity(0.75),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  done ? '💧' : '🫧',
                                  style:
                                      const TextStyle(fontSize: 44),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Progress bar
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Progress',
                                      style: TextStyle(
                                          color: _kSubtext,
                                          fontSize: 12,
                                          fontWeight:
                                              FontWeight.w600)),
                                  Text(
                                    '${(progress * 100).round()}%',
                                    style: const TextStyle(
                                        color: _kWaterLt,
                                        fontSize: 12,
                                        fontWeight:
                                            FontWeight.w700),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(8),
                                child: AnimatedBuilder(
                                  animation: _fillAnim,
                                  builder: (_, __) =>
                                      LinearProgressIndicator(
                                    value: _fillAnim.value,
                                    minHeight: 10,
                                    backgroundColor:
                                        const Color(0xFF1E2535),
                                    valueColor:
                                        const AlwaysStoppedAnimation<
                                            Color>(_kWater),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Bottle
                          GestureDetector(
                            onTap: _tap,
                            child: AnimatedBuilder(
                              animation: _fillAnim,
                              builder: (_, __) => CustomPaint(
                                size: const Size(200, 290),
                                painter: _BottlePainter(
                                    fill: _fillAnim.value),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap bottle to drink',
                            style: TextStyle(
                                color: _kMuted, fontSize: 12),
                          ),
                          const SizedBox(height: 24),

                          // +/- count buttons
                          Row(
                            children: [
                              Expanded(
                                child: _ActionButton(
                                  label: '−',
                                  onTap: _dec,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ActionButton(
                                  label: '+',
                                  onTap: _inc,
                                  primary: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Goal row
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 14),
                            decoration: BoxDecoration(
                              color: _kCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _kBorder),
                            ),
                            child: Row(
                              children: [
                                const Text('🎯',
                                    style:
                                        TextStyle(fontSize: 18)),
                                const SizedBox(width: 10),
                                const Text(
                                  'Daily Goal',
                                  style: TextStyle(
                                    color: _kText,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const Spacer(),
                                _SmallIconBtn(
                                    icon: Icons.remove,
                                    onTap: _goalMinus),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 14),
                                  child: Text(
                                    '$goal',
                                    style: const TextStyle(
                                      color: _kText,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                _SmallIconBtn(
                                    icon: Icons.add,
                                    onTap: _goalPlus),
                              ],
                            ),
                          ),

                          // Glass dots
                          const SizedBox(height: 16),
                          _buildGlassDots(),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassDots() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(goal, (i) {
        final filled = i < count;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? _kWater : const Color(0xFF111827),
            border: Border.all(
              color: filled ? _kWaterLt : const Color(0xFF1E2535),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '💧',
            style: TextStyle(
              fontSize: 14,
              color: filled ? Colors.white : Colors.transparent,
            ),
          ),
        );
      }),
    );
  }
}

// ── Large action button ────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool primary;

  const _ActionButton({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: primary
              ? const LinearGradient(
                  colors: [_kWater, Color(0xFF0369A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: primary ? null : const Color(0xFF111827),
          borderRadius: BorderRadius.circular(14),
          border: primary
              ? null
              : Border.all(color: const Color(0xFF1E2535)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: primary ? Colors.white : _kSubtext,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

// ── Small icon button ──────────────────────────────────────────────────────────
class _SmallIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SmallIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFF0D1120),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1E2535)),
        ),
        child: Icon(icon, size: 16, color: _kSubtext),
      ),
    );
  }
}

// ── Bottle painter ─────────────────────────────────────────────────────────────
class _BottlePainter extends CustomPainter {
  final double fill;
  _BottlePainter({required this.fill});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // bottle body rrect
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.20, h * 0.10, w * 0.60, h * 0.82),
      const Radius.circular(36),
    );
    // neck
    final neckRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.34, h * 0.02, w * 0.32, h * 0.12),
      const Radius.circular(16),
    );

    // fill clip
    final innerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.12, w * 0.56, h * 0.78),
      const Radius.circular(30),
    );

    // draw fill
    if (fill > 0) {
      final clipPath = Path()..addRRect(innerRect);
      canvas.save();
      canvas.clipPath(clipPath);

      final fillH = innerRect.height * fill;
      final topY = innerRect.bottom - fillH;

      canvas.drawRect(
        Rect.fromLTWH(innerRect.left, topY, innerRect.width, fillH),
        Paint()
          ..color = const Color(0xFF0891B2)
          ..style = PaintingStyle.fill,
      );

      // wave
      final wavePaint = Paint()
        ..color = Colors.white.withOpacity(0.12)
        ..style = PaintingStyle.fill;
      final wavePath = Path();
      final waveY = topY + 6;
      wavePath.moveTo(innerRect.left, waveY);
      for (double x = innerRect.left; x <= innerRect.right; x += 6) {
        wavePath.lineTo(x, waveY + sin(x / 12) * 4);
      }
      wavePath.lineTo(innerRect.right, innerRect.bottom);
      wavePath.lineTo(innerRect.left, innerRect.bottom);
      wavePath.close();
      canvas.drawPath(wavePath, wavePaint);

      canvas.restore();
    }

    // bottle outline
    final outlinePaint = Paint()
      ..color = const Color(0xFF1E2535)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(neckRect, outlinePaint);
    canvas.drawRRect(bodyRect, outlinePaint);

    // percentage label inside bottle
    if (fill > 0.1) {
      final pct = '${(fill * 100).round()}%';
      final tp = TextPainter(
        text: TextSpan(
          text: pct,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          (w - tp.width) / 2,
          innerRect.bottom - innerRect.height * fill / 2 - tp.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BottlePainter old) => old.fill != fill;
}
