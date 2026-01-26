import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/message_model.dart';
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
          ),
        ),
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
