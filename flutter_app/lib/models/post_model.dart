class Post {
  final String id;
  final String uid;
  final String username;
  final String type;
  final String text;
  final List<String> media;
  final String? thumbnail;
  final bool isQuote;
  final String? originalPostId;
  final Post? quotedPost;
  final String? repostedByUid;
  final String? repostedByName;
  final int likesCount;
  final int commentsCount;
  final int repostsCount;
  final int sharesCount;
  final String visibility;
  final String? category;
  final List<String> hashtags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isLiked;
  final bool hideLikeCount;
  final bool edited;
  final Post? originalPost;


  // USER INFO
  final String? userAvatar;
  final String? userName;
  final bool? userVerified;

  // 🔥 NEW
  final bool isPinned;

  Post({
    required this.id,
    required this.uid,
    required this.username,
    required this.type,
    this.text = '',
    this.media = const [],
    this.thumbnail,
    this.isQuote = false,
    this.originalPostId,
    this.quotedPost,
    this.repostedByUid,
    this.repostedByName,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.repostsCount = 0,
    this.sharesCount = 0,
    this.visibility = 'public',
    this.category,
    this.hashtags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isLiked = false,
    this.userAvatar,
    this.userName,
    this.userVerified,
    this.isPinned = false,
    this.hideLikeCount = false,
    this.edited = false,
    this.originalPost,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['_id'] ?? '',
      uid: json['uid'] is Map ? json['uid']['_id'] : json['uid'].toString(),
      username: json['username'] ?? '',
      type: json['type'] ?? 'text',
      text: json['text'] ?? '',
      media: List<String>.from(json['media'] ?? []),
      thumbnail: json['thumbnail'],
      isQuote: json['isQuote'] ?? false,
      originalPostId: json['originalPostId'] is Map
          ? (json['originalPostId']['_id']?.toString())
          : json['originalPostId']?.toString(),
      quotedPost: _parseQuotedOrOriginalPost(json),
      repostedByUid: json['repostedByUid']?.toString(),
      repostedByName: json['repostedByName'],
      likesCount: json['likesCount'] ?? 0,
      commentsCount: (json['commentsCount'] ?? json['comments_count'] ?? 0) as int,
      repostsCount: json['repostsCount'] ?? 0,
      sharesCount: json['sharesCount'] ?? 0,
      visibility: json['visibility'] ?? 'public',
      category: json['category'],
      hashtags: List<String>.from(json['hashtags'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isLiked: json['isLiked'] ?? false,
      userAvatar: json['uid'] is Map ? json['uid']['avatar'] : null,
      userName: json['uid'] is Map ? json['uid']['name'] : null,
      userVerified:
          json['uid'] is Map ? (json['uid']['verified'] ?? false) : null,
      isPinned: json['isPinned'] ?? false,
      hideLikeCount: json['hideLikeCount'] ?? false,
      edited: json['edited'] ?? false,
      originalPost: _parseQuotedOrOriginalPost(json),
    );
  }

  /// Parses the embedded original post from API (quotedPost, originalPost, or populated originalPostId).
  /// Uses _fromJsonEmbedded for sub-docs that may have missing fields (e.g. only uid, username, type, text, media, createdAt).
  static Post? _parseQuotedOrOriginalPost(Map<String, dynamic> json) {
    if (json['quotedPost'] != null && json['quotedPost'] is Map) {
      return _fromJsonEmbedded(Map<String, dynamic>.from(json['quotedPost'] as Map));
    }
    if (json['originalPost'] != null && json['originalPost'] is Map) {
      return _fromJsonEmbedded(Map<String, dynamic>.from(json['originalPost'] as Map));
    }
    if (json['originalPostId'] != null && json['originalPostId'] is Map) {
      return _fromJsonEmbedded(Map<String, dynamic>.from(json['originalPostId'] as Map));
    }
    return null;
  }

  /// Like fromJson but tolerates missing fields (e.g. populated sub-docs from feed).
  static Post _fromJsonEmbedded(Map<String, dynamic> json) {
    final createdAt = json['createdAt'];
    final updatedAt = json['updatedAt'];
    final date = createdAt != null
        ? (createdAt is DateTime ? createdAt : DateTime.tryParse(createdAt.toString()) ?? DateTime.now())
        : DateTime.now();
    final updated = updatedAt != null
        ? (updatedAt is DateTime ? updatedAt : DateTime.tryParse(updatedAt.toString()) ?? date)
        : date;
    final uidVal = json['uid'];
    final uidStr = uidVal is Map
        ? (uidVal['_id']?.toString() ?? '')
        : (uidVal?.toString() ?? '');
    return Post(
      id: (json['_id'] ?? '').toString(),
      uid: uidStr,
      username: (json['username'] ?? '').toString(),
      type: (json['type'] ?? 'text').toString(),
      text: (json['text'] ?? '').toString(),
      media: List<String>.from(json['media'] ?? []),
      thumbnail: json['thumbnail']?.toString(),
      isQuote: json['isQuote'] == true,
      originalPostId: null,
      quotedPost: null,
      repostedByUid: json['repostedByUid']?.toString(),
      repostedByName: json['repostedByName']?.toString(),
      likesCount: (json['likesCount'] ?? 0) as int,
      commentsCount: (json['commentsCount'] ?? json['comments_count'] ?? 0) as int,
      repostsCount: (json['repostsCount'] ?? 0) as int,
      sharesCount: (json['sharesCount'] ?? 0) as int,
      visibility: (json['visibility'] ?? 'public').toString(),
      category: json['category']?.toString(),
      hashtags: List<String>.from(json['hashtags'] ?? []),
      createdAt: date,
      updatedAt: updated,
      isLiked: json['isLiked'] == true,
      userAvatar: uidVal is Map ? uidVal['avatar']?.toString() : null,
      userName: uidVal is Map ? uidVal['name']?.toString() : null,
      userVerified: uidVal is Map ? (uidVal['verified'] == true) : null,
      isPinned: json['isPinned'] == true,
      hideLikeCount: json['hideLikeCount'] == true,
      edited: json['edited'] == true,
      originalPost: null,
    );
  }
}
