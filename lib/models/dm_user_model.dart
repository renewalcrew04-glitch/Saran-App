class DmUserModel {
  final String uid;
  final String name;
  final String username;
  final String? avatar;

  DmUserModel({
    required this.uid,
    required this.name,
    required this.username,
    this.avatar,
  });

  factory DmUserModel.fromJson(Map<String, dynamic> json) {
    return DmUserModel(
      uid: (json['uid'] ?? '').toString(),
      name: (json['name'] ?? 'User').toString(),
      username: (json['username'] ?? '').toString(),
      avatar: json['avatar']?.toString(),
    );
  }
}
