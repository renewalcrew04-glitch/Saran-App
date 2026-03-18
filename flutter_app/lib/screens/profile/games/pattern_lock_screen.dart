import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// ── Brand tokens ────────────────────────────────────────────────────────────────
const _kBg      = Color(0xFF060B14);
const _kCard    = Color(0xFF111827);
const _kBorder  = Color(0xFF1E2535);
const _kText    = Color(0xFFF1F5F9);
const _kMuted   = Color(0xFF64748B);
const _kSubtext = Color(0xFF94A3B8);
const _kOrange  = Color(0xFFEA580C);
const _kOrangeLt = Color(0xFFFB923C);

// ── Color palette for pattern ───────────────────────────────────────────────────
const _colors = [
  Color(0xFFEF4444), // red
  Color(0xFF3B82F6), // blue
  Color(0xFF10B981), // green
  Color(0xFFF59E0B), // amber
];

class PatternLockScreen extends StatefulWidget {
  const PatternLockScreen({super.key});

  @override
  State<PatternLockScreen> createState() => _PatternLockScreenState();
}

class _PatternLockScreenState extends State<PatternLockScreen> {
  static const _startLength = 3;
  static const _maxLength = 8;

  List<int> _sequence = [];
  List<int> _userInput = [];
  int _showing = -1; // index being shown
  bool _started = false;
  bool _showingSequence = false;
  bool _inputPhase = false;
  bool _won = false;
  bool _failed = false;
  int _round = 0;
  int _score = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _sequence = [];
      _userInput = [];
      _showing = -1;
      _started = true;
      _won = false;
      _failed = false;
      _round = 1;
      _score = 0;
    });
    _generateAndShow();
  }

  void _generateAndShow() {
    final r = Random();
    final length = min(_startLength + _round - 1, _maxLength);
    _sequence = List.generate(length, (_) => r.nextInt(_colors.length));
    _userInput = [];
    setState(() {
      _inputPhase = false;
      _showingSequence = true;
    });
    _playSequence();
  }

  void _playSequence() async {
    await Future.delayed(const Duration(milliseconds: 500));
    for (int i = 0; i < _sequence.length; i++) {
      if (!mounted) return;
      setState(() => _showing = i);
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() => _showing = -1);
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (!mounted) return;
    setState(() {
      _showingSequence = false;
      _inputPhase = true;
    });
  }

  void _onTap(int colorIndex) {
    if (!_inputPhase || _failed || _won) return;

    final pos = _userInput.length;
    if (colorIndex == _sequence[pos]) {
      setState(() {
        _userInput.add(colorIndex);
        _showing = pos;
      });
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() => _showing = -1);
      });

      if (_userInput.length == _sequence.length) {
        // Round complete
        setState(() => _score++);
        if (_round >= 5) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) setState(() => _won = true);
          });
        } else {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              setState(() => _round++);
              _generateAndShow();
            }
          });
        }
      }
    } else {
      setState(() {
        _failed = true;
        _inputPhase = false;
      });
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
                      Text('Pattern Lock',
                          style: TextStyle(
                              color: _kText,
                              fontSize: 20,
                              fontWeight: FontWeight.w900)),
                      Text('Follow the color sequence',
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
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: !_started
                      ? _buildStart()
                      : _won
                          ? _buildResult(true)
                          : _failed
                              ? _buildResult(false)
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
              _kOrange.withOpacity(0.3),
              _kOrange.withOpacity(0.05),
            ]),
            border: Border.all(color: _kOrange, width: 2),
          ),
          alignment: Alignment.center,
          child: const Text('👾', style: TextStyle(fontSize: 52)),
        ),
        const SizedBox(height: 28),
        const Text('Pattern Lock',
            style: TextStyle(
                color: _kText,
                fontSize: 24,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        const Text(
          'Watch the color sequence and repeat it.\n5 rounds — each one longer!',
          textAlign: TextAlign.center,
          style:
              TextStyle(color: _kSubtext, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 36),
        GestureDetector(
          onTap: _startGame,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            decoration: BoxDecoration(
              gradient:
                  const LinearGradient(colors: [_kOrangeLt, _kOrange]),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: _kOrange.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Text('Start Game',
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
    final sequenceLength = _sequence.length;
    final progress = _userInput.length / max(sequenceLength, 1);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Round + score row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBorder),
              ),
              child: Text('Round $_round / 5',
                  style: const TextStyle(
                      color: _kText,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _kOrange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: _kOrange.withOpacity(0.3)),
              ),
              child: Text('$_score pts',
                  style: const TextStyle(
                      color: _kOrangeLt,
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Status text
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _showingSequence
                ? 'Watch carefully…'
                : _inputPhase
                    ? 'Your turn! (${_userInput.length}/$sequenceLength)'
                    : '',
            key: ValueKey(_showingSequence),
            style: TextStyle(
              color: _showingSequence ? _kOrangeLt : _kSubtext,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _inputPhase ? progress : 0,
            minHeight: 4,
            backgroundColor: _kBorder,
            valueColor:
                const AlwaysStoppedAnimation<Color>(_kOrange),
          ),
        ),
        const SizedBox(height: 36),

        // Sequence display (dots)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: List.generate(_sequence.length, (i) {
            final active = _showing == i;
            final done = i < _userInput.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: active ? 20 : 14,
              height: active ? 20 : 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done || active
                    ? _colors[_sequence[i]]
                    : _kBorder,
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: _colors[_sequence[i]].withOpacity(0.6),
                          blurRadius: 12,
                        )
                      ]
                    : null,
              ),
            );
          }),
        ),
        const SizedBox(height: 48),

        // Color buttons (2x2 grid)
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.6,
          children: List.generate(_colors.length, (i) {
            final isActive = _showing != -1 &&
                _showingSequence &&
                _sequence[_showing] == i;
            return GestureDetector(
              onTap: () => _onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: _colors[i].withOpacity(isActive ? 0.85 : 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _colors[i].withOpacity(isActive ? 1 : 0.4),
                    width: isActive ? 2.5 : 1.5,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: _colors[i].withOpacity(0.5),
                            blurRadius: 16,
                          )
                        ]
                      : null,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildResult(bool won) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: won
                  ? [_kOrangeLt, _kOrange]
                  : [const Color(0xFF374151), const Color(0xFF1F2937)],
            ),
            boxShadow: [
              BoxShadow(
                color: (won ? _kOrange : _kMuted).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(won ? '🎯' : '❌',
              style: const TextStyle(fontSize: 42)),
        ),
        const SizedBox(height: 24),
        Text(
          won ? 'Pattern Master! 🎉' : 'Wrong pattern!',
          style: const TextStyle(
              color: _kText,
              fontSize: 24,
              fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          won
              ? 'You completed all 5 rounds!'
              : 'You reached round $_round with $_score correct.',
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: _kSubtext, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 36),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _startGame,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_kOrangeLt, _kOrange]),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text('Try Again',
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
