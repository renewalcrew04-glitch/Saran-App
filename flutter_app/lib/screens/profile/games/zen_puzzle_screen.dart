import 'dart:math';
import 'package:flutter/material.dart';

// ── Brand tokens ────────────────────────────────────────────────────────────────
const _kBg      = Color(0xFF060B14);
const _kCard    = Color(0xFF111827);
const _kBorder  = Color(0xFF1E2535);
const _kText    = Color(0xFFF1F5F9);
const _kMuted   = Color(0xFF64748B);
const _kSubtext = Color(0xFF94A3B8);
const _kGreen   = Color(0xFF059669);
const _kGreenLt = Color(0xFF34D399);

class ZenPuzzleScreen extends StatefulWidget {
  const ZenPuzzleScreen({super.key});

  @override
  State<ZenPuzzleScreen> createState() => _ZenPuzzleScreenState();
}

class _ZenPuzzleScreenState extends State<ZenPuzzleScreen> {
  static const _size = 3; // 3x3 grid
  static const _total = _size * _size; // 9 tiles, one blank

  List<int> _tiles = [];
  int _moves = 0;
  bool _started = false;
  bool _solved = false;

  // Goal state: [1,2,3,4,5,6,7,8,0] where 0 is blank
  static List<int> get _goal =>
      List.generate(_total, (i) => (i + 1) % _total);

  void _newGame() {
    List<int> tiles;
    do {
      tiles = List.generate(_total, (i) => (i + 1) % _total);
      // Fisher-Yates shuffle
      final r = Random();
      for (var i = tiles.length - 1; i > 0; i--) {
        final j = r.nextInt(i + 1);
        final tmp = tiles[i];
        tiles[i] = tiles[j];
        tiles[j] = tmp;
      }
    } while (!_isSolvable(tiles) || _isSolved(tiles));

    setState(() {
      _tiles = tiles;
      _moves = 0;
      _started = true;
      _solved = false;
    });
  }

  bool _isSolvable(List<int> t) {
    int inv = 0;
    final flat = t.where((x) => x != 0).toList();
    for (int i = 0; i < flat.length; i++) {
      for (int j = i + 1; j < flat.length; j++) {
        if (flat[i] > flat[j]) inv++;
      }
    }
    // For 3x3, solvable if inversions count is even
    return inv % 2 == 0;
  }

  bool _isSolved(List<int> t) {
    for (int i = 0; i < _total; i++) {
      if (t[i] != _goal[i]) return false;
    }
    return true;
  }

  void _tap(int index) {
    if (_solved) return;
    final blankIndex = _tiles.indexOf(0);
    final row = index ~/ _size;
    final col = index % _size;
    final bRow = blankIndex ~/ _size;
    final bCol = blankIndex % _size;

    // Only allow adjacent (up/down/left/right) moves
    final dr = (row - bRow).abs();
    final dc = (col - bCol).abs();
    if ((dr == 1 && dc == 0) || (dr == 0 && dc == 1)) {
      setState(() {
        _tiles[blankIndex] = _tiles[index];
        _tiles[index] = 0;
        _moves++;
        if (_isSolved(_tiles)) _solved = true;
      });
    }
  }

  // Pastel color per tile number
  Color _tileColor(int n) {
    const colors = [
      Color(0xFF0E7490), // 1
      Color(0xFF065F46), // 2
      Color(0xFF1E3A8A), // 3
      Color(0xFF4C1D95), // 4
      Color(0xFF7C2D12), // 5
      Color(0xFF064E3B), // 6
      Color(0xFF1E40AF), // 7
      Color(0xFF4A044E), // 8
    ];
    if (n == 0) return Colors.transparent;
    return colors[(n - 1) % colors.length];
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
                      Text('Zen Puzzle',
                          style: TextStyle(
                              color: _kText,
                              fontSize: 20,
                              fontWeight: FontWeight.w900)),
                      Text('Slide tiles into order',
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
                      : _solved
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
              _kGreen.withOpacity(0.3),
              _kGreen.withOpacity(0.05),
            ]),
            border: Border.all(color: _kGreen, width: 2),
          ),
          alignment: Alignment.center,
          child: const Text('🧩', style: TextStyle(fontSize: 52)),
        ),
        const SizedBox(height: 28),
        const Text('Zen Puzzle',
            style: TextStyle(
                color: _kText,
                fontSize: 24,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        const Text(
          'Slide the tiles to arrange numbers 1-8.\nFind your calm in the puzzle.',
          textAlign: TextAlign.center,
          style:
              TextStyle(color: _kSubtext, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 36),
        GestureDetector(
          onTap: _newGame,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            decoration: BoxDecoration(
              gradient:
                  const LinearGradient(colors: [_kGreenLt, _kGreen]),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: _kGreen.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Text('Start Puzzle',
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Moves counter
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.swap_horiz, color: _kGreenLt, size: 18),
              const SizedBox(width: 8),
              Text(
                '$_moves moves',
                style: const TextStyle(
                    color: _kText,
                    fontWeight: FontWeight.w700,
                    fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Puzzle grid
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kBorder),
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _size,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemCount: _total,
              itemBuilder: (context, i) {
                final n = _tiles[i];
                final isBlank = n == 0;
                return GestureDetector(
                  onTap: () => _tap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    decoration: BoxDecoration(
                      color: isBlank
                          ? Colors.transparent
                          : _tileColor(n),
                      borderRadius: BorderRadius.circular(12),
                      border: isBlank
                          ? Border.all(
                              color: _kBorder.withOpacity(0.3),
                              style: BorderStyle.solid)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: isBlank
                        ? null
                        : Text(
                            '$n',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),

        GestureDetector(
          onTap: _newGame,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _kBorder, width: 1.5),
            ),
            child: const Text('Shuffle',
                style: TextStyle(
                    color: _kSubtext, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
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
                const LinearGradient(colors: [_kGreenLt, _kGreen]),
            boxShadow: [
              BoxShadow(
                color: _kGreen.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text('✓',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 24),
        const Text('Puzzle Solved! 🧘',
            style: TextStyle(
                color: _kText,
                fontSize: 24,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(
          'Completed in $_moves moves',
          style: const TextStyle(color: _kSubtext, fontSize: 14),
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
                      colors: [_kGreenLt, _kGreen]),
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
    );
  }
}
