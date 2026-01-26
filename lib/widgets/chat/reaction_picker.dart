import 'package:flutter/material.dart';

class ReactionPicker {
  static Future<String?> show(BuildContext context) async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        final reactions = ['❤️', '😂', '👍', '😮'];
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 14,
            children: reactions
                .map(
                  (r) => GestureDetector(
                    onTap: () => Navigator.pop(context, r),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Text(r, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}
