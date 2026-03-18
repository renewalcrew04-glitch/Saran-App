import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../utils/daily_quotes.dart';

// ── Brand tokens (dark-only, kept for past-card gradients) ────────────────────
// Theme-aware colors are derived from Theme.of(context) in each build method.

// S-Daily launch epoch – Day 1 was 25 Dec 2025
final _kEpoch = DateTime(2025, 12, 25);

// ── Card colour palette (cycles through past days) ────────────────────────────
const _kPastColors = [
  [Color(0xFF4C1D95), Color(0xFF6D28D9)],  // violet/purple
  [Color(0xFF134E4A), Color(0xFF0F766E)],  // dark teal
  [Color(0xFF14532D), Color(0xFF166534)],  // dark green
  [Color(0xFF78350F), Color(0xFF92400E)],  // rust / brown
  [Color(0xFF1E1B4B), Color(0xFF3730A3)],  // deep indigo
  [Color(0xFF701A75), Color(0xFF86198F)],  // dark magenta
];

// ── Helpers ───────────────────────────────────────────────────────────────────

String _quoteForDate(DateTime date) => getQuoteForDate(date);

/// Day number since epoch (Day 1 = epoch).
int _dayNumber(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  return d.difference(_kEpoch).inDays + 1;
}

/// Short date label, e.g. "MAR 15"
String _shortDate(DateTime d) {
  const months = [
    'JAN','FEB','MAR','APR','MAY','JUN',
    'JUL','AUG','SEP','OCT','NOV','DEC',
  ];
  return '${months[d.month - 1]} ${d.day}';
}

/// Full weekday + date label, e.g. "Mon, March 16"
String _fullDate(DateTime d) {
  const days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
  const months = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December',
  ];
  return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
}

// ── Screen ────────────────────────────────────────────────────────────────────
class SDailyScreen extends StatefulWidget {
  const SDailyScreen({super.key});

  @override
  State<SDailyScreen> createState() => _SDailyScreenState();
}

class _SDailyScreenState extends State<SDailyScreen> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final today     = DateTime.now();
    final todayQuote = _quoteForDate(today);
    final dayNum    = _dayNumber(today);

    // Build past-day entries (most recent first, up to 5)
    final pastDays = List.generate(5, (i) {
      final d = today.subtract(Duration(days: i + 1));
      return (date: d, quote: _quoteForDate(d));
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(today, dayNum),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                children: [
                  // ── Today's featured card ──────────────────────────────
                  _TodayCard(
                    quote: todayQuote,
                    saved: _saved,
                    onSave: () => setState(() => _saved = !_saved),
                    onShare: () => SharePlus.instance.share(
                      ShareParams(text: '"$todayQuote"\n\n— S-Daily by SARAN'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Past days ──────────────────────────────────────────
                  ...pastDays.asMap().entries.map((e) {
                    final colors = _kPastColors[e.key % _kPastColors.length];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PastDayCard(
                        date: e.value.date,
                        quote: e.value.quote,
                        gradientColors: colors,
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

  // ── Custom header ────────────────────────────────────────────────────────
  Widget _buildHeader(DateTime today, int dayNum) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'S-Daily',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_fullDate(today)} · Day $dayNum',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: cs.onSurfaceVariant,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Today's featured affirmation card ─────────────────────────────────────────
class _TodayCard extends StatelessWidget {
  final String quote;
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onShare;

  const _TodayCard({
    required this.quote,
    required this.saved,
    required this.onSave,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF3730A3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4338CA), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          const Text(
            'TODAY\'S AFFIRMATION',
            style: TextStyle(
              color: Color(0xFFA5B4FC),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          // Quote – always white on the deep-indigo gradient card
          Text(
            '"$quote"',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),

          // Save / Share buttons
          Row(
            children: [
              Expanded(
                child: _CardButton(
                  label: saved ? 'Saved ✓' : 'Save',
                  onTap: onSave,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CardButton(label: 'Share', onTap: onShare),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Pill button inside today's card ──────────────────────────────────────────
class _CardButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _CardButton({required this.label, required this.onTap});

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
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Past-day quote card ───────────────────────────────────────────────────────
class _PastDayCard extends StatelessWidget {
  final DateTime date;
  final String quote;
  final List<Color> gradientColors;

  const _PastDayCard({
    required this.date,
    required this.quote,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _shortDate(date),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '"$quote"',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
