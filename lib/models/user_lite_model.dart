class UserLiteModel {
  final String id;
  final String name;
  final String? username;
  final String? avatar;
  final bool online;

  UserLiteModel({
    required this.id,
    required this.name,
    this.username,
    this.avatar,
    required this.online,
  });

  factory UserLiteModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['_id'] ?? json['uid'] ?? json['id'];

    return UserLiteModel(
      id: rawId?.toString() ?? '',
      name: json['name']?.toString() ?? 'User',
      username: json['username']?.toString(),
      avatar: json['avatar']?.toString(),
      online: json['online'] == true,
    );
  }
}
