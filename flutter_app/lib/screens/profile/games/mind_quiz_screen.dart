import 'dart:async';
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

// ── Quiz Data ───────────────────────────────────────────────────────────────────
class _Q {
  final String q;
  final List<String> opts;
  final int correct;
  const _Q(this.q, this.opts, this.correct);
}

const _questions = [
  _Q('Which planet is known as the Red Planet?',
      ['Mars', 'Venus', 'Jupiter', 'Saturn'], 0),
  _Q('How many sides does a hexagon have?',
      ['5', '6', '7', '8'], 1),
  _Q('What is the largest ocean on Earth?',
      ['Atlantic', 'Indian', 'Arctic', 'Pacific'], 3),
  _Q('Who painted the Mona Lisa?',
      ['Van Gogh', 'Picasso', 'Da Vinci', 'Monet'], 2),
  _Q('What gas do plants absorb from the air?',
      ['Oxygen', 'Nitrogen', 'Carbon Dioxide', 'Hydrogen'], 2),
  _Q('How many bones are in the adult human body?',
      ['196', '206', '216', '226'], 1),
  _Q('What is the chemical symbol for gold?',
      ['Ag', 'Ge', 'Go', 'Au'], 3),
  _Q('Which country invented pizza?',
      ['France', 'Italy', 'Greece', 'Spain'], 1),
  _Q('What is the tallest mountain in the world?',
      ['K2', 'Kangchenjunga', 'Mount Everest', 'Lhotse'], 2),
  _Q('How many strings does a standard guitar have?',
      ['4', '5', '6', '7'], 2),
];

class MindQuizScreen extends StatefulWidget {
  const MindQuizScreen({super.key});

  @override
  State<MindQuizScreen> createState() => _MindQuizScreenState();
}

class _MindQuizScreenState extends State<MindQuizScreen> {
  static const _timePerQ = 15;

  int _qIndex = 0;
  int _score = 0;
  int _selected = -1;
  bool _answered = false;
  bool _started = false;
  bool _done = false;
  int _secondsLeft = _timePerQ;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _qIndex = 0;
      _score = 0;
      _selected = -1;
      _answered = false;
      _started = true;
      _done = false;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _timePerQ);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _secondsLeft -= 1);
      if (_secondsLeft <= 0) {
        t.cancel();
        _onAnswer(-1); // time up = wrong
      }
    });
  }

  void _onAnswer(int idx) {
    if (_answered) return;
    _timer?.cancel();

    final correct = _questions[_qIndex].correct;
    setState(() {
      _selected = idx;
      _answered = true;
      if (idx == correct) _score++;
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_qIndex == _questions.length - 1) {
        setState(() => _done = true);
      } else {
        setState(() {
          _qIndex++;
          _selected = -1;
          _answered = false;
        });
        _startTimer();
      }
    });
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
                      Text('Mind Quiz',
                          style: TextStyle(
                              color: _kText,
                              fontSize: 20,
                              fontWeight: FontWeight.w900)),
                      Text('Test your knowledge',
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
                          : _buildQuestion(),
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
              _kPurple.withOpacity(0.3),
              _kPurple.withOpacity(0.05),
            ]),
            border: Border.all(color: _kPurple, width: 2),
          ),
          alignment: Alignment.center,
          child: const Text('🧠', style: TextStyle(fontSize: 52)),
        ),
        const SizedBox(height: 28),
        const Text('Mind Quiz',
            style: TextStyle(
                color: _kText, fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        const Text(
          '10 questions · 15 seconds each\nTest your brain with fun trivia!',
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
                  const LinearGradient(colors: [_kPurpleLt, _kPurple]),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: _kPurple.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Text('Start Quiz',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestion() {
    final q = _questions[_qIndex];
    final progress = _secondsLeft / _timePerQ;
    final timeColor = _secondsLeft > 8
        ? _kPurpleLt
        : _secondsLeft > 4
            ? const Color(0xFFFBBF24)
            : const Color(0xFFEF4444);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Progress dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_questions.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _qIndex ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i < _qIndex
                    ? _kPurple
                    : i == _qIndex
                        ? _kPurpleLt
                        : _kBorder,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),

        // Timer + score row
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: _kBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(timeColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text('$_secondsLeft s',
                style: TextStyle(
                    color: timeColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
            const SizedBox(width: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _kPurple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: _kPurple.withOpacity(0.3)),
              ),
              child: Text('$_score pts',
                  style: const TextStyle(
                      color: _kPurpleLt,
                      fontWeight: FontWeight.w800,
                      fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Question card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            children: [
              Text(
                'Q ${_qIndex + 1}/${_questions.length}',
                style: const TextStyle(
                    color: _kMuted, fontSize: 12),
              ),
              const SizedBox(height: 10),
              Text(
                q.q,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: _kText,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Options
        ...List.generate(q.opts.length, (i) {
          Color bg = const Color(0xFF1A2235);
          Color border = _kBorder;
          Color textColor = _kText;

          if (_answered) {
            if (i == q.correct) {
              bg = const Color(0xFF059669).withOpacity(0.2);
              border = const Color(0xFF059669);
              textColor = const Color(0xFF34D399);
            } else if (i == _selected && i != q.correct) {
              bg = const Color(0xFFEF4444).withOpacity(0.15);
              border = const Color(0xFFEF4444);
              textColor = const Color(0xFFF87171);
            }
          }

          return GestureDetector(
            onTap: _answered ? null : () => _onAnswer(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: border.withOpacity(0.2),
                      border: Border.all(color: border.withOpacity(0.5)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      String.fromCharCode(65 + i),
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(q.opts[i],
                        style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDone() {
    final pct = (_score / _questions.length * 100).round();
    final msg = pct >= 80
        ? 'Brilliant! 🌟'
        : pct >= 50
            ? 'Well done! 💪'
            : 'Keep practicing! 🧠';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient:
                const LinearGradient(colors: [_kPurpleLt, _kPurple]),
            boxShadow: [
              BoxShadow(
                color: _kPurple.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
              )
            ],
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$_score',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1),
              ),
              const Text('pts',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(msg,
            style: const TextStyle(
                color: _kText,
                fontSize: 24,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(
          'You scored $_score out of ${_questions.length}  ($pct%)',
          style:
              const TextStyle(color: _kSubtext, fontSize: 14),
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
                      colors: [_kPurpleLt, _kPurple]),
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
