class SFrame {
  final String id;
  final String? uid; // Can be ID or populated object
  final String mediaType; // 'photo', 'video', 'text'
  final String? mediaUrl;
  final String? textContent;
  final String? mood;
  final String? filter; // ✅ Added missing field
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> views;

  SFrame({
    required this.id,
    this.uid,
    required this.mediaType,
    this.mediaUrl,
    this.textContent,
    this.mood,
    this.filter, // ✅ Initialize
    required this.createdAt,
    required this.expiresAt,
    this.views = const [],
  });

  factory SFrame.fromJson(Map<String, dynamic> json) {
    return SFrame(
      id: json['_id'] ?? json['id'] ?? '',
      uid: json['uid'] is Map ? json['uid']['_id'] : json['uid'],
      mediaType: json['mediaType'] ?? 'text',
      mediaUrl: json['mediaUrl'],
      textContent: json['textContent'],
      mood: json['mood'],
      filter: json['filter'], // ✅ Map from JSON
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null 
          ? DateTime.parse(json['expiresAt']) 
          : DateTime.now().add(const Duration(hours: 24)),
      views: (json['views'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}