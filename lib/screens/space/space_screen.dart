import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/space/space_provider_riverpod.dart';
import '../../widgets/space/space_categories.dart';
import '../../widgets/space/space_event_card.dart';

class SpaceScreen extends ConsumerStatefulWidget {
  const SpaceScreen({super.key});

  @override
  ConsumerState<SpaceScreen> createState() => _SpaceScreenState();
}

class _SpaceScreenState extends ConsumerState<SpaceScreen> {
  String category = 'All';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(spaceProvider.notifier).load(category: category);
    });
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(spaceProvider);
    final notifier = ref.read(spaceProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Space')),
      body: Column(
        children: [
          SpaceCategories(
            selected: category,
            onChanged: (c) {
              setState(() => category = c);
              notifier.reset();
              notifier.load(category: category);
            },
          ),

          Expanded(
            child: ListView.builder(
              itemCount: events.length + 1,
              itemBuilder: (_, i) {
                if (i == events.length) {
                  if (notifier.hasMore) {
                    notifier.load(category: category);
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return const SizedBox.shrink();
                }
                return SpaceEventCard(event: events[i]);
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black,
        onPressed: () {
          Navigator.pushNamed(context, '/space/my-events');
        },
        label: const Text('My Events'),
      ),
    );
  }
}
