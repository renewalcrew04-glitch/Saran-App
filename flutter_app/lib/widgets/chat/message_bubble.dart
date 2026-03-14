import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../config/api_config.dart';
import '../../utils/media_utils.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../screens/profile/user_profile_screen.dart';
import 'voice_waveform_widget.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isOwn;
  final VoidCallback? onLongPress;
  final VoidCallback? onTapImage;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isOwn,
    this.onLongPress,
    this.onTapImage,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isOwn ? Colors.black : const Color(0xFFEEEEEE);
    final fg = isOwn ? Colors.white : Colors.black;

    Widget content;

    if (message.isImage && message.imageUrl != null) {
      content = GestureDetector(
        onTap: onTapImage,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: message.imageUrl!,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            placeholder: (_, __) => const ImageLoadingPlaceholder(width: 200, height: 200),
            errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 48, color: Colors.grey),
          ),
        ),
      );
    } else if (message.isProfile && message.profilePayload != null) {
      content = _ProfileShareBubble(
        payload: message.profilePayload!,
        isOwn: isOwn,
      );
    } else if (message.isVoice && message.voiceUrl != null) {
      content = VoiceWaveformWidget(
        url: message.voiceUrl!,
        isOwn: isOwn,
      );
    } else {
      content = Text(
        message.text ?? '',
        style: TextStyle(color: fg),
      );
    }

    // ✅ Seen/Delivered label (only for own messages)
    final statusText = isOwn
        ? (message.read == true ? "Seen" : "Delivered")
        : null;

    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: content,
            ),

            if (statusText != null)
              Padding(
                padding: const EdgeInsets.only(right: 14, left: 14, bottom: 2),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileShareBubble extends StatelessWidget {
  final Map<String, dynamic> payload;
  final bool isOwn;

  const _ProfileShareBubble({required this.payload, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    final uid = (payload['uid'] ?? payload['profileUid'])?.toString() ?? '';
    final username = (payload['username'] ?? '')?.toString();
    final name = (payload['name'] ?? username ?? '')?.toString();
    final avatar = payload['avatar']?.toString();

    final fg = isOwn ? Colors.white : Colors.black87;

    return GestureDetector(
      onTap: () {
        if (uid.isEmpty) return;
        final user = User(
          uid: uid,
          username: username ?? '',
          email: '',
          name: name ?? '',
          avatar: avatar,
          profileCompleted: true,
          verified: false,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserProfileScreen(user: user),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isOwn ? Colors.white.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isOwn ? Colors.white24 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            avatar != null && avatar.isNotEmpty
                ? safeAvatarNetworkImage(
                    url: ApiConfig.networkImageUrl(avatar) ?? avatar,
                    size: 44,
                    backgroundColor: isOwn ? Colors.white24 : Colors.grey.shade300,
                  )
                : CircleAvatar(
                    radius: 22,
                    backgroundColor: isOwn ? Colors.white24 : Colors.grey.shade300,
                    child: Text(
                      (name ?? '?').isNotEmpty ? ((name ?? '?')[0].toUpperCase()) : '?',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: fg),
                    ),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    username != null && username.isNotEmpty ? '@$username' : 'Profile',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: fg.withValues(alpha: 0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.person_outline, size: 20, color: fg.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}
