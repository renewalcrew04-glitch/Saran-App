import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/space_event_model.dart';
import '../../services/space_service.dart';

// 1. Service Provider
final spaceServiceProvider = Provider<SpaceService>((ref) {
  return SpaceService();
});

// 2. State Controller
class SpaceEventsNotifier extends StateNotifier<List<SpaceEvent>> {
  final SpaceService _service;
  bool isLoading = false;
  bool hasMore = true;

  SpaceEventsNotifier(this._service) : super([]);

  Future<void> load({String category = 'All'}) async {
    if (isLoading) return;
    isLoading = true;

    try {
      final events = await _service.fetchEvents(category: category);
      
      if (events.isEmpty) {
        hasMore = false;
      } else {
        state = events;
        hasMore = false;
      }
    } catch (e) {
      print("Provider Error: $e");
      hasMore = false;
    } finally {
      isLoading = false;
    }
  }

  void reset() {
    state = [];
    isLoading = false;
    hasMore = true;
  }

  // ✅ Method called by JoinButton and EventDetailsScreen
  Future<void> joinEvent(String eventId) async {
    final success = await _service.joinEvent(eventId);
    if (success) {
      state = [
        for (final event in state)
          if (event.id == eventId)
            event.copyWith(isJoined: true, attendeesCount: event.attendeesCount + 1)
          else
            event
      ];
    }
  }
}

// 3. Main Provider
final spaceProvider = StateNotifierProvider<SpaceEventsNotifier, List<SpaceEvent>>((ref) {
  final service = ref.watch(spaceServiceProvider);
  return SpaceEventsNotifier(service);
});