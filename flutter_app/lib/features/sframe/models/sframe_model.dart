class SFrame {
  final String id;
  final String uid;
  final String mediaType;
  final String? mediaUrl;
  final String? textContent;
  final String? filter;
  final List<dynamic> views;
  /// User ids who sent a heart (echo) on this story.
  final List<dynamic> echoes;
  final DateTime? createdAt;
  final String? ownerName;
  final String? ownerAvatar;
  final String? ownerUsername;

  SFrame({
    required this.id,
    required this.uid,
    required this.mediaType,
    this.mediaUrl,
    this.textContent,
    this.filter,
    required this.views,
    this.echoes = const [],
    this.createdAt,
    this.ownerName,
    this.ownerAvatar,
    this.ownerUsername,
  });

  int get viewCount => views.length;

  static String _stringId(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    if (v is Map && v['\$oid'] != null) return v['\$oid'].toString();
    return v.toString();
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  factory SFrame.fromJson(Map<String, dynamic> d) {
    return SFrame(
      id: _stringId(d['_id']),
      uid: _stringId(d['uid']),
      mediaType: d['mediaType']?.toString() ?? 'text',
      mediaUrl: d['mediaUrl']?.toString(),
      textContent: d['textContent']?.toString(),
      filter: d['filter']?.toString(),
      views: d['views'] is List ? d['views'] as List<dynamic> : [],
      echoes: d['echoes'] is List ? d['echoes'] as List<dynamic> : [],
      createdAt: _parseDate(d['createdAt']),
      ownerName: d['ownerName']?.toString(),
      ownerAvatar: (d['ownerAvatar'] ?? d['owner']?['avatar'])?.toString(),
      ownerUsername: d['ownerUsername']?.toString(),
    );
  }
}
