import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/space/space_provider_riverpod.dart';
import '../../widgets/space/space_event_card.dart';
import '../../features/podcasts/screens/podcast_home_screen.dart';
import '../../constants/space_categories.dart';

class SpaceScreen extends ConsumerStatefulWidget {
  const SpaceScreen({super.key});

  @override
  ConsumerState<SpaceScreen> createState() => _SpaceScreenState();
}

class _SpaceScreenState extends ConsumerState<SpaceScreen> {
  String category = 'All';
  final List<String> categories = SpaceCategories.all;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(spaceProvider.notifier).load(category: category));
  }

  void _openCategoryFilter(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: categories.map((c) {
            return ListTile(
              title: Text(c),
              trailing: category == c
                  ? Icon(Icons.check, color: scheme.primary)
                  : null,
              onTap: () {
                Navigator.pop(context);

                setState(() => category = c);

                ref.read(spaceProvider.notifier).reset();
                ref.read(spaceProvider.notifier).load(category: category);
              },
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(spaceProvider);
    final notifier = ref.read(spaceProvider.notifier);

    final scheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Spaces',
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          // ✅ Premium Black Pill Button " + Host "
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => context.push('/space/create'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add, color: scheme.onPrimary, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      "Host",
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    /// My Events Button
                    GestureDetector(
                      onTap: () => context.push('/space/my-events'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.confirmation_number_outlined,
                                size: 18, color: scheme.onSurface),
                            const SizedBox(width: 6),
                            Text(
                              "My Events",
                              style: TextStyle(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    /// Filter Button
                    GestureDetector(
                      onTap: () => _openCategoryFilter(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.tune, size: 18, color: scheme.onSurface),
                            const SizedBox(width: 6),
                            Text(
                              category,
                              style: TextStyle(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Event List
              Expanded(
                child: events.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_note, size: 64, color: scheme.outlineVariant),
                            const SizedBox(height: 16),
                            Text("No events found", style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
                        itemCount: events.length,
                        itemBuilder: (_, i) => SpaceEventCard(event: events[i]),
                      ),
              ),
            ],
          ),

          // Podcasts Floating Button
          Positioned(
            bottom: 110,
            right: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PodcastHomeScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.podcasts, color: scheme.onPrimary),
                    const SizedBox(width: 8),
                    Text(
                      "Podcasts",
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}