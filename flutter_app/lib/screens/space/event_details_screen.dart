import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/api_config.dart';
import '../../utils/media_utils.dart';
import '../../models/space_event_model.dart';
import '../../features/space/space_provider_riverpod.dart';

class EventDetailsScreen extends ConsumerStatefulWidget {
  final SpaceEvent event;

  // ✅ This constructor was missing the 'required this.event'
  const EventDetailsScreen({super.key, required this.event});

  @override
  ConsumerState<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends ConsumerState<EventDetailsScreen> {
  late SpaceEvent event;
  bool _isJoining = false;
  bool _isLeaving = false;
  bool _loadingJoinState = true;

  @override
  void initState() {
    super.initState();
    event = widget.event;
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshEventFromServer());
  }

  Future<void> _refreshEventFromServer() async {
    final service = ref.read(spaceServiceProvider);
    final data = await service.getEventById(event.id);
    if (mounted && data != null) {
      setState(() {
        event = SpaceEvent.fromJson(data);
        _loadingJoinState = false;
      });
    } else if (mounted) {
      setState(() => _loadingJoinState = false);
    }
  }

  static String _eventCoverUrl(SpaceEvent event) {
    final base = ApiConfig.networkImageUrl(event.coverUrl!) ?? event.coverUrl!;
    if (event.updatedAt != null) {
      return '$base${base.contains('?') ? '&' : '?'}v=${event.updatedAt!.millisecondsSinceEpoch}';
    }
    return base;
  }

  Future<void> _joinEvent() async {
    setState(() => _isJoining = true);
    try {
      final notifier = ref.read(spaceProvider.notifier);
      await notifier.joinEvent(event.id);

      if (mounted) {
        setState(() {
          event = event.copyWith(
            isJoined: true,
            attendeesCount: event.attendeesCount + 1,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You have joined this event!")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('Already joined') || msg.contains('already joined')) {
        setState(() {
          event = event.copyWith(isJoined: true);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You're already in this event.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to join: ${msg.replaceFirst('Exception: ', '')}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  Future<void> _leaveEvent() async {
    setState(() => _isLeaving = true);
    try {
      final notifier = ref.read(spaceProvider.notifier);
      await notifier.leaveEvent(event.id);
      if (mounted) {
        setState(() {
          event = event.copyWith(
            isJoined: false,
            attendeesCount: (event.attendeesCount - 1).clamp(0, event.attendeesCount),
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You have left this event.")),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to leave: $msg")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLeaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, MMM d • h:mm a').format(event.date);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Event Details",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              color: const Color(0xFFF5F5F5),
              child: event.coverUrl != null && event.coverUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: _eventCoverUrl(event),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 200,
                      placeholder: (_, __) => const ImageLoadingPlaceholder(width: double.infinity, height: 200),
                      errorWidget: (_, __, ___) => const Center(child: Icon(Icons.event, size: 80, color: Colors.black12)),
                    )
                  : const Center(child: Icon(Icons.event, size: 80, color: Colors.black12)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.category.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: event.isOnline ? Colors.green.shade700 : Colors.grey.shade700,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.isOnline ? 'ONLINE' : 'OFFLINE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        backgroundImage: event.hostAvatar != null
                            ? NetworkImage(event.hostAvatar!)
                            : null,
                        radius: 20,
                        child: event.hostAvatar == null
                            ? const Icon(Icons.person, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Hosted by", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text(
                            event.hostName ?? "Unknown Host",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _infoRow(Icons.calendar_today, dateStr),
                  const SizedBox(height: 16),
                  if (event.isOnline && event.meetingLink != null && event.meetingLink!.isNotEmpty) ...[
                    _infoRow(Icons.link, 'Online – Joining link below'),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 34),
                      child: SelectableText(
                        event.meetingLink!,
                        style: const TextStyle(fontSize: 14, color: Colors.blue, decoration: TextDecoration.underline),
                      ),
                    ),
                  ] else
                    _infoRow(Icons.location_on, event.location.isNotEmpty ? event.location : 'Address TBA'),
                  const SizedBox(height: 16),
                  _infoRow(Icons.people, "${event.attendeesCount} / ${event.capacity} Attending"),
                  if (event.isJoined) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          "You joined • ${event.attendeesCount}/${event.capacity} going",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  _infoRow(Icons.attach_money, event.price == 0 ? "Free Event" : "₹${event.price}"),
                  const SizedBox(height: 32),
                  const Text(
                    "About Event",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    event.description.isEmpty
                        ? "No description provided."
                        : event.description,
                    style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: _loadingJoinState || _isJoining || _isLeaving
                ? null
                : (event.isJoined ? _leaveEvent : _joinEvent),
            style: ElevatedButton.styleFrom(
              backgroundColor: event.isJoined ? Colors.red.shade600 : Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              disabledBackgroundColor: Colors.grey[300],
            ),
            child: _isJoining || _isLeaving || _loadingJoinState
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    event.isJoined ? "Leave" : "Join Event",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.black54, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}