import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WellnessHomeScreen extends StatelessWidget {
  const WellnessHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Wellness"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Text(
              "Your space for balance, growth, and care",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF555555),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "MENTAL WELLBEING",
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF888888),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),

            _WellnessCard(
              icon: Icons.nightlight_outlined,
              title: "S-Mind Journal",
              desc: "Safe space to reflect",
              onTap: () => context.push('/wellness/mind-journal'),
            ),
            _WellnessCard(
              icon: Icons.spa_outlined,
              title: "Calm Corner",
              desc: "Micro-calming exercises",
              onTap: () => context.push('/wellness/calm-corner'),
            ),
            _WellnessCard(
              icon: Icons.favorite_border,
              title: "S-Cycle",
              desc: "Period & wellness tracker",
              highlight: true,
              onTap: () => context.push('/wellness/s-cycle'),
            ),
            _WellnessCard(
              icon: Icons.water_drop_outlined,
              title: "Hydration Tap",
              desc: "Daily water tracker",
              onTap: () => context.push('/wellness/hydration'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WellnessCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;
  final bool highlight;

  const _WellnessCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
    this.highlight = false,
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
          border: Border.all(
            color: highlight ? Colors.black : const Color(0xFFEEEEEE),
            width: highlight ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.black),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
