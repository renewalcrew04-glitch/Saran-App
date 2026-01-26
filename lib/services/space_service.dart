import '../models/space_event_model.dart';
import 'api_client.dart';

class SpaceService {
  /// Fetch events with cursor pagination
  Future<Map<String, dynamic>> fetchEvents({
    String? category,
    String? cursor,
  }) async {
    final query = <String, dynamic>{};

    if (category != null && category != 'All') {
      query['category'] = category;
    }
    if (cursor != null) {
      query['cursor'] = cursor;
    }

    // ApiClient.get returns Map<String, dynamic>
    final res = await ApiClient.get(
      _withQuery('/space/events', query),
    );

    return res;
  }

  /// Create event
  Future<void> createEvent(Map<String, dynamic> data) async {
    await ApiClient.post(
      '/space/events',
      body: data,
    );
  }

  /// Join event
  Future<void> joinEvent(String id) async {
    await ApiClient.post(
      '/space/events/$id/join',
      body: {},
    );
  }

  /// Helper to append query params (ApiClient has no query support)
  String _withQuery(String path, Map<String, dynamic> query) {
    if (query.isEmpty) return path;

    final q = query.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');

    return '$path?$q';
  }
}
