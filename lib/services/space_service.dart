import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/space_event_model.dart';

class SpaceService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: { 'Content-Type': 'application/json' },
    ),
  );

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Options> _getAuthOptions() async {
    final token = await _getToken();
    return Options(headers: { 'Authorization': 'Bearer $token' });
  }

  /// Fetch Feed Events
  Future<List<SpaceEvent>> fetchEvents({String? category}) async {
    try {
      final options = await _getAuthOptions();
      final query = <String, dynamic>{};
      if (category != null && category != 'All') query['category'] = category;

      final response = await _dio.get('/space/events', queryParameters: query, options: options);

      if (response.statusCode == 200) {
        final data = response.data;
        List list = [];
        if (data is Map && data.containsKey('items')) list = data['items'];
        else if (data is List) list = data;
        return list.map((e) => SpaceEvent.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// ✅ Fetch HOSTED Events
  Future<List<SpaceEvent>> fetchHostedEvents() async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get('/space/hosted-events', options: options);
      if (response.statusCode == 200) {
        final List data = response.data is List ? response.data : [];
        return data.map((e) => SpaceEvent.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// ✅ Fetch BOOKED Events
  Future<List<SpaceEvent>> fetchBookedEvents() async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get('/space/booked-events', options: options);
      if (response.statusCode == 200) {
        final List data = response.data is List ? response.data : [];
        return data.map((e) => SpaceEvent.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> joinEvent(String eventId) async {
    try {
      final options = await _getAuthOptions();
      await _dio.post('/space/events/$eventId/join', options: options);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createEvent(Map<String, dynamic> eventData) async {
    try {
      final options = await _getAuthOptions();
      await _dio.post('/space/events', data: eventData, options: options);
      return true;
    } catch (e) {
      print("Error creating event: $e");
      return false;
    }
  }
}