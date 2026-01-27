import 'package:flutter/material.dart';
import '../models/space_event_model.dart';

class SpaceProvider extends ChangeNotifier {
  final List<SpaceEvent> _events = [];
  final List<String> _bookedIds = [];

  List<SpaceEvent> get events => _events;

  List<SpaceEvent> eventsByCategory(String category) {
    if (category == 'All') return _events;
    return _events.where((e) => e.category == category).toList();
  }

  List<SpaceEvent> get bookedEvents =>
      _events.where((e) => _bookedIds.contains(e.id)).toList();

  void loadDummyEvents() {
    if (_events.isNotEmpty) return;

    _events.add(
      SpaceEvent(
        id: '1',
        title: 'FareWell',
        category: 'Meetup',
        location: 'Grand Auditorium, SSN College',
        dateTime: DateTime.now(),
        price: 100,
        capacity: 100,
        joined: 0,
      ),
    );

    notifyListeners();
  }

  bool isJoined(String id) => _bookedIds.contains(id);

  void joinEvent(String id) {
    if (_bookedIds.contains(id)) return;
    _bookedIds.add(id);

    final index = _events.indexWhere((e) => e.id == id);
    if (index != -1) {
      _events[index] =
          _events[index].copyWith(joined: _events[index].joined + 1);
    }
    notifyListeners();
  }
}
