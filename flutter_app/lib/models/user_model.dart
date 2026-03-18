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
  /// Gender from signup: female, trans_woman, male.
  final String? gender;
  /// Date of birth from signup.
  final DateTime? dob;
  /// Selfie image URL from signup/verification.
  final String? selfieImage;
  final bool verified;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final int wellnessStreak;
  final String? website;
  final String? phone;
  final List<String> interests;
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
    this.gender,
    this.dob,
    this.selfieImage,
    required this.verified,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.wellnessStreak = 0,
    this.website,
    this.phone,
    this.interests = const <String>[],
    this.isFollowing,
    this.isFollowPending,
  });

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

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
      gender: json['gender']?.toString(),
      dob: json['dob'] != null ? _parseDate(json['dob']) : null,
      selfieImage: json['selfieImage']?.toString(),
      verified: json['verified'] ?? false,
      followersCount: (json['followersCount'] ?? 0) as int,
      followingCount: (json['followingCount'] ?? 0) as int,
      postsCount: (json['postsCount'] ?? 0) as int,
      wellnessStreak: (json['wellnessStreak'] ?? 0) as int,
      website: json['website']?.toString(),
      phone: json['phone']?.toString(),
      interests: json['interests'] != null
          ? List<String>.from(
              (json['interests'] as List).map((e) => e.toString()))
          : <String>[],
      isFollowing: json['isFollowing'] as bool?,
      isFollowPending: json['isFollowPending'] as bool?,
    );
  }

  /// Returns a copy of this user with the given fields replaced.
  /// Pass [clearWebsite] = true to explicitly set website to null.
  User copyWith({
    String? name,
    String? bio,
    String? location,
    bool? isPrivate,
    String? website,
    bool clearWebsite = false,
    String? phone,
    List<String>? interests,
    String? avatar,
    String? coverImage,
    int? followersCount,
    int? followingCount,
    int? postsCount,
  }) {
    return User(
      uid: uid,
      username: username,
      email: email,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      coverImage: coverImage ?? this.coverImage,
      isPrivate: isPrivate ?? this.isPrivate,
      profileCompleted: profileCompleted,
      gender: gender,
      dob: dob,
      selfieImage: selfieImage,
      verified: verified,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      wellnessStreak: wellnessStreak,
      website: clearWebsite ? null : (website ?? this.website),
      phone: phone ?? this.phone,
      interests: interests ?? this.interests,
      isFollowing: isFollowing,
      isFollowPending: isFollowPending,
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
      'gender': gender,
      'dob': dob?.toIso8601String(),
      'selfieImage': selfieImage,
      'verified': verified,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'wellnessStreak': wellnessStreak,
      'website': website,
      'phone': phone,
      'interests': interests,
    };
  }
}
