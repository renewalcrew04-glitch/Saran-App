import 'package:flutter/material.dart';
import 'glass_box.dart';

/// Horizontal scrollable filter-tab row that delegates to [LiquidGlassChip].
class CategoryChips extends StatelessWidget {
  final List<String> items;
  final String selected;
  final ValueChanged<String> onChanged;

  const CategoryChips({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final label = items[index];
          return LiquidGlassChip(
            label: label,
            isActive: label == selected,
            onTap: () => onChanged(label),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          );
        },
      ),
    );
  }
}
