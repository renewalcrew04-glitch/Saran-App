import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../utils/daily_quotes.dart';

class DailyQuoteCard extends StatefulWidget {
  const DailyQuoteCard({super.key});

  @override
  State<DailyQuoteCard> createState() => _DailyQuoteCardState();
}

class _DailyQuoteCardState extends State<DailyQuoteCard> {
  bool expanded = false;
  bool saved = false;

  @override
  Widget build(BuildContext context) {
    final quote = getDailyQuote();

    return GestureDetector(
      onTap: () => setState(() => expanded = !expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF3730A3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF4338CA), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF312E81).withValues(alpha: 0.40),
              blurRadius: 18,
              spreadRadius: -4,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header label
            const Text(
              "TODAY'S AFFIRMATION",
              style: TextStyle(
                color: Color(0xFFA5B4FC),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 12),

            // Quote text
            Text(
              '"$quote"',
              style: const TextStyle(
                color: Color(0xFFF1F5F9),
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),

            // Expandable Save / Share
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _CardButton(
                              label: saved ? 'Saved ✓' : 'Save',
                              icon: saved
                                  ? FontAwesomeIcons.solidBookmark
                                  : FontAwesomeIcons.bookmark,
                              onTap: () => setState(() => saved = !saved),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _CardButton(
                              label: 'Share',
                              icon: FontAwesomeIcons.shareNodes,
                              onTap: () =>
                                  ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Share coming soon')),
                              ),
                            ),
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

class _CardButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  const _CardButton({
    required this.label,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF4338CA).withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              FaIcon(icon!, size: 13, color: const Color(0xFFF1F5F9)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFF1F5F9),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
