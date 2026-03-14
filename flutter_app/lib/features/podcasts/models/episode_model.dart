class EpisodeModel {
  final String id;
  final String podcastId;
  final String title;
  final String description;
  final String audioUrl;
  final String coverUrl;
  final int duration;
  final int listens;

  EpisodeModel({
    required this.id,
    required this.podcastId,
    required this.title,
    required this.description,
    required this.audioUrl,
    required this.coverUrl,
    required this.duration,
    required this.listens,
  });

  factory EpisodeModel.fromJson(Map<String, dynamic> json) {
    return EpisodeModel(
      id: json['_id'],
      podcastId: json['podcastId'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      audioUrl: json['audioUrl'],
      coverUrl: json['coverUrl'] ?? '',
      duration: json['duration'] ?? 0,
      listens: json['listens'] ?? 0,
    );
  }
}