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

  static String _stringId(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    if (v is Map && v['\$oid'] != null) return v['\$oid'].toString();
    return v.toString();
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
    );
  }
}
