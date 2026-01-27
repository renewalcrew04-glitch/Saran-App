import 'package:flutter/material.dart';

class SpaceCategories extends StatelessWidget {
  final String selected;
  final Function(String) onChanged;

  const SpaceCategories({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const categories = [
    'All',
    'Workshop',
    'Meetup',
    'Fitness',
    'Art',
    'Wellness',
    'Food',
    'Travel',
    'Learning',
    'Social',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = categories[i];
          final active = c == selected;

          return GestureDetector(
            onTap: () => onChanged(c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black12),
              ),
              child: Text(
                c,
                style: TextStyle(
                  color: active ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
