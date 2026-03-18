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

class GroundingScreen extends StatefulWidget {
  const GroundingScreen({super.key});

  @override
  State<GroundingScreen> createState() => _GroundingScreenState();
}

class _GroundingScreenState extends State<GroundingScreen>
    with SingleTickerProviderStateMixin {
  static const _steps = [
    (
      count: 5,
      sense: 'See',
      emoji: '👁️',
      prompt: 'Look around and name 5 things you can see right now.',
      color: Color(0xFF0891B2),
    ),
    (
      count: 4,
      sense: 'Touch',
      emoji: '🤚',
      prompt: 'Feel 4 things you can physically touch right now.',
      color: Color(0xFF7C3AED),
    ),
    (
      count: 3,
      sense: 'Hear',
      emoji: '👂',
      prompt: 'Listen and name 3 sounds you can hear around you.',
      color: Color(0xFF059669),
    ),
    (
      count: 2,
      sense: 'Smell',
      emoji: '👃',
      prompt: 'Take a breath. Name 2 things you can smell.',
      color: Color(0xFFD97706),
    ),
    (
      count: 1,
      sense: 'Taste',
      emoji: '👅',
      prompt: 'Focus on your mouth. Name 1 thing you can taste.',
      color: Color(0xFFBE185D),
    ),
  ];

  int _stepIndex = 0;
  bool _completed = false;

  late final AnimationController _anim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(
            begin: const Offset(0.1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_stepIndex == _steps.length - 1) {
      setState(() => _completed = true);
      await WellnessStreakService.markCompleted(
        activityId: 'grounding',
        activityTitle: '5-4-3-2-1 Grounding',
      );
    } else {
      _anim.reset();
      setState(() => _stepIndex += 1);
      _anim.forward();
    }
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
                        '5-4-3-2-1 Grounding',
                        style: TextStyle(
                          color: _kText,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Return to the present moment',
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
                  child:
                      _completed ? _buildDone(context) : _buildStep(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    final step = _steps[_stepIndex];

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Step indicators
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
                        ? step.color
                        : const Color(0xFF1E2535),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 40),

            // Big count circle
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    step.color.withOpacity(0.25),
                    step.color.withOpacity(0.05),
                  ],
                ),
                border: Border.all(color: step.color, width: 2.5),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(step.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 4),
                  Text(
                    '${step.count}',
                    style: TextStyle(
                      color: step.color,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Sense label
            Text(
              step.sense,
              style: TextStyle(
                color: step.color,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            // Prompt
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E2535)),
              ),
              child: Text(
                step.prompt,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _kText,
                  fontSize: 15,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 36),

            // Next / Done button
            GestureDetector(
              onTap: _next,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 52, vertical: 15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kPrimaryLt, _kPrimary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40FF8132),
                      blurRadius: 14,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  _stepIndex == _steps.length - 1 ? 'Complete' : 'Done',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Text(
              'Step ${_stepIndex + 1} of ${_steps.length}',
              style: const TextStyle(color: _kMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

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
              fontSize: 42,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'You are grounded 🌱',
          style: TextStyle(
            color: _kText,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'You are here, in this moment.\nNothing else is required right now.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _kSubtext,
            fontSize: 14,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 36),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kPrimaryLt, _kPrimary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              'Back to Calm Corner',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
