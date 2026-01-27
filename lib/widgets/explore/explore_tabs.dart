import 'package:flutter/material.dart';

class ExploreTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const ExploreTabs({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  static const List<String> tabs = [
    "All",
    "People",
    "Texts",
    "Photos",
    "Videos",
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final active = selectedIndex == index;

          return GestureDetector(
            onTap: () => onTap(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: active ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black, width: 1.2),
              ),
              child: Text(
                tabs[index],
                style: TextStyle(
                  color: active ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
