import 'package:flutter/material.dart';

/// Instagram-style Stories row with circular story rings
class StoriesRow extends StatelessWidget {
  const StoriesRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: 10, // Mock stories count
        itemBuilder: (context, index) {
          final scheme = Theme.of(context).colorScheme;
          final isAddStory = index == 0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isAddStory
                            ? null
                            : LinearGradient(
                                colors: [
                                  Colors.purple,
                                  Colors.pink,
                                  Colors.orange,
                                ],
                              ),
                        border: isAddStory
                            ? Border.all(color: scheme.outlineVariant, width: 2)
                            : null,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.surface,
                        ),
                        child: isAddStory
                            ? Icon(
                                Icons.add,
                                color: scheme.onSurfaceVariant,
                                size: 24,
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: scheme.outlineVariant,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isAddStory ? 'Your story' : 'Username',
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
