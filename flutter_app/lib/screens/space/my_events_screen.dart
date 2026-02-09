import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/api_config.dart';
import '../../models/space_event_model.dart';
import '../../features/space/space_provider_riverpod.dart';

class MyEventsScreen extends ConsumerStatefulWidget {
  const MyEventsScreen({super.key});

  @override
  ConsumerState<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends ConsumerState<MyEventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<SpaceEvent> _hostedEvents = [];
  List<SpaceEvent> _bookedEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetch();
  }

  Future<void> _fetch() async {
    final service = ref.read(spaceServiceProvider);
    final results = await Future.wait([
      service.fetchHostedEvents(),
      service.fetchBookedEvents(),
    ]);

    if (mounted) {
      setState(() {
        _hostedEvents = results[0];
        _bookedEvents = results[1];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Events", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // ✅ Custom Tab Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
              ),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              indicatorPadding: const EdgeInsets.all(2),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: "Hosted (${_hostedEvents.length})"),
                Tab(text: "Joined (${_bookedEvents.length})"),
              ],
            ),
          ),

          // ✅ Tab Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.black))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEventList(_hostedEvents, isHosted: true),
                      _buildEventList(_bookedEvents, isHosted: false),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList(List<SpaceEvent> events, {required bool isHosted}) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[200]),
            const SizedBox(height: 16),
            Text(
              isHosted ? "You haven't posted any events." : "You haven't joined any events.",
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _MyEventCard(
          event: event,
          isHosted: isHosted,
          onReturnFromEdit: () {
            if (mounted) _fetch();
          },
        );
      },
    );
  }
}

// ✅ Custom Card – tap to see full event details
class _MyEventCard extends StatelessWidget {
  final SpaceEvent event;
  final bool isHosted;
  final VoidCallback? onReturnFromEdit;

  const _MyEventCard({
    required this.event,
    required this.isHosted,
    this.onReturnFromEdit,
  });

  static String _eventCoverUrl(SpaceEvent event) {
    final base = ApiConfig.networkImageUrl(event.coverUrl!) ?? event.coverUrl!;
    if (event.updatedAt != null) {
      return '$base${base.contains('?') ? '&' : '?'}v=${event.updatedAt!.millisecondsSinceEpoch}';
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/space/details', extra: event),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: event.coverUrl != null && event.coverUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: _eventCoverUrl(event),
                    fit: BoxFit.cover,
                    width: 80,
                    height: 80,
                    placeholder: (_, __) => const Center(child: Icon(Icons.image, color: Colors.grey)),
                    errorWidget: (_, __, ___) => const Icon(Icons.image, color: Colors.grey),
                  )
                : const Icon(Icons.image, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isHosted)
                      GestureDetector(
                        onTap: () async {
                          await context.push('/space/edit?id=${Uri.encodeComponent(event.id)}');
                          onReturnFromEdit?.call();
                        },
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.edit, size: 20, color: Colors.black),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "${DateFormat('MMM d').format(event.date)} • ${DateFormat('HH:mm').format(event.date)}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  event.location,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isHosted ? Icons.people_outline : Icons.check_circle,
                          size: 14,
                          color: isHosted ? Colors.grey : Colors.black87,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isHosted
                              ? "${event.attendeesCount}/${event.capacity} joined"
                              : "You joined • ${event.attendeesCount}/${event.capacity} going",
                          style: TextStyle(
                            color: isHosted ? Colors.grey[600] : Colors.black87,
                            fontSize: 12,
                            fontWeight: isHosted ? FontWeight.w500 : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (isHosted)
                      const Icon(Icons.delete_outline, size: 18, color: Colors.black),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }
}