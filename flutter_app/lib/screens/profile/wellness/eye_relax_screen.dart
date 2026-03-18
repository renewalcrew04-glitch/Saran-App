import 'dart:async';
import 'package:flutter/material.dart';
import 'package:saran_app/services/wellness_streak_service.dart';

// ── Brand tokens ───────────────────────────────────────────────────────────────
const _kBg        = Color(0xFF060B14);
const _kCard      = Color(0xFF111827);
const _kBorder    = Color(0xFF1E2535);
const _kPrimary   = Color(0xFFFF8132);
const _kPrimaryLt = Color(0xFFFF9D5C);
const _kText      = Color(0xFFF1F5F9);
const _kMuted     = Color(0xFF64748B);
const _kSubtext   = Color(0xFF94A3B8);

class EyeRelaxScreen extends StatefulWidget {
  const EyeRelaxScreen({super.key});

  @override
  State<EyeRelaxScreen> createState() => _EyeRelaxScreenState();
}

class _EyeRelaxScreenState extends State<EyeRelaxScreen> {
  static const _steps = [
    (
      text: 'Blink slowly 10 times',
      emoji: '👁️',
      instruction: 'Close and open your eyes slowly and gently.',
      duration: 8,
      color: Color(0xFF0891B2),
    ),
    (
      text: 'Look at something far away',
      emoji: '🔭',
      instruction: 'Find an object at least 6 metres away and focus on it.',
      duration: 6,
      color: Color(0xFF7C3AED),
    ),
    (
      text: 'Focus on something near',
      emoji: '🔍',
      instruction: 'Now bring your gaze to something close, like your hand.',
      duration: 6,
      color: Color(0xFF059669),
    ),
    (
      text: 'Close your eyes and rest',
      emoji: '😌',
      instruction: 'Let your eyes rest completely. Feel the darkness.',
      duration: 6,
      color: Color(0xFF6D28D9),
    ),
  ];

  int _stepIndex = 0;
  int _seconds = 8;
  bool _done = false;
  bool _started = false;

  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startExercise() {
    setState(() {
      _started = true;
      _stepIndex = 0;
      _done = false;
    });
    _startStep();
  }

  Future<void> _startStep() async {
    if (_done) return;
    _seconds = _steps[_stepIndex].duration;
    setState(() {});

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      setState(() => _seconds -= 1);
      if (_seconds <= 0) {
        t.cancel();
        if (_stepIndex == _steps.length - 1) {
          setState(() => _done = true);
          await WellnessStreakService.markCompleted(
            activityId: 'eye_relax',
            activityTitle: 'Eye Relaxation',
          );
        } else {
          setState(() => _stepIndex += 1);
          _startStep();
        }
      }
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
                        'Eye Relaxation',
                        style: TextStyle(
                          color: _kText,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '4-step eye care routine',
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
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: !_started
                      ? _buildStart()
                      : _done
                          ? _buildDone(context)
                          : _buildStep(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Start ──────────────────────────────────────────────────────────────────
  Widget _buildStart() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFF1E3A5F), Color(0xFF0D1120)],
            ),
            border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
          ),
          alignment: Alignment.center,
          child: const Text('👁️', style: TextStyle(fontSize: 52)),
        ),
        const SizedBox(height: 30),
        const Text(
          'Rest your eyes',
          style: TextStyle(
            color: _kText,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'A short 4-step routine to relieve eye strain.\nTakes about 30 seconds.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _kSubtext,
            fontSize: 14,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 36),

        // Steps preview
        ..._steps.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: e.value.color.withOpacity(0.15),
                      border: Border.all(
                          color: e.value.color.withOpacity(0.4)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${e.key + 1}',
                      style: TextStyle(
                        color: e.value.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.value.text,
                      style: const TextStyle(
                          color: _kSubtext, fontSize: 13),
                    ),
                  ),
                  Text(
                    '${e.value.duration}s',
                    style: const TextStyle(color: _kMuted, fontSize: 12),
                  ),
                ],
              ),
            )),

        const SizedBox(height: 28),
        GestureDetector(
          onTap: _startExercise,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 48, vertical: 15),
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
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: const Text(
              'Start',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step ───────────────────────────────────────────────────────────────────
  Widget _buildStep() {
    final step = _steps[_stepIndex];
    final progress =
        1 - (_seconds / step.duration.toDouble());

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Step dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_steps.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == _stepIndex ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i <= _stepIndex
                    ? _steps[_stepIndex].color
                    : const Color(0xFF1E2535),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: 36),

        // Timer circle
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 5,
                backgroundColor: const Color(0xFF1E2535),
                valueColor:
                    AlwaysStoppedAnimation<Color>(step.color),
              ),
            ),
            Column(
              children: [
                Text(
                  step.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_seconds',
                  style: TextStyle(
                    color: step.color,
                    fontSize: 36,
                    fontWeight: FontWeight.w300,
                    height: 1,
                  ),
                ),
                Text(
                  'sec',
                  style: const TextStyle(
                      color: _kMuted, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Step title
        Text(
          step.text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: step.color,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),

        // Instruction
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder),
          ),
          child: Text(
            step.instruction,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _kSubtext,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Step ${_stepIndex + 1} of ${_steps.length}',
          style: const TextStyle(color: _kMuted, fontSize: 12),
        ),
      ],
    );
  }

  // ── Done ───────────────────────────────────────────────────────────────────
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
          'Eyes refreshed ✨',
          style: TextStyle(
            color: _kText,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Thank you for taking care of your vision.\nRepeat this every hour of screen time.',
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
              onTap: _startExercise,
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
                  'Again',
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
