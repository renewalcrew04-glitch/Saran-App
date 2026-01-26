class SFrame {
  final String id;
  final String uid;
  final String mediaType;
  final String? mediaUrl;
  final String? textContent;
  final String? filter;
  final List<dynamic> views;

  SFrame({
    required this.id,
    required this.uid,
    required this.mediaType,
    this.mediaUrl,
    this.textContent,
    this.filter,
    required this.views,
  });

  factory SFrame.fromJson(Map<String, dynamic> d) {
    return SFrame(
      id: d['_id'],
      uid: d['uid'],
      mediaType: d['mediaType'],
      mediaUrl: d['mediaUrl'],
      textContent: d['textContent'],
      filter: d['filter'],
      views: d['views'] ?? [],
    );
  }
}
