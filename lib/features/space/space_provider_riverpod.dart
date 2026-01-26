import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/space_event_model.dart';
import '../../services/space_service.dart';

final spaceProvider =
    StateNotifierProvider<SpaceNotifier, List<SpaceEvent>>(
  (ref) => SpaceNotifier(),
);

class SpaceNotifier extends StateNotifier<List<SpaceEvent>> {
  SpaceNotifier() : super([]);

  final SpaceService _service = SpaceService();
  String? _cursor;
  bool _hasMore = true;
  bool _loading = false;

  bool get hasMore => _hasMore;

  Future<void> load({String? category}) async {
    if (_loading || !_hasMore) return;
    _loading = true;

    final res = await _service.fetchEvents(
      category: category,
      cursor: _cursor,
    );

    final items = (res['items'] as List)
        .map((e) => SpaceEvent.fromJson(e))
        .toList();

    _cursor = res['nextCursor'];
    _hasMore = _cursor != null;

    state = [...state, ...items];
    _loading = false;
  }

  Future<void> join(String id) async {
    await _service.joinEvent(id);

    state = [
      for (final e in state)
        if (e.id == id)
          e.copyWith(
            joined: e.joined + 1,
            joinedByMe: true,
          )
        else
          e
    ];
  }

  void reset() {
    state = [];
    _cursor = null;
    _hasMore = true;
  }
}
