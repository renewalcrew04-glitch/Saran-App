import 'package:flutter/material.dart';

class ExploreSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  const ExploreSearchBar({
    super.key,
    required this.controller,
    required this.onClear,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.black),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: (_) => onSubmitted(),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                hintText: "Search women, posts, topics...",
                border: InputBorder.none,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: Container(
                height: 28,
                width: 28,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
        ],
      ),
    );
  }
}
