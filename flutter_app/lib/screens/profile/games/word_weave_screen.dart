import 'dart:math';
import 'package:flutter/material.dart';

// ── Brand tokens ────────────────────────────────────────────────────────────────
const _kBg      = Color(0xFF060B14);
const _kCard    = Color(0xFF111827);
const _kBorder  = Color(0xFF1E2535);
const _kText    = Color(0xFFF1F5F9);
const _kMuted   = Color(0xFF64748B);
const _kSubtext = Color(0xFF94A3B8);
const _kTeal    = Color(0xFF0891B2);
const _kTealLt  = Color(0xFF22D3EE);

// ── Word data ───────────────────────────────────────────────────────────────────
// Each entry: (letters, words you can make)
const _puzzles = [
  (letters: 'TACEWR', words: ['WATER', 'TRACE', 'CRATE', 'CARE', 'RACE', 'WEAR', 'RATE']),
  (letters: 'SNIGLE', words: ['LINES', 'SINGL', 'GLINE', 'SLIDE', 'LENIS', 'LENS', 'SINE']),
  (letters: 'FROEST', words: ['FOREST', 'FORTE', 'STORE', 'FORTS', 'ROTES', 'TORE', 'ROTE']),
  (letters: 'PLANST', words: ['PLANTS', 'SLANT', 'PLANT', 'PANTS', 'ANTS', 'PLAN', 'PANT']),
  (letters: 'DREAMY', words: ['DREAM', 'RAYED', 'DRAY', 'DARE', 'MARE', 'ARMY', 'DEAR']),
];

class WordWeaveScreen extends StatefulWidget {
  const WordWeaveScreen({super.key});

  @override
  State<WordWeaveScreen> createState() => _WordWeaveScreenState();
}

class _WordWeaveScreenState extends State<WordWeaveScreen> {
  int _puzzleIndex = 0;
  String _input = '';
  Set<String> _found = {};
  bool _started = false;
  bool _done = false;

  List<String> get _availableLetters =>
      _puzzles[_puzzleIndex].letters.split('');
  List<String> get _targetWords =>
      List<String>.from(_puzzles[_puzzleIndex].words);
  String get _letters => _puzzles[_puzzleIndex].letters;

  void _startGame([int? idx]) {
    final index =
        idx ?? Random().nextInt(_puzzles.length);
    setState(() {
      _puzzleIndex = index;
      _input = '';
      _found = {};
      _started = true;
      _done = false;
    });
  }

  void _tapLetter(String l) {
    if (_input.length >= _letters.length) return;
    // Only allow letters that exist in remaining pool
    final remaining = _letters.split('');
    for (final used in _input.split('')) {
      remaining.remove(used);
    }
    if (!remaining.contains(l)) return;
    setState(() => _input += l);
  }

  void _deleteLast() {
    if (_input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  void _submit() {
    if (_input.length < 3) return;
    final word = _input.toUpperCase();
    if (_targetWords.contains(word) && !_found.contains(word)) {
      setState(() {
        _found.add(word);
        _input = '';
        if (_found.length >= 3) _done = true;
      });
    } else {
      // Invalid or duplicate – shake and clear
      setState(() => _input = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
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
                      Text('Word Weave',
                          style: TextStyle(
                              color: _kText,
                              fontSize: 20,
                              fontWeight: FontWeight.w900)),
                      Text('Build words from the letters',
                          style:
                              TextStyle(color: _kSubtext, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: !_started
                      ? _buildStart()
                      : _done
                          ? _buildDone()
                          : _buildGame(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStart() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              _kTeal.withOpacity(0.3),
              _kTeal.withOpacity(0.05),
            ]),
            border: Border.all(color: _kTeal, width: 2),
          ),
          alignment: Alignment.center,
          child: const Text('✏️', style: TextStyle(fontSize: 52)),
        ),
        const SizedBox(height: 28),
        const Text('Word Weave',
            style: TextStyle(
                color: _kText,
                fontSize: 24,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        const Text(
          'Use the given letters to build as many\nwords as you can. Find at least 3!',
          textAlign: TextAlign.center,
          style:
              TextStyle(color: _kSubtext, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 36),
        GestureDetector(
          onTap: () => _startGame(),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            decoration: BoxDecoration(
              gradient:
                  const LinearGradient(colors: [_kTealLt, _kTeal]),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: _kTeal.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Text('Play Now',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildGame() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Found: ${_found.length}',
                  style: const TextStyle(
                      color: _kTealLt,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kBorder),
                ),
                child: const Text('Find 3 to win',
                    style: TextStyle(
                        color: _kSubtext, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Input display
          Container(
            width: double.infinity,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _input.isNotEmpty ? _kTeal : _kBorder,
              ),
            ),
            child: Text(
              _input.isEmpty ? 'Tap letters below' : _input,
              style: TextStyle(
                color: _input.isEmpty ? _kMuted : _kText,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Letter tiles
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: _availableLetters.map((l) {
              final remaining = _letters.split('');
              for (final used in _input.split('')) {
                remaining.remove(used);
              }
              final available = remaining.contains(l);
              return GestureDetector(
                onTap: () => _tapLetter(l),
                child: Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: available
                        ? _kTeal.withOpacity(0.15)
                        : const Color(0xFF0A111E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: available
                          ? _kTeal.withOpacity(0.5)
                          : _kBorder.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    l,
                    style: TextStyle(
                      color: available ? _kText : _kMuted,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _deleteLast,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kBorder),
                  ),
                  child: const Icon(Icons.backspace_outlined,
                      color: _kSubtext, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _submit,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 36, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_kTealLt, _kTeal]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _kTeal.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text('Submit',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => setState(() => _input = ''),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kBorder),
                  ),
                  child: const Icon(Icons.refresh,
                      color: _kSubtext, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Found words
          if (_found.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Found words:',
                  style:
                      TextStyle(color: _kSubtext, fontSize: 12)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _found.map((w) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _kTeal.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _kTeal.withOpacity(0.4)),
                    ),
                    child: Text(w,
                        style: const TextStyle(
                            color: _kTealLt,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDone() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient:
                const LinearGradient(colors: [_kTealLt, _kTeal]),
            boxShadow: [
              BoxShadow(
                color: _kTeal.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text('✏️',
              style: TextStyle(fontSize: 42)),
        ),
        const SizedBox(height: 24),
        const Text('Word Master! 📚',
            style: TextStyle(
                color: _kText,
                fontSize: 24,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(
          'You found ${_found.length} words from "${_puzzles[_puzzleIndex].letters}"',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _kSubtext, fontSize: 14),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: _found.map((w) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _kTeal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _kTeal.withOpacity(0.4)),
                ),
                child: Text(w,
                    style: const TextStyle(
                        color: _kTealLt,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              )).toList(),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _startGame(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_kTealLt, _kTeal]),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text('Next Puzzle',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: _kBorder, width: 1.5),
                ),
                child: const Text('Back',
                    style: TextStyle(
                        color: _kSubtext,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
