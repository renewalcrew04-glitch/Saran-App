import 'dart:async';
import 'dart:io';
import '../../providers/message_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/upload_service.dart';
import '../../services/voice_recorder_service.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/reaction_picker.dart';
import 'image_preview_screen.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherName;
  final String? otherAvatar;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherName,
    this.otherAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final UploadService _uploadService = UploadService();
  final VoiceRecorderService _voiceRecorder = VoiceRecorderService();

  bool _sending = false;

  // 🎤 voice
  bool _recording = false;

  // typing debounce
  Timer? _typingDebounce;
  bool _typingSentTrue = false;

  @override
void initState() {
  super.initState();

  Future.microtask(() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;

    // open + start polling messages
    await context.read<ChatProvider>().openConversation(
          token: token,
          conversationId: widget.conversationId,
        );

    // ✅ mark read (reset unreadCount in backend)
    await context.read<ChatProvider>().markRead(
          token: token,
          conversationId: widget.conversationId,
        );

    // ✅ refresh conversation list so badge disappears immediately
    await context.read<MessageProvider>().loadConversations(token: token);
  });
}

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _controller.dispose();

    // stop polling
    context.read<ChatProvider>().disposePolling();

    // clear typing when leaving
    _clearTypingOnExit();

    _voiceRecorder.dispose();
    super.dispose();
  }

  Future<void> _clearTypingOnExit() async {
    try {
      final auth = context.read<AuthProvider>();
      final token = auth.token;
      if (token == null) return;

      await context.read<ChatProvider>().setTyping(
            token: token,
            conversationId: widget.conversationId,
            value: false,
          );
    } catch (_) {
      // ignore
    }
  }

  // ✅ typing handler
  void _onTypingChanged(String value) {
  final auth = context.read<AuthProvider>();
  final token = auth.token;
  if (token == null) return;

  final hasText = value.trim().isNotEmpty;

  // ✅ if user cleared text, stop typing immediately
  if (!hasText && _typingSentTrue) {
    _typingSentTrue = false;
    context.read<ChatProvider>().setTyping(
          token: token,
          conversationId: widget.conversationId,
          value: false,
        );
  }

  // send typing:true instantly once
  if (hasText && !_typingSentTrue) {
    _typingSentTrue = true;
    context.read<ChatProvider>().setTyping(
          token: token,
          conversationId: widget.conversationId,
          value: true,
        );
  }

  // debounce typing:false after user stops
  _typingDebounce?.cancel();
  _typingDebounce = Timer(const Duration(milliseconds: 800), () async {
    if (!mounted) return;

    final current = _controller.text.trim().isNotEmpty;
    if (!current) {
      _typingSentTrue = false;
      await context.read<ChatProvider>().setTyping(
            token: token,
            conversationId: widget.conversationId,
            value: false,
          );
    }
  });
}

  Future<void> _sendText() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      await context.read<ChatProvider>().sendText(
            token: token,
            conversationId: widget.conversationId,
            receiverUid: widget.otherUserId,
            text: text,
          );

      _controller.clear();

      // ✅ stop typing after send
      _typingSentTrue = false;
      await context.read<ChatProvider>().setTyping(
            token: token,
            conversationId: widget.conversationId,
            value: false,
          );
    } finally {
      setState(() => _sending = false);
    }
  }

  Future<void> _pickAndSendImage() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null) return;

    setState(() => _sending = true);
    try {
      final url = await _uploadService.uploadSingle(
        token: token,
        file: File(picked.path),
      );

      await context.read<ChatProvider>().sendImage(
            token: token,
            conversationId: widget.conversationId,
            receiverUid: widget.otherUserId,
            imageUrl: url,
          );
    } finally {
      setState(() => _sending = false);
    }
  }

  // 🎤 hold start
  Future<void> _startVoiceRecording() async {
    if (_sending) return;

    setState(() => _recording = true);

    try {
      await _voiceRecorder.startRecording();
    } catch (e) {
      setState(() => _recording = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Mic error: $e")),
      );
    }
  }

  // 🎤 hold end
  Future<void> _stopVoiceRecordingAndSend() async {
    if (!_recording) return;

    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;

    setState(() => _recording = false);

    try {
      final recordedPath = await _voiceRecorder.stopRecording();
      if (recordedPath == null || recordedPath.isEmpty) return;

      setState(() => _sending = true);

      final voiceUrl = await _uploadService.uploadSingle(
        token: token,
        file: File(recordedPath),
      );

      await context.read<ChatProvider>().sendVoice(
            token: token,
            conversationId: widget.conversationId,
            receiverUid: widget.otherUserId,
            voiceUrl: voiceUrl,
          );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Voice send failed: $e")),
      );
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final auth = context.watch<AuthProvider>();
    final myId = auth.user?.uid ?? '';

    // ✅ show typing from other user
    final otherTyping = chat.typingMap[widget.otherUserId] == true;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.black12,
              backgroundImage: (widget.otherAvatar != null && widget.otherAvatar!.isNotEmpty)
                  ? NetworkImage(widget.otherAvatar!)
                  : null,
              child: (widget.otherAvatar == null || widget.otherAvatar!.isEmpty)
                  ? const Icon(Icons.person, color: Colors.black)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.otherName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ✅ Typing indicator
          if (otherTyping)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Typing…",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),

          Expanded(
            child: chat.loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    itemCount: chat.messages.length,
                    itemBuilder: (context, index) {
                      final m = chat.messages[index];
                      final isOwn = m.senderUid == myId;

                      return Column(
                        crossAxisAlignment:
                            isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          MessageBubble(
                            message: m,
                            isOwn: isOwn,
                            onTapImage: () {
                              if (m.imageUrl == null) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ImagePreviewScreen(uri: m.imageUrl!),
                                ),
                              );
                            },
                            onLongPress: () async {
                              final token = auth.token;
                              if (token == null) return;

                              final reaction = await ReactionPicker.show(context);
                              if (reaction == null) return;

                              await context.read<ChatProvider>().react(
                                    token: token,
                                    conversationId: widget.conversationId,
                                    messageId: m.id,
                                    reaction: reaction,
                                  );
                            },
                          ),
                          if (m.reactions.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 16, left: 16, bottom: 6),
                              child: Wrap(
                                spacing: 6,
                                children: m.reactions.values
                                    .map((r) => Text(r, style: const TextStyle(fontSize: 14)))
                                    .toList(),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
          ),

          // INPUT BAR
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFDDDDDD), width: 0.5)),
              ),
              child: Row(
                children: [
                  // 🎤 hold to record
                  GestureDetector(
                    onLongPressStart: (_) => _startVoiceRecording(),
                    onLongPressEnd: (_) => _stopVoiceRecordingAndSend(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _recording ? Colors.black : const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        _recording ? Icons.mic : Icons.mic_none,
                        color: _recording ? Colors.white : Colors.black,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  IconButton(
                    onPressed: _sending ? null : _pickAndSendImage,
                    icon: const Icon(Icons.add, color: Colors.black),
                  ),

                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_sending,
                      onChanged: _onTypingChanged, // ✅ typing call
                      decoration: InputDecoration(
                        hintText: _recording ? "Recording..." : "Type a message…",
                        filled: true,
                        fillColor: const Color(0xFFF2F2F2),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  IconButton(
                    onPressed: _sending ? null : _sendText,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
