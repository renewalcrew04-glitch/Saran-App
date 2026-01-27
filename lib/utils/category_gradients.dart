import 'package:flutter/material.dart';

class CategoryGradients {
  static const Map<String, List<Color>> _gradients = {
    "Wellness": [Color(0xFF56CCF2), Color(0xFF2F80ED)],
    "Career": [Color(0xFFF2994A), Color(0xFFF2C94C)],
    "Lifestyle": [Color(0xFF9B51E0), Color(0xFFBB6BD9)],
    "Motherhood": [Color(0xFFFF758C), Color(0xFFFF7EB3)],
    "Relationships": [Color(0xFFFF6A88), Color(0xFFFF99AC)],
    "Creativity": [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
    "Travel": [Color(0xFF11998E), Color(0xFF38EF7D)],
    "Inspiration": [Color(0xFFFF512F), Color(0xFFDD2476)],
    "Beauty": [Color(0xFFF857A6), Color(0xFFFF5858)],
    "Fitness": [Color(0xFF00B09B), Color(0xFF96C93D)],
    "Food": [Color(0xFFFDC830), Color(0xFFF37335)],
    "Fashion": [Color(0xFFDA4453), Color(0xFF89216B)],
    "Education": [Color(0xFF396AFC), Color(0xFF2948FF)],
  };

  /// Single category gradient
  static LinearGradient forCategory(String category) {
    final colors = _gradients[category] ??
        const [Color(0xFFB993D6), Color(0xFF8CA6DB)];

    return LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Multi-category blended gradient
  static LinearGradient forCategories(List<String> categories) {
    final colors = categories
        .map((c) => _gradients[c])
        .where((c) => c != null)
        .expand((c) => c!)
        .toList();

    return LinearGradient(
      colors: colors.isNotEmpty
          ? colors
          : [const Color(0xFFB993D6), const Color(0xFF8CA6DB)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
