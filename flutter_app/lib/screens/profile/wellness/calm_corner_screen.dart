import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ── Brand tokens ───────────────────────────────────────────────────────────────
const _kBg      = Color(0xFF060B14);
const _kCard    = Color(0xFF111827);
const _kBorder  = Color(0xFF1E2535);
const _kPrimary = Color(0xFFFF8132);
const _kPrimaryLt = Color(0xFFFF9D5C);
const _kText    = Color(0xFFF1F5F9);
const _kMuted   = Color(0xFF64748B);
const _kSubtext = Color(0xFF94A3B8);

class CalmCornerScreen extends StatelessWidget {
  const CalmCornerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
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
                        'Calm Corner',
                        style: TextStyle(
                          color: _kText,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Micro-calming exercises',
                        style: TextStyle(color: _kSubtext, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Intro banner ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF4338CA), width: 1),
                ),
                child: const Row(
                  children: [
                    Text('🧘', style: TextStyle(fontSize: 28)),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Take a breath',
                            style: TextStyle(
                              color: Color(0xFFE0E7FF),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Pick any exercise below to calm your mind.',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Exercise cards ───────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                children: [
                  _ExerciseCard(
                    emoji: '💨',
                    title: '1-Minute Breathing',
                    desc: 'Slow your breath, clear your mind.',
                    duration: '1 min',
                    gradient: const [Color(0xFF0F766E), Color(0xFF0D4F4A)],
                    onTap: () => context.push('/wellness/breathing'),
                  ),
                  _ExerciseCard(
                    emoji: '👁️',
                    title: '5-4-3-2-1 Grounding',
                    desc: 'Return to the present moment.',
                    duration: '5 min',
                    gradient: const [Color(0xFF6D28D9), Color(0xFF4C1D95)],
                    onTap: () => context.push('/wellness/grounding'),
                  ),
                  _ExerciseCard(
                    emoji: '👀',
                    title: 'Eye Relaxation',
                    desc: 'Rest your eyes and reduce screen fatigue.',
                    duration: '30 sec',
                    gradient: const [Color(0xFF1E3A5F), Color(0xFF111827)],
                    onTap: () => context.push('/wellness/eye-relax'),
                  ),
                  const SizedBox(height: 12),
                  // Tip card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _kBorder),
                    ),
                    child: const Row(
                      children: [
                        Text('💡', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Even 60 seconds of mindful breathing can lower your cortisol levels.',
                            style: TextStyle(
                              color: _kSubtext,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
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
}

class _ExerciseCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String desc;
  final String duration;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ExerciseCard({
    required this.emoji,
    required this.title,
    required this.desc,
    required this.duration,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            // Gradient icon circle
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _kText,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: const TextStyle(
                      color: _kSubtext,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kPrimary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: _kPrimary.withOpacity(0.4)),
                  ),
                  child: Text(
                    duration,
                    style: const TextStyle(
                      color: _kPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: _kMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
