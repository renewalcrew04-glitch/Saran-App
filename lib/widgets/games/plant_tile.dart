import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PlantTile extends StatelessWidget {
  final int stage; // 0 seed, 1 seedling, 2 tree

  const PlantTile({super.key, required this.stage});

  @override
  Widget build(BuildContext context) {
    IconData icon;

    if (stage == 0) {
      icon = FontAwesomeIcons.circleDot; // dot-circle
    } else if (stage == 1) {
      icon = FontAwesomeIcons.seedling;
    } else {
      icon = FontAwesomeIcons.tree;
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: FaIcon(icon, size: 26, color: Colors.black),
      ),
    );
  }
}
