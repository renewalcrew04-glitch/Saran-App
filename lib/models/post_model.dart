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
      originalPostId: json['originalPostId']?.toString(),
      repostedByUid: json['repostedByUid']?.toString(),
      repostedByName: json['repostedByName'],
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
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
    );
  }
}
