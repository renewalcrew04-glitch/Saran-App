import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/space/space_provider_riverpod.dart';

class JoinButton extends ConsumerWidget {
  final String eventId;

  const JoinButton({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(spaceProvider);
    final notifier = ref.read(spaceProvider.notifier);

    // SAFE lookup
    final event = events.where((e) => e.id == eventId).toList();
    if (event.isEmpty) {
      return const SizedBox(); // event not loaded yet
    }

    final e = event.first;

    // TEMP logic (will change when bookings API is wired)
    final joinedByMe = e.joined > 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: joinedByMe
            ? null
            : () {
                notifier.join(eventId);
              },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              joinedByMe ? Colors.grey.shade200 : Colors.black,
          foregroundColor:
              joinedByMe ? Colors.black : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: joinedByMe ? 0 : 8,
        ),
        child: Text(joinedByMe ? 'Joined' : 'Join Event'),
      ),
    );
  }
}
