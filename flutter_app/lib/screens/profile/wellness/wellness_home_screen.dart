import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../services/wellness_streak_service.dart';

// ── Brand tokens (kept for non-theme colors) ──────────────────────────────────
const _kPrimary   = Color(0xFFFF8132);
const _kPrimaryLt = Color(0xFFFF9D5C);

// ── Mood data ─────────────────────────────────────────────────────────────────
const _kMoods = [
  (emoji: '😔', label: 'Low'),
  (emoji: '😐', label: 'Okay'),
  (emoji: '🙂', label: 'Good'),
  (emoji: '😊', label: 'Great'),
  (emoji: '🤩', label: 'Amazing'),
];

// ── Meditation session data ───────────────────────────────────────────────────
const _kSessions = [
  (
    title: 'Morning Calm',
    duration: '8 min',
    type: 'Guided',
    emoji: '☀️',
    gradient: [Color(0xFF0F766E), Color(0xFF0D4F4A)],
    route: '/wellness/breathing',
  ),
  (
    title: 'Stress Relief',
    duration: '12 min',
    type: 'Guided',
    emoji: '✨',
    gradient: [Color(0xFF6D28D9), Color(0xFF4C1D95)],
    route: '/wellness/calm-corner',
  ),
  (
    title: 'Sleep Well',
    duration: '20 min',
    type: 'Guided',
    emoji: '🌙',
    gradient: [Color(0xFF1E3A5F), Color(0xFF111827)],
    route: '/wellness/breathing',
  ),
];

