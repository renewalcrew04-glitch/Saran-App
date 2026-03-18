import 'package:flutter/material.dart';
import 'package:saran_app/services/games_streak_service.dart';
import 'package:saran_app/screens/profile/games/memory_bloom_screen.dart';
import 'package:saran_app/screens/profile/games/word_weave_screen.dart';
import 'package:saran_app/screens/profile/games/mind_quiz_screen.dart';
import 'package:saran_app/screens/profile/games/zen_puzzle_screen.dart';
import 'package:saran_app/screens/profile/games/pattern_lock_screen.dart';
import 'package:saran_app/screens/profile/games/creative_color_screen.dart';

// ── Brand tokens (kept for non-theme colors) ────────────────────────────────────
const _kOrange   = Color(0xFFFF8132);
const _kOrangeLt = Color(0xFFFF9D5C);

class GamesHomeScreen extends StatefulWidget {
  const GamesHomeScreen({super.key});

  @override
  State<GamesHomeScreen> createState() => _GamesHomeScreenState();
}

class _GamesHomeScreenState extends State<GamesHomeScreen> {
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await GamesStreakService.getStreak();
    if (!mounted) return;
    setState(() => _streak = s);
  }

  Future<void> _openGame({
    required String id,
    required String title,
    required Widget screen,
  }) async {
    await GamesStreakService.recordPlay(gameId: id, gameTitle: title);
    await _load();
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  static final _games = [
    _GameDef(
      id: 'memory_bloom',
      title: 'Memory Bloom',
      desc: 'Match flower pairs before time runs out',
      emoji: '🌸',
      screen: const MemoryBloomScreen(),
      badge: 'Popular',
      gradient: [const Color(0xFF7C3AED), const Color(0xFF5B21B6)],
    ),
    _GameDef(
      id: 'word_weave',
      title: 'Word Weave',
      desc: 'Build words from the daily letter grid',
      emoji: '✏️',
      screen: const WordWeaveScreen(),
      badge: 'Daily',
      gradient: [const Color(0xFF0891B2), const Color(0xFF0E7490)],
    ),
    _GameDef(
      id: 'mind_quiz',
      title: 'Mind Quiz',
      desc: 'Test your knowledge with brain teasers',
      emoji: '🧠',
      screen: const MindQuizScreen(),
      badge: 'New',
      gradient: [const Color(0xFF7C3AED), const Color(0xFF4C1D95)],
    ),
    _GameDef(
      id: 'zen_puzzle',
      title: 'Zen Puzzle',
      desc: 'Calming sliding puzzle with beautiful art',
      emoji: '🧩',
      screen: const ZenPuzzleScreen(),
      badge: null,
      gradient: [const Color(0xFF059669), const Color(0xFF065F46)],
    ),
    _GameDef(
      id: 'pattern_lock',
      title: 'Pattern Lock',
      desc: 'Spot the pattern, unlock the sequence',
      emoji: '👾',
      screen: const PatternLockScreen(),
      badge: null,
      gradient: [const Color(0xFFEA580C), const Color(0xFFB91C1C)],
    ),
    _GameDef(
      id: 'creative_color',
      title: 'Creative Color',
      desc: 'Color-by-number relaxing art sessions',
      emoji: '🎨',
      screen: const CreativeColorScreen(),
      badge: null,
      gradient: [const Color(0xFF1E40AF), const Color(0xFF1E3A8A)],
    ),
  ];

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
        child: CustomScrollView(
          slivers: [
            // ── Header ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: subtext, size: 20),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(width: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mini Games',
                          style: TextStyle(
                            color: text,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Relax, play, and recharge your mind',
                          style: TextStyle(
                              color: subtext, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Streak card ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: _StreakCard(streak: _streak),
              ),
            ),

            // ── All Games label ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 14),
                child: Text(
                  'All Games',
                  style: TextStyle(
                    color: text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),

            // ── Game grid ────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final g = _games[i];
                    return _GameCard(
                      game: g,
                      onTap: () => _openGame(
                        id: g.id,
                        title: g.title,
                        screen: g.screen,
                      ),
                    );
                  },
                  childCount: _games.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data class ──────────────────────────────────────────────────────────────────
class _GameDef {
  final String id;
  final String title;
  final String desc;
  final String emoji;
  final Widget screen;
  final String? badge;
  final List<Color> gradient;

  const _GameDef({
    required this.id,
    required this.title,
    required this.desc,
    required this.emoji,
    required this.screen,
    required this.badge,
    required this.gradient,
  });
}

// ── Streak Card ─────────────────────────────────────────────────────────────────
class _StreakCard extends StatelessWidget {
  final int streak;
  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final text = isDark ? const Color(0xFFF1F5F9) : cs.onSurface;
    final subtext = isDark ? const Color(0xFF94A3B8) : cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1040), Color(0xFF0D1120)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2D1B69)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2D1B69),
              border: Border.all(
                  color: const Color(0xFFFFAC33).withOpacity(0.4)),
            ),
            alignment: Alignment.center,
            child: const Text('🏆', style: TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR STREAK',
                  style: TextStyle(
                    color: _kOrange,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  streak == 0
                      ? 'Start your streak!'
                      : '$streak day${streak == 1 ? '' : 's'} in a row!',
                  style: TextStyle(
                    color: text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  streak == 0
                      ? 'Play a game to get started'
                      : 'Play today to keep your streak going',
                  style: TextStyle(
                    color: subtext,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Game Card ───────────────────────────────────────────────────────────────────
class _GameCard extends StatelessWidget {
  final _GameDef game;
  final VoidCallback onTap;

  const _GameCard({required this.game, required this.onTap});

  Color get _badgeColor {
    switch (game.badge) {
      case 'Popular':
        return const Color(0xFFEC4899);
      case 'Daily':
        return const Color(0xFF10B981);
      case 'New':
        return const Color(0xFF6366F1);
      default:
        return _kOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: game.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji + badge row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(game.emoji,
                    style: const TextStyle(fontSize: 32)),
                const Spacer(),
                if (game.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _badgeColor.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _badgeColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      game.badge!,
                      style: TextStyle(
                        color: _badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),

            const Spacer(),

            // Title
            Text(
              game.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),

            // Description
            Text(
              game.desc,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Play Now button
            Container(
              width: double.infinity,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.white.withOpacity(0.15)),
              ),
              child: const Text(
                'Play Now',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
