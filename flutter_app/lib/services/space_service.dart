import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
        if (data is Map && data.containsKey('items')) {
          list = data['items'];
        } else if (data is List) {
          list = data;
        }
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

  /// Joins the event. Throws on failure (e.g. not found, already joined, auth).
  Future<void> joinEvent(String eventId) async {
    final options = await _getAuthOptions();
    try {
      final response = await _dio.post(
        '/space/events/$eventId/join',
        options: options,
      );
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return;
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map &&
              (e.response!.data as Map).containsKey('message')
          ? (e.response!.data as Map)['message'].toString()
          : (e.response?.statusMessage ?? e.message ?? 'Failed to join');
      debugPrint('Join event error: $msg');
      throw Exception(msg);
    }
    throw Exception('Failed to join event');
  }

  /// Leaves the event. Throws on failure (e.g. not joined, auth).
  Future<void> leaveEvent(String eventId) async {
    final options = await _getAuthOptions();
    try {
      final response = await _dio.post(
        '/space/events/$eventId/leave',
        options: options,
      );
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return;
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map &&
              (e.response!.data as Map).containsKey('message')
          ? (e.response!.data as Map)['message'].toString()
          : (e.response?.statusMessage ?? e.message ?? 'Failed to leave');
      debugPrint('Leave event error: $msg');
      throw Exception(msg);
    }
    throw Exception('Failed to leave event');
  }

  Future<bool> createEvent(Map<String, dynamic> eventData) async {
    try {
      final options = await _getAuthOptions();
      await _dio.post('/space/events', data: eventData, options: options);
      return true;
    } catch (e) {
      debugPrint("Error creating event: $e");
      return false;
    }
  }

  /// Fetch full event by id (for edit screen).
  Future<Map<String, dynamic>?> getEventById(String eventId) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get('/space/events/$eventId', options: options);
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching event: $e");
      return null;
    }
  }

  /// Returns null on success, or an error message string on failure.
  /// Uses PUT /api/events/:id (event routes) so update works even if /api/space PUT is not deployed.
  Future<String?> updateEvent(String eventId, Map<String, dynamic> eventData) async {
    try {
      final options = await _getAuthOptions();
      final url = ApiConfig.getUrl('events/$eventId');
      final response = await _dio.put(
        url,
        data: eventData,
        options: options,
      );
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return null;
      }
      final msg = response.data is Map && response.data['message'] != null
          ? response.data['message'].toString()
          : 'Failed to update event';
      return msg;
    } on DioException catch (e) {
      final msg = e.response?.data is Map && e.response?.data['message'] != null
          ? e.response?.data['message'].toString()
          : (e.response?.statusMessage ?? e.message ?? 'Failed to update event');
      debugPrint("Error updating event: $e");
      debugPrint("Response: ${e.response?.data}");
      return msg;
    } catch (e) {
      debugPrint("Error updating event: $e");
      return e.toString();
    }
  }
}