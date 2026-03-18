import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../config/api_config.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/message_provider.dart';
import '../../services/upload_service.dart';
import '../../services/voice_recorder_service.dart';
import '../../widgets/chat/reaction_picker.dart';
import '../profile/user_profile_screen.dart';
import 'image_preview_screen.dart';

// ── Brand tokens (dark-only, kept for reference; build methods use theme-aware locals) ──
const _kPrimary   = Color(0xFFFF8132);
const _kPrimaryLt = Color(0xFFFF9D5C);

const _kAvatarPalette = [
  [Color(0xFF0891B2), Color(0xFF06B6D4)],
  [Color(0xFF7C3AED), Color(0xFFEC4899)],
  [Color(0xFF059669), Color(0xFF10B981)],
  [Color(0xFFD97706), Color(0xFFF59E0B)],
  [Color(0xFFBE185D), Color(0xFFF43F5E)],
  [Color(0xFF1D4ED8), Color(0xFF60A5FA)],
];

List<Color> _avatarColors(String name) {
  final idx = name.isNotEmpty ? name.codeUnitAt(0) % _kAvatarPalette.length : 0;
  return _kAvatarPalette[idx];
}

// ── Screen ────────────────────────────────────────────────────────────────────
class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherName;
  final String? otherAvatar;
  final bool otherOnline;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherName,
    this.otherAvatar,
    this.otherOnline = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _uploadService = UploadService();
  final _voiceRecorder = VoiceRecorderService();

  bool _sending = false;
  bool _recording = false;

  Timer? _typingDebounce;
  bool _typingSentTrue = false;

  ChatProvider? _chatProvider;
  String? _cachedToken;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatProvider ??= context.read<ChatProvider>();
    _cachedToken ??= context.read<AuthProvider>().token;
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      final token = context.read<AuthProvider>().token;
      if (token == null) return;
      final chatProvider = context.read<ChatProvider>();
      final messageProvider = context.read<MessageProvider>();

      // Suppress push notifications while this conversation is open
      messageProvider.currentOpenConversationId = widget.conversationId;

      await chatProvider.openConversation(
        token: token,
        conversationId: widget.conversationId,
      );
      if (!mounted) return;

      // Clear any stale typing state left from previous sessions
      await chatProvider.setTyping(
        token: token,
        conversationId: widget.conversationId,
        value: false,
      );
      if (!mounted) return;

      await chatProvider.markRead(
        token: token,
        conversationId: widget.conversationId,
      );
      if (!mounted) return;

      await messageProvider.loadConversations(token: token);
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    // Re-enable push notifications for this conversation
    if (mounted) {
      context.read<MessageProvider>().currentOpenConversationId = null;
    }
    if (_chatProvider != null && _cachedToken != null && _cachedToken!.isNotEmpty) {
      _chatProvider!.disposePolling();
      _chatProvider!.setTyping(
        token: _cachedToken!,
        conversationId: widget.conversationId,
        value: false,
      );
    }
    _voiceRecorder.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onTypingChanged(String value) {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final hasText = value.trim().isNotEmpty;

    if (!hasText && _typingSentTrue) {
      _typingSentTrue = false;
      context.read<ChatProvider>().setTyping(
            token: token,
            conversationId: widget.conversationId,
            value: false,
          );
    }
    if (hasText && !_typingSentTrue) {
      _typingSentTrue = true;
      context.read<ChatProvider>().setTyping(
            token: token,
            conversationId: widget.conversationId,
            value: true,
          );
    }
    final chatProvider = context.read<ChatProvider>();
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 800), () async {
      if (!mounted) return;
      final current = _controller.text.trim().isNotEmpty;
      if (!current) {
        _typingSentTrue = false;
        await chatProvider.setTyping(
          token: token,
          conversationId: widget.conversationId,
          value: false,
        );
      }
    });
  }

  Future<void> _sendText() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final chatProvider = context.read<ChatProvider>();
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      await chatProvider.sendText(
        token: token,
        conversationId: widget.conversationId,
        receiverUid: widget.otherUserId,
        text: text,
      );
      _controller.clear();
      _typingSentTrue = false;
      await chatProvider.setTyping(
        token: token,
        conversationId: widget.conversationId,
        value: false,
      );
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickAndSendImage() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final chatProvider = context.read<ChatProvider>();
    final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;
    setState(() => _sending = true);
    try {
      final url = await _uploadService.uploadSingle(
          token: token, file: File(picked.path));
      if (!mounted) return;
      await chatProvider.sendImage(
        token: token,
        conversationId: widget.conversationId,
        receiverUid: widget.otherUserId,
        imageUrl: url,
      );
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _startVoiceRecording() async {
    if (_sending) return;
    setState(() => _recording = true);
    try {
      await _voiceRecorder.startRecording();
    } catch (e) {
      if (!mounted) return;
      setState(() => _recording = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mic error: $e')));
    }
  }

  Future<void> _stopVoiceRecordingAndSend() async {
    if (!_recording) return;
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final chatProvider = context.read<ChatProvider>();
    setState(() => _recording = false);
    try {
      final path = await _voiceRecorder.stopRecording();
      if (path == null || path.isEmpty) return;
      setState(() => _sending = true);
      final url = await _uploadService.uploadSingle(
          token: token, file: File(path));
      if (!mounted) return;
      await chatProvider.sendVoice(
        token: token,
        conversationId: widget.conversationId,
        receiverUid: widget.otherUserId,
        voiceUrl: url,
      );
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voice send failed: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final bg = isDark ? const Color(0xFF060B14) : Theme.of(context).scaffoldBackgroundColor;
    final surface = isDark ? const Color(0xFF0D1120) : cs.surfaceContainerLow;
    final bubbleIn = isDark ? const Color(0xFF111827) : cs.surfaceContainerLow;
    final border = isDark ? const Color(0xFF1E2535) : cs.outlineVariant;
    final text = isDark ? const Color(0xFFF1F5F9) : cs.onSurface;
    final muted = isDark ? const Color(0xFF64748B) : cs.onSurfaceVariant;
    final subtext = isDark ? const Color(0xFF94A3B8) : cs.onSurfaceVariant;

    final chat = context.watch<ChatProvider>();
    final myId = context.watch<AuthProvider>().user?.uid ?? '';
    final otherTyping = chat.typingMap[widget.otherUserId] == true;
    final token = context.read<AuthProvider>().token;

    return Scaffold(
      backgroundColor: bg,
      appBar: _buildAppBar(context, surface: surface, border: border, text: text, subtext: subtext),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: chat.loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: _kPrimary, strokeWidth: 2.5))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: chat.messages.length + 1, // +1 for date sep
                    itemBuilder: (context, index) {
                      // First item = date separator
                      if (index == 0) return _DateSeparator(label: 'Today');

                      final m = chat.messages[index - 1];
                      final isOwn = m.senderUid == myId;

                      return _MessageItem(
                        message: m,
                        isOwn: isOwn,
                        otherName: widget.otherName,
                        otherAvatar: widget.otherAvatar,
                        onTapImage: () {
                          if (m.imageUrl == null) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ImagePreviewScreen(uri: m.imageUrl!),
                            ),
                          );
                        },
                        onLongPress: () async {
                          if (token == null) return;
                          final reaction =
                              await ReactionPicker.show(context);
                          if (!context.mounted || reaction == null) return;
                          await context.read<ChatProvider>().react(
                                token: token,
                                conversationId: widget.conversationId,
                                messageId: m.id,
                                reaction: reaction,
                              );
                        },
                      );
                    },
                  ),
          ),

          // Typing indicator
          if (otherTyping)
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: bubbleIn,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TypingDot(delay: 0),
                      _TypingDot(delay: 150),
                      _TypingDot(delay: 300),
                    ],
                  ),
                ),
              ),
            ),

          // Input bar
          _buildInputBar(surface: surface, border: border, text: text, muted: muted, subtext: subtext),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, {
    required Color surface,
    required Color border,
    required Color text,
    required Color subtext,
  }) {
    final colors = _avatarColors(widget.otherName);
    final initial = widget.otherName.isNotEmpty
        ? widget.otherName[0].toUpperCase()
        : '?';
    final avatarUrl = widget.otherAvatar != null
        ? ApiConfig.networkImageUrl(widget.otherAvatar!)
        : null;

    return AppBar(
      backgroundColor: surface,
      elevation: 0,
      leadingWidth: 48,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: subtext, size: 20),
      ),
      titleSpacing: 0,
      title: GestureDetector(
        onTap: () {
          final user = User(
            uid: widget.otherUserId,
            username: '',
            email: '',
            name: widget.otherName,
            avatar: widget.otherAvatar,
            profileCompleted: true,
            verified: false,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => UserProfileScreen(user: user)),
          );
        },
        child: Row(
          children: [
            // Avatar
            avatarUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: avatarUrl,
                      width: 38,
                      height: 38,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _avatarCircle(
                          initial: initial, colors: colors, size: 38),
                      placeholder: (_, __) => _avatarCircle(
                          initial: initial, colors: colors, size: 38),
                    ),
                  )
                : _avatarCircle(initial: initial, colors: colors, size: 38),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherName,
                  style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Online',
                      style: TextStyle(
                        color: Color(0xFF22C55E),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.phone_outlined, color: subtext, size: 22),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.videocam_outlined, color: subtext, size: 24),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: border),
      ),
    );
  }

  Widget _buildInputBar({
    required Color surface,
    required Color border,
    required Color text,
    required Color muted,
    required Color subtext,
  }) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: surface,
          border: Border(top: BorderSide(color: border, width: 1)),
        ),
        child: Row(
          children: [
            // "+" button
            GestureDetector(
              onTap: _sending ? null : _pickAndSendImage,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: border, width: 1.5),
                ),
                child: Icon(Icons.add, color: subtext, size: 20),
              ),
            ),
            const SizedBox(width: 8),

            // Text field
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: border),
                ),
                child: TextField(
                  controller: _controller,
                  enabled: !_sending && !_recording,
                  onChanged: _onTypingChanged,
                  onSubmitted: (_) => _sendText(),
                  style: TextStyle(color: text, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: _recording ? 'Recording...' : 'Type a message...',
                    hintStyle: TextStyle(color: muted, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Mic (hold to record)
            GestureDetector(
              onLongPressStart: (_) => _startVoiceRecording(),
              onLongPressEnd: (_) => _stopVoiceRecordingAndSend(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _recording
                      ? _kPrimary
                      : Colors.transparent,
                  border: Border.all(color: border, width: 1.5),
                ),
                child: Icon(
                  _recording ? Icons.mic : Icons.mic_none_rounded,
                  color: _recording ? Colors.white : subtext,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Send button
            GestureDetector(
              onTap: _sending ? null : _sendText,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_kPrimaryLt, _kPrimary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40FF8132),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: _sending
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Avatar circle helper ───────────────────────────────────────────────────────
Widget _avatarCircle({
  required String initial,
  required List<Color> colors,
  required double size,
}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    alignment: Alignment.center,
    child: Text(
      initial,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: size * 0.36,
        height: 1,
      ),
    ),
  );
}

// ── Date separator ────────────────────────────────────────────────────────────
class _DateSeparator extends StatelessWidget {
  final String label;
  const _DateSeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final surface = isDark ? const Color(0xFF0D1120) : cs.surfaceContainerLow;
    final border = isDark ? const Color(0xFF1E2535) : cs.outlineVariant;
    final subtext = isDark ? const Color(0xFF94A3B8) : cs.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(child: Divider(color: border, thickness: 0.5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border, width: 0.8),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: subtext,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(child: Divider(color: border, thickness: 0.5)),
        ],
      ),
    );
  }
}

