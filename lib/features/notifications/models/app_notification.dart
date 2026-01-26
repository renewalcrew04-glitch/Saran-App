class AppNotification {
  final String id;
  final String type;
  final String? entityId;
  final String? entityType;
  final bool read;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    this.entityId,
    this.entityType,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id'],
      type: json['type'],
      entityId: json['entityId'],
      entityType: json['entityType'],
      read: json['read'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      type: type,
      entityId: entityId,
      entityType: entityType,
      read: read ?? this.read,
      createdAt: createdAt,
    );
  }
}
