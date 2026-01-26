import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:saran_app/services/games_streak_service.dart';

class GamesHomeScreen extends StatefulWidget {
  const GamesHomeScreen({super.key});

  @override
  State<GamesHomeScreen> createState() => _GamesHomeScreenState();
}

class _GamesHomeScreenState extends State<GamesHomeScreen> {
  int _streak = 0;
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await GamesStreakService.getStreak();
    final h = await GamesStreakService.getHistory();
    if (!mounted) return;
    setState(() {
      _streak = s;
      _history = h;
    });
  }

  Future<void> _openGame({
    required String id,
    required String title,
    required String route,
  }) async {
    await GamesStreakService.recordPlay(gameId: id, gameTitle: title);
    await _load();
    if (!mounted) return;
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final games = [
      _GameItem(
        id: "garden",
        title: "S-Garden",
        desc: "Grow positivity gently",
        icon: Icons.spa_outlined,
        route: "/games/garden",
      ),
      _GameItem(
        id: "soundboard",
        title: "S-Zen Soundboard",
        desc: "Calming sounds for peace",
        icon: Icons.graphic_eq_outlined,
        route: "/games/soundboard",
      ),
      _GameItem(
        id: "mirror",
        title: "S-Mirror Challenge",
        desc: "Self-love reflection",
        icon: Icons.auto_awesome_outlined,
        route: "/games/mirror",
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("S-Games"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _StreakCard(streak: _streak),
            const SizedBox(height: 14),

            Expanded(
              child: ListView(
                children: [
                  const Text(
                    "Play",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),

                  ...games.map(
                    (g) => _GameCard(
                      title: g.title,
                      desc: g.desc,
                      icon: g.icon,
                      onTap: () => _openGame(
                        id: g.id,
                        title: g.title,
                        route: g.route,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "History",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await GamesStreakService.clearHistory();
                          await _load();
                        },
                        child: const Text(
                          "Clear",
                          style: TextStyle(color: Colors.black),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (_history.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFEDEDED)),
                      ),
                      child: const Text(
                        "No history yet. Open a game to start your streak ✨",
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  else
                    ..._history.take(8).map((raw) {
                      final parts = raw.split("|");
                      final time = parts.isNotEmpty ? parts[0] : "";
                      final title = parts.length >= 3 ? parts[2] : "Game";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFEDEDED)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.history, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              _shortTime(time),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return "";
    return "${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, "0")}:${dt.minute.toString().padLeft(2, "0")}";
  }
}

class _GameItem {
  final String id;
  final String title;
  final String desc;
  final IconData icon;
  final String route;

  _GameItem({
    required this.id,
    required this.title,
    required this.desc,
    required this.icon,
    required this.route,
  });
}

class _StreakCard extends StatelessWidget {
  final int streak;

  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Streak: $streak day${streak == 1 ? "" : "s"}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
          const Text(
            "Keep going",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String desc;
  final IconData icon;
  final VoidCallback onTap;

  const _GameCard({
    required this.title,
    required this.desc,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFEDEDED)),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: Colors.black),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }
}
