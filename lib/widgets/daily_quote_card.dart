import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DailyQuoteCard extends StatefulWidget {
  const DailyQuoteCard({super.key});

  @override
  State<DailyQuoteCard> createState() => _DailyQuoteCardState();
}

class _DailyQuoteCardState extends State<DailyQuoteCard>
    with SingleTickerProviderStateMixin {
  bool expanded = false;
  bool saved = false;

  static const List<String> quotes = [
    "She believed in herself even when the world doubted her.",
    "A woman’s strength is quiet, deep, and unstoppable.",
    "You are not too much. You are enough.",
    "Strong women don’t wait for permission.",
    "Confidence looks good on you.",
    "Your power begins the moment you stop apologizing.",
    "She stood tall, even when she felt small.",
    "You are braver than you think.",
    "Your voice matters. Use it.",
    "Strength grows every time you choose yourself.",
    "A woman who chooses herself changes everything.",
    "Freedom is a woman owning her choices.",
    "Independent doesn’t mean alone.",
    "She built her own wings.",
    "You don’t need saving — you need space.",
    "Be free enough to be yourself.",
    "Your life, your rules.",
    "Independence is self-respect in action.",
    "Walk your path unapologetically.",
    "You were never meant to shrink.",
    "She rises every time she falls.",
    "Courage looks like continuing.",
    "Healing is a brave act.",
    "Even broken wings remember how to fly.",
    "Pain shaped her, but didn’t define her.",
    "Resilience is her second name.",
    "Every scar tells a survival story.",
    "She turns wounds into wisdom.",
    "Falling is not failing.",
    "You are worthy without proving anything.",
    "Self-love is revolutionary.",
    "Know your value, then add tax.",
    "She stopped chasing validation.",
    "You don’t need approval to shine.",
    "Your worth isn’t negotiable.",
    "Being yourself is your superpower.",
    "Confidence is quiet, not loud.",
    "You are allowed to take up space.",
    "Loving yourself is powerful.",
    "Dream boldly. You belong there.",
    "Her ambition scares those who lack it.",
    "Women can be soft and unstoppable.",
    "Your dreams are valid.",
    "She dares greatly.",
    "Go after what sets your soul on fire.",
    "Success has many faces — yours is one.",
    "You are allowed to want more.",
    "Build the life you imagine.",
    "She creates her own future.",
    "Growth is not linear — and that’s okay.",
    "Healing takes time, not weakness.",
    "Rest is productive.",
    "Becoming yourself is a journey.",
    "She blooms at her own pace.",
    "You are allowed to pause.",
    "Growth feels uncomfortable before it feels right.",
    "Every day you heal a little more.",
    "Progress is still progress.",
    "Gentle with yourself, always.",
  ];

  String getDailyQuote() {
    final today = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
    int hash = 0;

    for (int i = 0; i < today.length; i++) {
      hash = today.codeUnitAt(i) + ((hash << 5) - hash);
    }

    final index = hash.abs() % quotes.length;
    return quotes[index];
  }

  @override
  Widget build(BuildContext context) {
    final quote = getDailyQuote();

    return GestureDetector(
      onTap: () {
        setState(() => expanded = !expanded);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: Colors.black, width: 1.5),
        ),
        child: Column(
          children: [
            Text(
              quote,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),

            // Actions (expand/collapse)
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ActionItem(
                            icon: saved
                                ? FontAwesomeIcons.solidBookmark
                                : FontAwesomeIcons.bookmark,
                            label: "Save",
                            onTap: () {
                              setState(() => saved = !saved);
                            },
                          ),
                          const SizedBox(width: 22),
                          _ActionItem(
                            icon: FontAwesomeIcons.shareNodes,
                            label: "Share",
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Share coming soon"),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(height: 0),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            FaIcon(icon, size: 14, color: Colors.black),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
