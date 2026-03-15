class PodcastModel {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final String category;
  final int totalEpisodes;
  final String? creatorId;

  PodcastModel({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.category,
    required this.totalEpisodes,
    this.creatorId,
  });

  factory PodcastModel.fromJson(Map<String, dynamic> json) {
    return PodcastModel(
      id: json['_id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      coverUrl: json['coverUrl'] ?? '',
      category: json['category'] ?? '',
      totalEpisodes: json['totalEpisodes'] ?? 0,
      creatorId: json['creatorId']?.toString(),
    );
  }
}