// ── Message item ──────────────────────────────────────────────────────────────
class _MessageItem extends StatelessWidget {
  final MessageModel message;
  final bool isOwn;
  final String otherName;
  final String? otherAvatar;
  final VoidCallback onTapImage;
  final VoidCallback onLongPress;

  const _MessageItem({
    required this.message,
    required this.isOwn,
    required this.otherName,
    required this.otherAvatar,
    required this.onTapImage,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final muted = isDark ? const Color(0xFF64748B) : cs.onSurfaceVariant;

    final colors = _avatarColors(otherName);
    final initial =
        otherName.isNotEmpty ? otherName[0].toUpperCase() : '?';
    final avatarUrl = otherAvatar != null
        ? ApiConfig.networkImageUrl(otherAvatar!)
        : null;

    // Format time — convert to IST (device local time), 12-hour format
    final ist = message.createdAt.toLocal();
    final h12 = ist.hour == 0 ? 12 : (ist.hour > 12 ? ist.hour - 12 : ist.hour);
    final ampm = ist.hour < 12 ? 'AM' : 'PM';
    final time = '${h12.toString().padLeft(2, '0')}:${ist.minute.toString().padLeft(2, '0')} $ampm';

    Widget bubble;
    if (message.isImage && message.imageUrl != null) {
      bubble = _ImageBubble(
          url: message.imageUrl!, isOwn: isOwn, onTap: onTapImage);
    } else if (message.isVoice && message.voiceUrl != null) {
      bubble = _VoiceBubble(url: message.voiceUrl!, isOwn: isOwn);
    } else if (message.isProfile && message.profilePayload != null) {
      bubble = _ProfileBubble(
          payload: message.profilePayload!, isOwn: isOwn);
    } else {
      bubble = _TextBubble(text: message.text ?? '', isOwn: isOwn);
    }

    if (isOwn) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  bubble,
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 4, top: 2),
                child: Text(
                  time,
                  style: TextStyle(color: muted, fontSize: 11),
                ),
              ),
              if (message.reactions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8, top: 2),
                  child: Wrap(
                    spacing: 4,
                    children: message.reactions.values
                        .map((r) =>
                            Text(r, style: const TextStyle(fontSize: 14)))
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Other user avatar
            avatarUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: avatarUrl,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _avatarCircle(
                          initial: initial, colors: colors, size: 32),
                      placeholder: (_, __) => _avatarCircle(
                          initial: initial, colors: colors, size: 32),
                    ),
                  )
                : _avatarCircle(
                    initial: initial, colors: colors, size: 32),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bubble,
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 2),
                    child: Text(
                      time,
                      style: TextStyle(
                          color: muted, fontSize: 11),
                    ),
                  ),
                  if (message.reactions.isNotEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 4, top: 2),
                      child: Wrap(
                        spacing: 4,
                        children: message.reactions.values
                            .map((r) => Text(r,
                                style:
                                    const TextStyle(fontSize: 14)))
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Text bubble ───────────────────────────────────────────────────────────────
class _TextBubble extends StatelessWidget {
  final String text;
  final bool isOwn;
  const _TextBubble({required this.text, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final bubbleIn = isDark ? const Color(0xFF111827) : cs.surfaceContainerLow;

    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: isOwn
            ? const LinearGradient(
                colors: [_kPrimaryLt, _kPrimary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isOwn ? null : bubbleIn,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isOwn ? 18 : 4),
          bottomRight: Radius.circular(isOwn ? 4 : 18),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isOwn ? Colors.white : Theme.of(context).colorScheme.onSurface,
          fontSize: 14,
          height: 1.45,
        ),
      ),
    );
  }
}

