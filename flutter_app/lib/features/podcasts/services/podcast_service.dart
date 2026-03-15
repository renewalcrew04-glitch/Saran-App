import 'package:dio/dio.dart';

import '../../../services/api_client.dart';
import '../models/podcast_model.dart';
import '../models/episode_model.dart';

class PodcastService {
  Future<List<PodcastModel>> fetchPodcasts() async {
    try {
      final res = await ApiClient.get('podcasts');
      final raw = res['data'];
      final List data = raw is List ? raw : (raw != null ? [raw] : []);
      return data
          .map((e) => PodcastModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'podcasts'));
    }
  }

  Future<List<EpisodeModel>> fetchEpisodes(String podcastId) async {
    try {
      final res = await ApiClient.get('podcasts/$podcastId/episodes');
      final raw = res['data'];
      final List data = raw is List ? raw : (raw != null ? [raw] : []);
      return data
          .map((e) => EpisodeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'episodes'));
    }
  }

  static String _messageFromDio(DioException e, String what) {
    final res = e.response;
    if (res != null) {
      final status = res.statusCode ?? 0;
      if (status == 401) return 'Please sign in to load $what.';
      if (status == 403) return 'You don’t have access to $what.';
      if (status >= 500) return 'Server error. Try again later.';
      final msg = res.data is Map && res.data['message'] != null
          ? res.data['message'].toString()
          : null;
      if (msg != null && msg.isNotEmpty) return msg;
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'No connection. Check network and try again.';
    }
    if (e.type == DioExceptionType.receiveTimeout) {
      return 'Request timed out. Try again.';
    }
    return e.message ?? 'Could not load $what.';
  }

  Future<void> increaseListen(String episodeId) async {
    await ApiClient.post('episodes/$episodeId/listen', body: {});
  }
}