// ── Self-care tips data ───────────────────────────────────────────────────────
const _kTips = [
  (
    tag: 'Anxiety',
    tagColor: Color(0xFF059669),
    title: '5-4-3-2-1 Grounding Technique',
    desc: 'Name 5 things you see, 4 you can touch, 3 you hear, 2 you smell, 1 you taste.',
    emoji: '',
    cta: '',
    route: '/wellness/grounding',
  ),
  (
    tag: 'Sleep',
    tagColor: Color(0xFF6D28D9),
    title: 'Digital Detox Hour',
    desc: 'Put your phone away for 60 minutes before bed. Read instead.',
    emoji: '',
    cta: '',
    route: '/wellness/eye-relax',
  ),
  (
    tag: '',
    tagColor: Color(0xFF000000),
    title: '4-7-8 Breathing',
    desc: 'Calm your nervous system in 2 minutes',
    emoji: '💨',
    cta: 'Start',
    route: '/wellness/breathing',
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────
class WellnessHomeScreen extends StatefulWidget {
  const WellnessHomeScreen({super.key});

  @override
  State<WellnessHomeScreen> createState() => _WellnessHomeScreenState();
}

class _WellnessHomeScreenState extends State<WellnessHomeScreen> {
  int _selectedMood = 3; // default: "Great"
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    final streak = await WellnessStreakService.getStreak();
    if (mounted) setState(() => _streak = streak);
  }

  String _todayLabel() {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final now = DateTime.now();
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final bg = isDark ? const Color(0xFF060B14) : Theme.of(context).scaffoldBackgroundColor;
    final text = isDark ? const Color(0xFFF1F5F9) : cs.onSurface;
    final subtext = isDark ? const Color(0xFF94A3B8) : cs.onSurfaceVariant;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            _buildHeader(text, subtext),
            _buildMoodCard(),
            _buildMeditationSection(context),
            _buildSelfCareTips(context),
            _buildQuickLinks(context),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(Color text, Color subtext) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wellness',
                style: TextStyle(
                  color: text,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _todayLabel(),
                style: TextStyle(
                  color: subtext,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Streak badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _kPrimary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kPrimary.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 5),
                Text(
                  '$_streak day streak',
                  style: const TextStyle(
                    color: _kPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Mood tracker card ────────────────────────────────────────────────────────
  Widget _buildMoodCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final muted = isDark ? const Color(0xFF64748B) : cs.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B4B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF3730A3), width: 1),
        ),
        child: Column(
          children: [
            const Text(
              'HOW ARE YOU FEELING TODAY?',
              style: TextStyle(
                color: Color(0xFFA5B4FC),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_kMoods.length, (i) {
                final mood = _kMoods[i];
                final selected = _selectedMood == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMood = i),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected
                              ? _kPrimary.withOpacity(0.25)
                              : Colors.transparent,
                          border: Border.all(
                            color: selected
                                ? _kPrimary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          mood.emoji,
                          style: TextStyle(
                            fontSize: selected ? 26 : 22,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        mood.label,
                        style: TextStyle(
                          color: selected ? _kPrimary : muted,
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ── Meditation sessions ──────────────────────────────────────────────────────
  Widget _buildMeditationSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final text = isDark ? const Color(0xFFF1F5F9) : cs.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
          child: Row(
            children: [
              Text(
                'Meditation Sessions',
                style: TextStyle(
                  color: text,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/wellness/calm-corner'),
                child: const Text(
                  'See all',
                  style: TextStyle(
                    color: _kPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 148,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _kSessions.length,
            itemBuilder: (_, i) {
              final s = _kSessions[i];
              return GestureDetector(
                onTap: () => context.push(s.route),
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: s.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.emoji, style: const TextStyle(fontSize: 26)),
                      const Spacer(),
                      Text(
                        s.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${s.duration} · ${s.type}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Self-care tips ───────────────────────────────────────────────────────────
  Widget _buildSelfCareTips(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final text = isDark ? const Color(0xFFF1F5F9) : cs.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            'Self-Care Tips',
            style: TextStyle(
              color: text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        ..._kTips.map((tip) => _buildTipCard(context, tip)),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildTipCard(BuildContext context, dynamic tip) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final card = isDark ? const Color(0xFF111827) : cs.surfaceContainerLow;
    final border = isDark ? const Color(0xFF1E2535) : cs.outlineVariant;

    final isBreathing = tip.cta.isNotEmpty;

    return GestureDetector(
      onTap: () => context.push(tip.route as String),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: isBreathing
            ? _buildBreathingTip(context, tip)
            : _buildRegularTip(context, tip),
      ),
    );
  }

  Widget _buildRegularTip(BuildContext context, dynamic tip) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final text = isDark ? const Color(0xFFF1F5F9) : cs.onSurface;
    final subtext = isDark ? const Color(0xFF94A3B8) : cs.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tip.tag.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: (tip.tagColor as Color).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: (tip.tagColor as Color).withOpacity(0.5)),
            ),
            child: Text(
              tip.tag as String,
              style: TextStyle(
                color: tip.tagColor as Color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        Text(
          tip.title as String,
          style: TextStyle(
            color: text,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        if ((tip.desc as String).isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            tip.desc as String,
            style: TextStyle(
              color: subtext,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBreathingTip(BuildContext context, dynamic tip) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final text = isDark ? const Color(0xFFF1F5F9) : cs.onSurface;
    final subtext = isDark ? const Color(0xFF94A3B8) : cs.onSurfaceVariant;

    return Row(
      children: [
        // Orange icon circle
        Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [_kPrimaryLt, _kPrimary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          alignment: Alignment.center,
          child: const Text('💨', style: TextStyle(fontSize: 22)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tip.title as String,
                style: TextStyle(
                  color: text,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                tip.desc as String,
                style: TextStyle(
                  color: subtext,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => context.push(tip.route as String),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Start',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Quick links (existing wellness features) ─────────────────────────────────
  Widget _buildQuickLinks(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final text = isDark ? const Color(0xFFF1F5F9) : cs.onSurface;

    const links = [
      (icon: Icons.nightlight_outlined, label: 'S-Mind\nJournal', route: '/wellness/mind-journal', color: Color(0xFF6D28D9)),
      (icon: Icons.spa_outlined, label: 'Calm\nCorner', route: '/wellness/calm-corner', color: Color(0xFF0F766E)),
      (icon: Icons.favorite_border, label: 'S-Cycle', route: '/wellness/s-cycle', color: Color(0xFFBE185D)),
      (icon: Icons.water_drop_outlined, label: 'Hydration', route: '/wellness/hydration', color: Color(0xFF0369A1)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Text(
            'Wellness Tools',
            style: TextStyle(
              color: text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.4,
            children: links.map((link) {
              return GestureDetector(
                onTap: () => context.push(link.route),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: link.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: link.color.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(link.icon,
                          color: link.color, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          link.label,
                          style: TextStyle(
                            color: link.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