// ── Image bubble ──────────────────────────────────────────────────────────────
class _ImageBubble extends StatelessWidget {
  final String url;
  final bool isOwn;
  final VoidCallback onTap;
  const _ImageBubble(
      {required this.url, required this.isOwn, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final bubbleIn = isDark ? const Color(0xFF111827) : cs.surfaceContainerLow;
    final muted = isDark ? const Color(0xFF64748B) : cs.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CachedNetworkImage(
          imageUrl: url,
          width: 200,
          height: 180,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            width: 200,
            height: 180,
            color: bubbleIn,
            child: const Center(
              child: CircularProgressIndicator(
                  color: _kPrimary, strokeWidth: 2),
            ),
          ),
          errorWidget: (_, __, ___) => Container(
            width: 200,
            height: 180,
            color: bubbleIn,
            child: Icon(Icons.broken_image,
                color: muted, size: 40),
          ),
        ),
      ),
    );
  }
}

// ── Voice bubble ──────────────────────────────────────────────────────────────
class _VoiceBubble extends StatelessWidget {
  final String url;
  final bool isOwn;
  const _VoiceBubble({required this.url, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final bubbleIn = isDark ? const Color(0xFF111827) : cs.surfaceContainerLow;
    final border = isDark ? const Color(0xFF1E2535) : cs.outlineVariant;
    final subtext = isDark ? const Color(0xFF94A3B8) : cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isOwn ? _kPrimary.withOpacity(0.85) : bubbleIn,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isOwn ? Colors.white.withOpacity(0.2) : border,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              color: isOwn ? Colors.white : subtext,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          // Frequency waveform
          SizedBox(
            width: 90,
            height: 28,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(18, (i) {
                const waveHeights = [
                  0.30, 0.55, 0.75, 0.95, 0.65, 0.85, 0.50,
                  0.70, 1.00, 0.80, 0.60, 0.90, 0.50, 0.75,
                  0.40, 0.80, 0.55, 0.30,
                ];
                final h = waveHeights[i] * 24;
                final played = i < 7;
                return Container(
                  width: 3,
                  height: h,
                  decoration: BoxDecoration(
                    color: played
                        ? (isOwn ? Colors.white : _kPrimary)
                        : (isOwn ? Colors.white.withOpacity(0.35) : border),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '0:08',
            style: TextStyle(
              color: isOwn
                  ? Colors.white.withOpacity(0.9)
                  : subtext,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile share bubble ──────────────────────────────────────────────────────
class _ProfileBubble extends StatelessWidget {
  final Map<String, dynamic> payload;
  final bool isOwn;
  const _ProfileBubble({required this.payload, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final bubbleIn = isDark ? const Color(0xFF111827) : cs.surfaceContainerLow;

    final name =
        payload['name']?.toString() ?? payload['username']?.toString() ?? '?';
    final username = payload['username']?.toString();
    final uid = payload['uid']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        if (uid.isEmpty) return;
        final user = User(
          uid: uid,
          username: username ?? '',
          email: '',
          name: name,
          avatar: payload['avatar']?.toString(),
          profileCompleted: true,
          verified: false,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => UserProfileScreen(user: user)),
        );
      },
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isOwn ? _kPrimary.withOpacity(0.85) : bubbleIn,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                username != null ? '@$username' : name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Typing dots animation ─────────────────────────────────────────────────────
class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final subtext = isDark ? const Color(0xFF94A3B8) : cs.onSurfaceVariant;

    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 7,
        height: 7,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: subtext,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
