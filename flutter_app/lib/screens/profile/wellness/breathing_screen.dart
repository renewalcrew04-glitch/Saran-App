import 'dart:async';
import 'package:flutter/material.dart';
import 'package:saran_app/services/wellness_streak_service.dart';

// ── Brand tokens ───────────────────────────────────────────────────────────────
const _kBg        = Color(0xFF060B14);
const _kSurface   = Color(0xFF0D1120);
const _kPrimary   = Color(0xFFFF8132);
const _kPrimaryLt = Color(0xFFFF9D5C);
const _kText      = Color(0xFFF1F5F9);
const _kMuted     = Color(0xFF64748B);
const _kSubtext   = Color(0xFF94A3B8);

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with SingleTickerProviderStateMixin {
  static const int totalSeconds = 60;
  static const Duration cycleDuration = Duration(milliseconds: 4000);

  bool started = false;
  bool done = false;

  int secondsLeft = totalSeconds;
  String phase = 'inhale';

  Timer? _timer;
  Timer? _phaseTimer;

  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: cycleDuration,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.45).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phaseTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      started = true;
      done = false;
      secondsLeft = totalSeconds;
      phase = 'inhale';
    });
    _controller.repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      setState(() => secondsLeft -= 1);
      if (secondsLeft <= 0) {
        t.cancel();
        _phaseTimer?.cancel();
        _controller.stop();
        setState(() {
          done = true;
          started = false;
          secondsLeft = 0;
        });
        await WellnessStreakService.markCompleted(
          activityId: 'breathing',
          activityTitle: '1-Minute Breathing',
        );
      }
    });

    _phaseTimer = Timer.periodic(cycleDuration, (_) {
      setState(() {
        phase = (phase == 'inhale') ? 'exhale' : 'inhale';
      });
    });
  }

  void _reset() {
    _timer?.cancel();
    _phaseTimer?.cancel();
    _controller.stop();
    setState(() {
      started = false;
      done = false;
      secondsLeft = totalSeconds;
      phase = 'inhale';
    });
  }

  @override
  Widget build(BuildContext context) {
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
                        '1-Minute Breathing',
                        style: TextStyle(
                          color: _kText,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '4-7-8 technique',
                        style: TextStyle(color: _kSubtext, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: !started && !done
                      ? _buildStart()
                      : done
                          ? _buildDone(context)
                          : _buildExercise(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Start state ──────────────────────────────────────────────────────────────
  Widget _buildStart() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Decorative circle
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF0D1120)],
            ),
            border: Border.all(color: const Color(0xFF3730A3), width: 1.5),
          ),
          alignment: Alignment.center,
          child: const Text('💨', style: TextStyle(fontSize: 56)),
        ),
        const SizedBox(height: 32),
        const Text(
          'Ready to breathe?',
          style: TextStyle(
            color: _kText,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Find a comfortable position.\nInhale for 4s · Hold for 7s · Exhale for 8s.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _kSubtext,
            fontSize: 14,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 36),
        GestureDetector(
          onTap: _start,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kPrimaryLt, _kPrimary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x50FF8132),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: const Text(
              'Begin',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Exercise state ───────────────────────────────────────────────────────────
  Widget _buildExercise() {
    final isInhale = phase == 'inhale';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Phase label
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            isInhale ? 'Inhale…' : 'Exhale…',
            key: ValueKey(phase),
            style: TextStyle(
              color: isInhale ? _kPrimaryLt : const Color(0xFF818CF8),
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Animated breathing circle
        ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isInhale
                    ? [
                        const Color(0xFFFF8132).withOpacity(0.3),
                        const Color(0xFFFF8132).withOpacity(0.05),
                      ]
                    : [
                        const Color(0xFF6366F1).withOpacity(0.3),
                        const Color(0xFF6366F1).withOpacity(0.05),
                      ],
              ),
              border: Border.all(
                color: isInhale ? _kPrimary : const Color(0xFF6366F1),
                width: 2.5,
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$secondsLeft',
                  style: const TextStyle(
                    color: _kText,
                    fontSize: 44,
                    fontWeight: FontWeight.w300,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'sec',
                  style: TextStyle(color: _kMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: 1 - (secondsLeft / totalSeconds),
            minHeight: 6,
            backgroundColor: const Color(0xFF1E2535),
            valueColor:
                const AlwaysStoppedAnimation<Color>(_kPrimary),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${totalSeconds - secondsLeft}s / ${totalSeconds}s',
          style: const TextStyle(color: _kMuted, fontSize: 12),
        ),
        const SizedBox(height: 32),

        // Stop button
        GestureDetector(
          onTap: _reset,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFF1E2535), width: 1.5),
            ),
            child: const Text(
              'Stop',
              style: TextStyle(color: _kMuted, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  // ── Done state ───────────────────────────────────────────────────────────────
  Widget _buildDone(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [_kPrimaryLt, _kPrimary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x50FF8132),
                blurRadius: 20,
                offset: Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            '✓',
            style: TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Well done 🌿',
          style: TextStyle(
            color: _kText,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'You took a moment for yourself.\nThat matters.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _kSubtext,
            fontSize: 14,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 36),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _start,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kPrimaryLt, _kPrimary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'Do again',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: const Color(0xFF1E2535), width: 1.5),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                      color: _kSubtext, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
