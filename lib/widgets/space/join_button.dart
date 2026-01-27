import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/space/space_provider_riverpod.dart';
import '../../models/space_event_model.dart';

class JoinButton extends ConsumerWidget {
  final SpaceEvent event;

  const JoinButton({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(spaceProvider.notifier);

    if (event.isJoined) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
            const SizedBox(width: 4),
            Text(
              "Joined",
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton(
      onPressed: () {
        // ✅ Fixed: Using correct method name 'joinEvent'
        notifier.joinEvent(event.id);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: const Text("Join", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}