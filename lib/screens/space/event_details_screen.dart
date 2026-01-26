import 'package:flutter/material.dart';
import '../../models/space_event_model.dart';
import '../../widgets/space/join_button.dart';
import '../../features/spaces/services/space_api.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class EventDetailsScreen extends StatefulWidget {
  const EventDetailsScreen({super.key});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool reminderEnabled = true;
  bool loading = true;

  late SpaceApi _spaceApi;
  late SpaceEvent event;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    event = ModalRoute.of(context)!.settings.arguments as SpaceEvent;

    final token =
        Provider.of<AuthProvider>(context, listen: false).token;

    _spaceApi = SpaceApi();
    if (token != null) {
      _spaceApi.setToken(token);
    }

    _loadReminderStatus();
  }

  Future<void> _loadReminderStatus() async {
    try {
      final enabled =
          await _spaceApi.getReminderStatus(event.id);
      if (mounted) {
        setState(() {
          reminderEnabled = enabled;
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          reminderEnabled = true;
          loading = false;
        });
      }
    }
  }

  Future<void> _toggleReminder(bool value) async {
    setState(() => reminderEnabled = value);
    await _spaceApi.updateReminderStatus(event.id, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(event.title)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              event.location,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ),

          // 🔔 EVENT REMINDER TOGGLE
          if (!loading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SwitchListTile(
                title: const Text("Event reminders"),
                subtitle: const Text(
                  "Get notified before this event starts",
                ),
                value: reminderEnabled,
                onChanged: _toggleReminder,
              ),
            ),

          // JOIN BUTTON (UNCHANGED)
          JoinButton(eventId: event.id),
        ],
      ),
    );
  }
}
