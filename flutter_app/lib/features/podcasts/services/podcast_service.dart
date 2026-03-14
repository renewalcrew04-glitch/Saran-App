import '../../../services/api_client.dart';
import '../models/podcast_model.dart';
import '../models/episode_model.dart';

class PodcastService {

  Future<List<PodcastModel>> fetchPodcasts() async {
    final res = await ApiClient.get('/api/podcasts');

    final List data = res['data'] ?? [];

    return data.map((e) => PodcastModel.fromJson(e)).toList();
  }

  Future<List<EpisodeModel>> fetchEpisodes(String podcastId) async {
    final res = await ApiClient.get('/api/podcasts/$podcastId/episodes');

    final List data = res['data'] ?? [];

    return data.map((e) => EpisodeModel.fromJson(e)).toList();
  }

  Future<void> increaseListen(String episodeId) async {
    await ApiClient.post(
      '/api/episodes/$episodeId/listen',
      body: {},
    );
  }
}