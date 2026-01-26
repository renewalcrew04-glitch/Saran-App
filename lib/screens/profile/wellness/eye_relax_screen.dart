import 'dart:async';
import 'package:flutter/material.dart';
import 'package:saran_app/services/wellness_streak_service.dart';

class EyeRelaxScreen extends StatefulWidget {
  const EyeRelaxScreen({super.key});

  @override
  State<EyeRelaxScreen> createState() => _EyeRelaxScreenState();
}

class _EyeRelaxScreenState extends State<EyeRelaxScreen> {
  final steps = const [
    {"text": "Blink slowly 10 times", "duration": 8},
    {"text": "Look at something far away", "duration": 6},
    {"text": "Now focus on something near", "duration": 6},
    {"text": "Close your eyes and rest", "duration": 6},
  ];

  int stepIndex = 0;
  int seconds = 8;
  bool done = false;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startStep();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startStep() async {
    if (done) return;

    seconds = steps[stepIndex]["duration"] as int;
    setState(() {});

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      setState(() => seconds -= 1);

      if (seconds <= 0) {
        t.cancel();

        if (stepIndex == steps.length - 1) {
          setState(() => done = true);

          await WellnessStreakService.markCompleted(
            activityId: "eye_relax",
            activityTitle: "Eye Relaxation",
          );
        } else {
          setState(() => stepIndex += 1);
          _startStep();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final stepText = steps[stepIndex]["text"] as String;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Eye Relaxation"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: !done
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 4),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "$seconds",
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      stepText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
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
                    const SizedBox(height: 24),
                    const Text(
                      "Eyes refreshed",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Thank you for taking care of your vision",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF666666)),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
