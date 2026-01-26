class MessageModel {
  final String id;
  final String senderUid;
  final String receiverUid;
  final String conversationId;

  final String type; // text | image | voice
  final String? text;
  final String? imageUrl;
  final String? voiceUrl;

  final bool read;
  final Map<String, String> reactions;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.senderUid,
    required this.receiverUid,
    required this.conversationId,
    required this.type,
    required this.text,
    required this.imageUrl,
    required this.voiceUrl,
    required this.read,
    required this.reactions,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    final Map<String, String> parsedReactions = {};
    final raw = json['reactions'];
    if (raw is Map) {
      raw.forEach((k, v) {
        parsedReactions[k.toString()] = v.toString();
      });
    }

    return MessageModel(
      id: json['_id']?.toString() ?? '',
      senderUid: json['senderUid']?.toString() ?? '',
      receiverUid: json['receiverUid']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      text: json['text']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      voiceUrl: json['voiceUrl']?.toString(),
      read: json['read'] == true,
      reactions: parsedReactions,
      createdAt: parseDate(json['createdAt']),
    );
  }

  bool get isText => type == 'text';
  bool get isImage => type == 'image';
  bool get isVoice => type == 'voice';
}
