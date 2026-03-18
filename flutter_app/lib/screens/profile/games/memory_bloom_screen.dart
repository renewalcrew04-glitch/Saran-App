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
const _kPurple  = Color(0xFF7C3AED);
const _kPurpleLt = Color(0xFFA78BFA);

// ── Game Data ───────────────────────────────────────────────────────────────────
const _flowers = ['🌸', '🌺', '🌻', '🌹', '🌷', '🪷', '💐', '🌼'];

class MemoryBloomScreen extends StatefulWidget {
  const MemoryBloomScreen({super.key});

  @override
  State<MemoryBloomScreen> createState() => _MemoryBloomScreenState();
}

class _MemoryBloomScreenState extends State<MemoryBloomScreen> {
  static const _totalPairs = 8;
  static const _totalTime = 60;

  List<String> _cards = [];
  List<bool> _flipped = [];
  List<bool> _matched = [];

  int _firstIndex = -1;
  int _secondIndex = -1;
  bool _checking = false;
  int _moves = 0;
  int _matchedPairs = 0;
  int _secondsLeft = _totalTime;
  bool _started = false;
  bool _won = false;
  bool _lost = false;

  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _newGame() {
    _timer?.cancel();
    final pairs = List<String>.from(_flowers)..shuffle(Random());
    final deck = [...pairs, ...pairs]..shuffle(Random());

    setState(() {
      _cards = deck;
      _flipped = List.filled(_totalPairs * 2, false);
      _matched = List.filled(_totalPairs * 2, false);
      _firstIndex = -1;
      _secondIndex = -1;
      _checking = false;
      _moves = 0;
      _matchedPairs = 0;
      _secondsLeft = _totalTime;
      _started = true;
      _won = false;
      _lost = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _secondsLeft -= 1);
      if (_secondsLeft <= 0) {
        t.cancel();
        setState(() => _lost = true);
      }
    });
  }

  void _onTap(int index) {
    if (_checking) return;
    if (_matched[index]) return;
    if (_flipped[index]) return;

    setState(() => _flipped[index] = true);

    if (_firstIndex == -1) {
      _firstIndex = index;
    } else {
      _secondIndex = index;
      _checking = true;
      _moves++;

      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        if (_cards[_firstIndex] == _cards[_secondIndex]) {
          setState(() {
            _matched[_firstIndex] = true;
            _matched[_secondIndex] = true;
            _matchedPairs++;
          });
          if (_matchedPairs == _totalPairs) {
            _timer?.cancel();
            setState(() => _won = true);
          }
        } else {
          setState(() {
            _flipped[_firstIndex] = false;
            _flipped[_secondIndex] = false;
          });
        }
        setState(() {
          _firstIndex = -1;
          _secondIndex = -1;
          _checking = false;
        });
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
                      Text('Memory Bloom',
                          style: TextStyle(
                              color: _kText,
                              fontSize: 20,
                              fontWeight: FontWeight.w900)),
                      Text('Match all flower pairs',
                          style:
                              TextStyle(color: _kSubtext, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: !_started
                  ? _buildStart()
                  : _won
                      ? _buildResult(true)
                      : _lost
                          ? _buildResult(false)
                          : _buildGame(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _kPurple.withOpacity(0.3),
                  _kPurple.withOpacity(0.05),
                ]),
                border: Border.all(color: _kPurple, width: 2),
              ),
              alignment: Alignment.center,
              child: const Text('🌸', style: TextStyle(fontSize: 52)),
            ),
            const SizedBox(height: 28),
            const Text('Memory Bloom',
                style: TextStyle(
                    color: _kText,
                    fontSize: 24,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            const Text(
              'Flip the cards and find matching\nflower pairs before time runs out!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _kSubtext, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 36),
            GestureDetector(
              onTap: _newGame,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 48, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_kPurpleLt, _kPurple]),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: _kPurple.withOpacity(0.4),
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
        ),
      ),
    );
  }

  Widget _buildGame() {
    final progress = _secondsLeft / _totalTime;
    final timeColor = _secondsLeft > 20
        ? _kPurpleLt
        : _secondsLeft > 10
            ? const Color(0xFFFBBF24)
            : const Color(0xFFEF4444);

    return Column(
      children: [
        // Stats bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              // Timer
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.timer_outlined,
                            color: timeColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '$_secondsLeft s',
                          style: TextStyle(
                            color: timeColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: _kBorder,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(timeColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Pairs
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$_matchedPairs / $_totalPairs',
                    style: const TextStyle(
                      color: _kPurpleLt,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const Text('pairs',
                      style:
                          TextStyle(color: _kMuted, fontSize: 11)),
                ],
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$_moves',
                    style: const TextStyle(
                      color: _kSubtext,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const Text('moves',
                      style:
                          TextStyle(color: _kMuted, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),

        // Card grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: _cards.length,
              itemBuilder: (context, i) => _buildCard(i),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCard(int i) {
    final isFlipped = _flipped[i] || _matched[i];
    final isMatched = _matched[i];

    return GestureDetector(
      onTap: () => _onTap(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isMatched
              ? _kPurple.withOpacity(0.2)
              : isFlipped
                  ? _kCard
                  : const Color(0xFF1A2235),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMatched
                ? _kPurple.withOpacity(0.6)
                : isFlipped
                    ? _kBorder
                    : const Color(0xFF263148),
            width: isMatched ? 1.5 : 1,
          ),
          boxShadow: isMatched
              ? [
                  BoxShadow(
                    color: _kPurple.withOpacity(0.2),
                    blurRadius: 8,
                  )
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: isFlipped
            ? Text(_cards[i],
                style: TextStyle(
                  fontSize: 28,
                  color: isMatched ? Colors.white : null,
                ))
            : const Text('🌿', style: TextStyle(fontSize: 22)),
      ),
    );
  }

  Widget _buildResult(bool won) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: won
                      ? [_kPurpleLt, _kPurple]
                      : [
                          const Color(0xFF374151),
                          const Color(0xFF1F2937)
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (won ? _kPurple : _kMuted).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                won ? '🌸' : '⏰',
                style: const TextStyle(fontSize: 42),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              won ? 'Garden Complete! 🎉' : 'Time\'s Up!',
              style: const TextStyle(
                  color: _kText,
                  fontSize: 24,
                  fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              won
                  ? 'You matched all $_totalPairs pairs in $_moves moves!'
                  : 'You matched $_matchedPairs out of $_totalPairs pairs.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: _kSubtext, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 36),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _newGame,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_kPurpleLt, _kPurple]),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text('Play Again',
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
        ),
      ),
    );
  }
}
