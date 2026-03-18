import 'package:flutter/material.dart';

// ── Brand tokens ────────────────────────────────────────────────────────────────
const _kBg      = Color(0xFF060B14);
const _kCard    = Color(0xFF111827);
const _kBorder  = Color(0xFF1E2535);
const _kText    = Color(0xFFF1F5F9);
const _kMuted   = Color(0xFF64748B);
const _kSubtext = Color(0xFF94A3B8);
const _kBlue    = Color(0xFF1E40AF);
const _kBlueLt  = Color(0xFF60A5FA);

// ── Palette ─────────────────────────────────────────────────────────────────────
const _palette = [
  Color(0xFFEF4444), // red
  Color(0xFFF97316), // orange
  Color(0xFFF59E0B), // amber
  Color(0xFF10B981), // green
  Color(0xFF06B6D4), // cyan
  Color(0xFF3B82F6), // blue
  Color(0xFF8B5CF6), // violet
  Color(0xFFEC4899), // pink
  Color(0xFFF1F5F9), // white
  Color(0xFF374151), // dark
];

// ── Canvas grid (8x10, numbers 1-4 for colors) ────────────────────────────────
// 0 = no target color, filled with user color. 1-4 = hint colors
const _gridW = 8;
const _gridH = 10;

// Simple flower pattern hints (using indices into palette: 0-9)
final _hints = List.generate(_gridH, (row) =>
    List.generate(_gridW, (col) {
      // Simple sun/flower pattern
      final cx = _gridW ~/ 2;
      final cy = _gridH ~/ 3;
      final dx = col - cx;
      final dy = row - cy;
      final dist = dx * dx + dy * dy;

      if (dist == 0) return 1; // center: orange
      if (dist <= 2) return 2; // inner: yellow
      if (dist <= 5) return 3; // petal: red
      if (row > _gridH * 0.6 && (col == cx - 1 || col == cx || col == cx + 1)) return 4; // stem: green
      return 0; // background
    }),
);

const _hintColors = [
  Colors.transparent, // 0 - no hint
  Color(0xFFF97316),  // 1 - orange (center)
  Color(0xFFF59E0B),  // 2 - yellow
  Color(0xFFEF4444),  // 3 - red petal
  Color(0xFF10B981),  // 4 - green stem
];

class CreativeColorScreen extends StatefulWidget {
  const CreativeColorScreen({super.key});

  @override
  State<CreativeColorScreen> createState() => _CreativeColorScreenState();
}

class _CreativeColorScreenState extends State<CreativeColorScreen> {
  late List<List<Color?>> _canvas;
  int _selectedColor = 0;
  bool _started = false;

  void _initCanvas() {
    _canvas = List.generate(
        _gridH, (_) => List.generate(_gridW, (_) => null));
  }

  void _paint(int row, int col) {
    setState(() {
      _canvas[row][col] = _palette[_selectedColor];
    });
  }

  void _erase(int row, int col) {
    setState(() {
      _canvas[row][col] = null;
    });
  }

  int get _filledCount {
    int count = 0;
    for (final row in _canvas) {
      for (final cell in row) {
        if (cell != null) count++;
      }
    }
    return count;
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Creative Color',
                            style: TextStyle(
                                color: _kText,
                                fontSize: 20,
                                fontWeight: FontWeight.w900)),
                        Text('Tap to paint your canvas',
                            style:
                                TextStyle(color: _kSubtext, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (_started)
                    GestureDetector(
                      onTap: () {
                        _initCanvas();
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _kCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _kBorder),
                        ),
                        child: const Text('Clear',
                            style: TextStyle(
                                color: _kSubtext,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: !_started
                  ? _buildStart()
                  : _buildCanvas(),
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
                  _kBlue.withOpacity(0.4),
                  _kBlue.withOpacity(0.05),
                ]),
                border: Border.all(color: _kBlueLt, width: 2),
              ),
              alignment: Alignment.center,
              child: const Text('🎨', style: TextStyle(fontSize: 52)),
            ),
            const SizedBox(height: 28),
            const Text('Creative Color',
                style: TextStyle(
                    color: _kText,
                    fontSize: 24,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            const Text(
              'Tap each cell to paint it with your\nchosen color. Follow the hints to\ncreate a beautiful picture!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _kSubtext, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 36),
            GestureDetector(
              onTap: () {
                _initCanvas();
                setState(() {
                  _started = true;
                  _selectedColor = 0;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 48, vertical: 16),
                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(colors: [_kBlueLt, _kBlue]),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: _kBlue.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Text('Start Coloring',
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

  Widget _buildCanvas() {
    final total = _gridW * _gridH;
    final fillPct = (_filledCount / total * 100).round();

    return Column(
      children: [
        // Progress
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _filledCount / total,
                    minHeight: 4,
                    backgroundColor: _kBorder,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(_kBlueLt),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('$fillPct%',
                  style: const TextStyle(
                      color: _kBlueLt,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ],
          ),
        ),

        // Grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cellSize = constraints.maxWidth / _gridW;
                return GestureDetector(
                  onPanUpdate: (details) {
                    final box =
                        context.findRenderObject() as RenderBox?;
                    if (box == null) return;
                    final local = box.globalToLocal(
                        details.globalPosition);
                    final col =
                        (local.dx / cellSize).floor().clamp(0, _gridW - 1);
                    final row =
                        (local.dy / cellSize).floor().clamp(0, _gridH - 1);
                    _paint(row, col);
                  },
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _gridW,
                      childAspectRatio: 1,
                    ),
                    itemCount: _gridW * _gridH,
                    itemBuilder: (context, idx) {
                      final row = idx ~/ _gridW;
                      final col = idx % _gridW;
                      final painted = _canvas[row][col];
                      final hint = _hints[row][col];
                      final hintColor =
                          hint > 0 ? _hintColors[hint] : null;

                      return GestureDetector(
                        onTap: () => _paint(row, col),
                        onLongPress: () => _erase(row, col),
                        child: Container(
                          decoration: BoxDecoration(
                            color: painted ??
                                (hintColor != null
                                    ? hintColor.withOpacity(0.12)
                                    : const Color(0xFF0D1627)),
                            border: Border.all(
                              color: _kBorder.withOpacity(0.4),
                              width: 0.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: painted == null && hint > 0
                              ? Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        hintColor!.withOpacity(0.5),
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),

        // Color palette
        Container(
          height: 88,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: _kCard,
            border: Border(top: BorderSide(color: _kBorder)),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _palette.length,
            itemBuilder: (context, i) {
              final selected = i == _selectedColor;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 10),
                  width: selected ? 52 : 44,
                  height: selected ? 52 : 44,
                  decoration: BoxDecoration(
                    color: _palette[i],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? Colors.white
                          : Colors.white.withOpacity(0.1),
                      width: selected ? 2.5 : 1,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: _palette[i].withOpacity(0.5),
                              blurRadius: 12,
                            )
                          ]
                        : null,
                  ),
                  child: selected
                      ? const Icon(Icons.check,
                          color: Colors.white, size: 20)
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
