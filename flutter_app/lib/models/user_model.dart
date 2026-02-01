class User {
  final String uid;
  final String username;
  final String email;
  final String name;
  final String? avatar;
  final String? bio;
  final String? coverImage;
  final bool? isPrivate;
  final bool profileCompleted;
  final bool verified;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final int wellnessStreak;

  User({
    required this.uid,
    required this.username,
    required this.email,
    required this.name,
    this.avatar,
    this.bio,
    this.coverImage,
    this.isPrivate,
    required this.profileCompleted,
    required this.verified,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.wellnessStreak = 0,
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
      coverImage: json['coverImage']?.toString(),
      isPrivate: json['isPrivate'] as bool?,
      profileCompleted: json['profileCompleted'] ?? false,
      verified: json['verified'] ?? false,
      followersCount: (json['followersCount'] ?? 0) as int,
      followingCount: (json['followingCount'] ?? 0) as int,
      postsCount: (json['postsCount'] ?? 0) as int,
      wellnessStreak: (json['wellnessStreak'] ?? 0) as int,
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
