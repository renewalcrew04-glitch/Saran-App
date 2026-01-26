import 'dart:async';
import 'package:flutter/material.dart';
import 'package:saran_app/services/wellness_streak_service.dart';

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with SingleTickerProviderStateMixin {
  static const int totalSeconds = 60;
  static const Duration cycleDuration = Duration(milliseconds: 4000);

  bool started = false;
  bool done = false;

  int secondsLeft = totalSeconds;
  String phase = "inhale";

  Timer? _timer;
  Timer? _phaseTimer;

  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: cycleDuration,
    );

    _scaleAnim = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phaseTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      started = true;
      done = false;
      secondsLeft = totalSeconds;
      phase = "inhale";
    });

    _controller.repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      setState(() {
        secondsLeft -= 1;
      });

      if (secondsLeft <= 0) {
        t.cancel();
        _phaseTimer?.cancel();
        _controller.stop();

        setState(() {
          done = true;
          started = false;
          secondsLeft = 0;
        });

        await WellnessStreakService.markCompleted(
          activityId: "breathing",
          activityTitle: "1-Minute Breathing",
        );
      }
    });

    _phaseTimer = Timer.periodic(cycleDuration, (_) {
      setState(() {
        phase = (phase == "inhale") ? "exhale" : "inhale";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("1-Minute Breathing"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: !started && !done
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Find a comfortable position and relax",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF666666)),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _start,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 36,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text("Begin"),
                    ),
                  ],
                )
              : (!done)
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ScaleTransition(
                          scale: _scaleAnim,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 4),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "$secondsLeft",
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          phase == "inhale" ? "Inhale…" : "Exhale…",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            "✓",
                            style: TextStyle(color: Colors.white, fontSize: 36),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Well done",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "You took a moment for yourself",
                          style: TextStyle(color: Color(0xFF666666)),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
