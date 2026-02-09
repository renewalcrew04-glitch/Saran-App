class User {
  final String uid;
  final String username;
  final String email;
  final String name;
  final String? avatar;
  final String? bio;
  /// Profile display location (e.g. "New York, USA"). From API [locationText].
  final String? location;
  final String? coverImage;
  final bool? isPrivate;
  final bool profileCompleted;
  final bool verified;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final int wellnessStreak;
  /// When loading from suggestions/search/profile API: am I following this user (accepted)?
  final bool? isFollowing;
  /// When loading from suggestions/search/profile API: do I have a pending follow request to this user?
  final bool? isFollowPending;

  User({
    required this.uid,
    required this.username,
    required this.email,
    required this.name,
    this.avatar,
    this.bio,
    this.location,
    this.coverImage,
    this.isPrivate,
    required this.profileCompleted,
    required this.verified,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.wellnessStreak = 0,
    this.isFollowing,
    this.isFollowPending,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // ✅ MongoDB support: _id / id / uid
    final dynamic rawId = json['uid'] ?? json['_id'] ?? json['id'];

    return User(
      uid: rawId?.toString() ?? '',
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      avatar: json['avatar']?.toString(),
      bio: json['bio']?.toString(),
      location: (json['locationText'] ?? json['location'])?.toString(),
      coverImage: json['coverImage']?.toString(),
      isPrivate: json['isPrivate'] as bool?,
      profileCompleted: json['profileCompleted'] ?? false,
      verified: json['verified'] ?? false,
      followersCount: (json['followersCount'] ?? 0) as int,
      followingCount: (json['followingCount'] ?? 0) as int,
      postsCount: (json['postsCount'] ?? 0) as int,
      wellnessStreak: (json['wellnessStreak'] ?? 0) as int,
      isFollowing: json['isFollowing'] as bool?,
      isFollowPending: json['isFollowPending'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'name': name,
      'avatar': avatar,
      'bio': bio,
      'location': location,
      'coverImage': coverImage,
      'isPrivate': isPrivate,
      'profileCompleted': profileCompleted,
      'verified': verified,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'wellnessStreak': wellnessStreak,
    };
  }
}
