import 'package:flutter/material.dart';
import 'package:saran_app/services/wellness_streak_service.dart';

class GroundingScreen extends StatefulWidget {
  const GroundingScreen({super.key});

  @override
  State<GroundingScreen> createState() => _GroundingScreenState();
}

class _GroundingScreenState extends State<GroundingScreen> {
  final List<Map<String, dynamic>> steps = const [
    {"count": 5, "label": "See", "prompt": "Name 5 things you can see around you"},
    {"count": 4, "label": "Touch", "prompt": "Name 4 things you can touch right now"},
    {"count": 3, "label": "Hear", "prompt": "Name 3 things you can hear"},
    {"count": 2, "label": "Smell", "prompt": "Name 2 things you can smell"},
    {"count": 1, "label": "Taste", "prompt": "Name 1 thing you can taste"},
  ];

  int stepIndex = 0;
  bool completed = false;

  Future<void> _next() async {
    if (stepIndex == steps.length - 1) {
      setState(() => completed = true);

      await WellnessStreakService.markCompleted(
        activityId: "grounding",
        activityTitle: "5-4-3-2-1 Grounding",
      );
    } else {
      setState(() => stepIndex += 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = steps[stepIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("5-4-3-2-1 Grounding"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: !completed
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 4),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "${step["count"]}",
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      step["label"],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      step["prompt"],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF555555),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text("Done"),
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
                      "You are grounded",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "You are here, in this moment",
                      style: TextStyle(color: Color(0xFF666666)),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
