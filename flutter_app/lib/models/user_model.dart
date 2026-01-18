class User {
  final String uid;
  final String username;
  final String email;
  final String name;
  final String? avatar;
  final String? bio;
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
    this.isPrivate,
    required this.profileCompleted,
    required this.verified,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.wellnessStreak = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'],
      bio: json['bio'],
      isPrivate: json['isPrivate'],
      profileCompleted: json['profileCompleted'] ?? false,
      verified: json['verified'] ?? false,
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      postsCount: json['postsCount'] ?? 0,
      wellnessStreak: json['wellnessStreak'] ?? 0,
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
