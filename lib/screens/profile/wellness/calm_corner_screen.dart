import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CalmCornerScreen extends StatelessWidget {
  const CalmCornerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Calm Corner"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _Card(
              title: "1-Minute Breathing",
              desc: "Calm your mind",
              onTap: () => context.push('/wellness/breathing'),
            ),
            _Card(
              title: "5-4-3-2-1 Grounding",
              desc: "Return to the present",
              onTap: () => context.push('/wellness/grounding'),
            ),
            _Card(
              title: "Eye Relaxation",
              desc: "Rest your eyes",
              onTap: () => context.push('/wellness/eye-relax'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String desc;
  final VoidCallback onTap;

  const _Card({
    required this.title,
    required this.desc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(desc,
                style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
          ],
        ),
      ),
    );
  }
}
