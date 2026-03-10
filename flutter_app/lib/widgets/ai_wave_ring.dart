import 'package:flutter/material.dart';
import 'dart:math';

class AIWaveRing extends StatefulWidget {

  final bool active;
  final double size;

  const AIWaveRing({
    super.key,
    required this.active,
    this.size = 240,
  });

  @override
  State<AIWaveRing> createState() => _AIWaveRingState();
}

class _AIWaveRingState extends State<AIWaveRing>
    with SingleTickerProviderStateMixin {

  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {

        double wave = widget.active
            ? sin(controller.value * pi) * 12
            : 0;

        return Container(
          width: widget.size + wave,
          height: widget.size + wave,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.purpleAccent.withOpacity(0.7),
              width: 2,
            ),
          ),
        );
      },
    );
  }
}