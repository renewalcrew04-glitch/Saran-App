import 'user_lite_model.dart';

class ConversationModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageAt;

  final int unreadCount;
  final bool isPinned;
  final bool isMuted;
  final bool isArchived;

  final UserLiteModel? otherUser;

  ConversationModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.isPinned,
    required this.isMuted,
    required this.isArchived,
    required this.otherUser,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return ConversationModel(
      id: json['_id']?.toString() ?? '',
      participants: (json['participants'] as List? ?? []).map((e) => e.toString()).toList(),
      lastMessage: json['lastMessage']?.toString() ?? '',
      lastMessageAt: parseDate(json['lastMessageAt']),
      unreadCount: (json['unreadCount'] is num) ? (json['unreadCount'] as num).toInt() : 0,
      isPinned: json['isPinned'] == true,
      isMuted: json['isMuted'] == true,
      isArchived: json['isArchived'] == true,
      otherUser: json['otherUser'] is Map<String, dynamic>
          ? UserLiteModel.fromJson(json['otherUser'])
          : null,
    );
  }
}
