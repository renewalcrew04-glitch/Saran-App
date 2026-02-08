class AppNotification {
  final String id;
  final String type;
  final String? entityId;
  final String? entityType;
  final bool read;
  final DateTime createdAt;
  /// Actor user (e.g. who requested to follow) - uid, name, username, avatar
  final Map<String, dynamic>? actor;

  AppNotification({
    required this.id,
    required this.type,
    this.entityId,
    this.entityType,
    required this.read,
    required this.createdAt,
    this.actor,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final actorRaw = json['actor'];
    return AppNotification(
      id: json['_id']?.toString() ?? '',
      type: json['type'],
      entityId: json['entityId']?.toString(),
      entityType: json['entityType']?.toString(),
      read: json['read'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      actor: actorRaw is Map ? Map<String, dynamic>.from(actorRaw as Map) : null,
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
      actor: actor,
    );
  }
}
