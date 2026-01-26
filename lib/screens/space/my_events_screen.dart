import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/space/space_provider_riverpod.dart';

class MyEventsScreen extends ConsumerWidget {
  const MyEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(spaceProvider);

    // TEMP: booked = joined > 0
    final bookedEvents = events.where((e) => e.joined > 0).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Events'),
      ),
      body: bookedEvents.isEmpty
          ? const Center(
              child: Text(
                'You haven’t booked any events yet',
                style: TextStyle(color: Colors.black54),
              ),
            )
          : ListView.builder(
              itemCount: bookedEvents.length,
              itemBuilder: (_, i) {
                final e = bookedEvents[i];
                return ListTile(
                  title: Text(e.title),
                  subtitle: Text(e.location),
                  trailing: Text('${e.joined} joined'),
                );
              },
            ),
    );
  }
}
