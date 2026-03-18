import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dm_provider.dart';
import '../../providers/dm_search_provider.dart';
import '../../providers/message_provider.dart';
import '../../models/conversation_model.dart';
import '../../models/dm_user_model.dart';
import '../../models/user_lite_model.dart';
import '../../models/user_model.dart';
import '../../services/message_service.dart';
import '../profile/user_profile_screen.dart';
import 'chat_screen.dart';
import 'new_message_screen.dart';

// ── Brand tokens (kept for reference; runtime values are resolved per-theme) ──
const _kPrimary   = Color(0xFFFF8132);
const _kPrimaryLt = Color(0xFFFF9D5C);

const _kAvatarPalette = [
  [Color(0xFF0891B2), Color(0xFF06B6D4)], // cyan
  [Color(0xFF7C3AED), Color(0xFFEC4899)], // purple-pink
  [Color(0xFF059669), Color(0xFF10B981)], // green
  [Color(0xFFD97706), Color(0xFFF59E0B)], // amber
  [Color(0xFFBE185D), Color(0xFFF43F5E)], // pink
  [Color(0xFF1D4ED8), Color(0xFF60A5FA)], // blue
];

List<Color> _avatarColors(String name) {
  final idx = name.isNotEmpty ? name.codeUnitAt(0) % _kAvatarPalette.length : 0;
  return _kAvatarPalette[idx];
}

String _formatTime(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);
  if (diff.inDays > 0) return '${diff.inDays}d';
  if (diff.inHours > 0) return '${diff.inHours}h';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m';
  return 'now';
}

// ── Screen ────────────────────────────────────────────────────────────────────
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MessageService _service = MessageService();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      final token = context.read<AuthProvider>().token;
      if (token == null) return;
      await context.read<MessageProvider>().loadConversations(token: token);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    await context.read<MessageProvider>().loadConversations(token: token);
  }

  // ── Conversation actions ───────────────────────────────────────────────────
  Future<void> _togglePin(ConversationModel c) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    await _service.updateFlags(
      token: token,
      conversationId: c.id,
      pinned: !c.isPinned,
    );
    await _refresh();
  }

  Future<void> _toggleArchive(ConversationModel c) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    await _service.updateFlags(
      token: token,
      conversationId: c.id,
      archived: !c.isArchived,
    );
    await _refresh();
  }

  Future<void> _toggleMute(ConversationModel c) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    await _service.updateFlags(
      token: token,
      conversationId: c.id,
      muted: !c.isMuted,
    );
    await _refresh();
  }

  Future<void> _deleteConversation(ConversationModel c) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    await _service.deleteConversation(token: token, conversationId: c.id);
    await _refresh();
  }

  Future<void> _confirmDelete(ConversationModel c) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final surface = isDark ? const Color(0xFF0D1120) : cs.surfaceContainerLow;
    final text = isDark ? const Color(0xFFF1F5F9) : cs.onSurface;
    final subtext = isDark ? const Color(0xFF94A3B8) : cs.onSurfaceVariant;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: surface,
        title: Text('Delete chat?', style: TextStyle(color: text)),
        content: Text(
          'This will permanently delete this conversation.',
          style: TextStyle(color: subtext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: subtext)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (ok == true) await _deleteConversation(c);
  }

  void _openChat(ConversationModel c) {
    final other = c.otherUser;
    if (other == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: c.id,
          otherUserId: other.id,
          otherName: other.name,
          otherAvatar: other.avatar,
          otherOnline: other.online,
        ),
      ),
    );
  }

  Future<void> _openDmWithUser(DmUserModel user) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final convoId = await context.read<DmProvider>().openDm(
          token: token,
          otherUid: user.uid,
        );
    if (!mounted) return;
    if (convoId == null || convoId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open chat')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: convoId,
          otherUserId: user.uid,
          otherName: user.name,
          otherAvatar: user.avatar,
        ),
      ),
    );
  }

  void _openProfile(UserLiteModel? other) {
    if (other == null) return;
    final user = User(
      uid: other.id,
      username: other.username ?? '',
      email: '',
      name: other.name,
      avatar: other.avatar,
      profileCompleted: true,
      verified: false,
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserProfileScreen(user: user)),
    );
  }

  void _showMenu(ConversationModel c) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final surface = isDark ? const Color(0xFF0D1120) : cs.surfaceContainerLow;
    final border = isDark ? const Color(0xFF1E2535) : cs.outlineVariant;
    final text = isDark ? const Color(0xFFF1F5F9) : cs.onSurface;
    final subtext = isDark ? const Color(0xFF94A3B8) : cs.onSurfaceVariant;

    showModalBottomSheet(
      context: context,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 8),
            _sheetTile(
              c.isPinned ? 'Unpin' : 'Pin',
              Icons.push_pin_outlined,
              () async { Navigator.pop(context); await _togglePin(c); },
              textColor: text,
              iconColor: subtext,
            ),
            _sheetTile(
              c.isMuted ? 'Unmute' : 'Mute',
              Icons.volume_off_outlined,
              () async { Navigator.pop(context); await _toggleMute(c); },
              textColor: text,
              iconColor: subtext,
            ),
            _sheetTile(
              c.isArchived ? 'Unarchive' : 'Archive',
              Icons.archive_outlined,
              () async { Navigator.pop(context); await _toggleArchive(c); },
              textColor: text,
              iconColor: subtext,
            ),
            _sheetTile(
              'Delete chat',
              Icons.delete_outline,
              () async { Navigator.pop(context); await _confirmDelete(c); },
              textColor: text,
              iconColor: subtext,
              danger: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetTile(
    String label,
    IconData icon,
    VoidCallback onTap, {
    required Color textColor,
    required Color iconColor,
    bool danger = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: danger ? Colors.red : iconColor, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: danger ? Colors.red : textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final bg = isDark ? const Color(0xFF060B14) : Theme.of(context).scaffoldBackgroundColor;
    final surface = isDark ? const Color(0xFF0D1120) : cs.surfaceContainerLow;
    final border = isDark ? const Color(0xFF1E2535) : cs.outlineVariant;
    final text = isDark ? const Color(0xFFF1F5F9) : cs.onSurface;
    final muted = isDark ? const Color(0xFF64748B) : cs.onSurfaceVariant;
    final subtext = isDark ? const Color(0xFF94A3B8) : cs.onSurfaceVariant;
    final primary = const Color(0xFFFF8132);

    final provider = context.watch<MessageProvider>();
    final dmSearch = context.watch<DmSearchProvider>();
    final conversations = provider.visibleConversations;
    final hasSearch = provider.search.trim().isNotEmpty;

    // "Active Now" = only users who are currently online
    final activeDisplay = conversations
        .where((c) => !c.isArchived && c.otherUser?.online == true)
        .toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        automaticallyImplyLeading: false,
        leadingWidth: 48,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.chevron_left_rounded, color: subtext, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        title: Text(
          'Messages',
          style: TextStyle(
            color: text,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NewMessageScreen()),
              ),
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
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: border),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Search bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: border),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: text, fontSize: 14),
                  onChanged: (v) {
                    provider.setSearch(v);
                    final token = context.read<AuthProvider>().token;
                    if (token != null) {
                      if (v.trim().isEmpty) {
                        context.read<DmSearchProvider>().clear();
                      } else {
                        context
                            .read<DmSearchProvider>()
                            .search(token: token, query: v);
                      }
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Search messages...',
                    hintStyle: TextStyle(color: muted, fontSize: 14),
                    prefixIcon:
                        Icon(Icons.search_rounded, color: muted, size: 20),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
              ),
            ),

            // ── Body ──────────────────────────────────────────────────────
            Expanded(
              child: provider.loading && !hasSearch
                  ? Center(
                      child: CircularProgressIndicator(
                          color: primary, strokeWidth: 2.5))
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      color: primary,
                      backgroundColor: surface,
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          // User search results
                          if (hasSearch && (dmSearch.results.isNotEmpty || dmSearch.loading)) ...[
                            _sectionLabel(context, 'START CHAT WITH', muted),
                            if (dmSearch.loading)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        color: primary, strokeWidth: 2),
                                  ),
                                ),
                              )
                            else
                              ...dmSearch.results
                                  .map((u) => _userSearchTile(context, u, text, muted)),
                            const SizedBox(height: 8),
                          ],

                          // Active Now
                          if (!hasSearch && activeDisplay.isNotEmpty) ...[
                            _sectionLabel(context, 'ACTIVE NOW', muted),
                            _ActiveNowRow(
                              conversations: activeDisplay,
                              onTap: _openChat,
                            ),
                            const SizedBox(height: 8),
                          ],

                          // Conversations
                          if (!hasSearch && provider.pinnedConversations.isNotEmpty) ...[
                            _sectionLabel(context, 'PINNED', muted),
                            ...provider.pinnedConversations
                                .map((c) => _convTile(context, c, bg, text, muted, subtext)),
                          ],
                          if (!hasSearch && provider.normalConversations.isNotEmpty)
                            ...provider.normalConversations
                                .map((c) => _convTile(context, c, bg, text, muted, subtext)),
                          if (hasSearch && provider.visibleConversations.isNotEmpty)
                            ...provider.visibleConversations
                                .map((c) => _convTile(context, c, bg, text, muted, subtext)),

                          // Empty state
                          if (conversations.isEmpty && !provider.loading && !hasSearch)
                            _buildEmpty(text, muted),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label, Color muted) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Text(
        label,
        style: TextStyle(
          color: muted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.3,
        ),
      ),
    );
  }

  Widget _userSearchTile(
    BuildContext context,
    DmUserModel u,
    Color text,
    Color muted,
  ) {
    final colors = _avatarColors(u.name);
    final avatarUrl =
        u.avatar != null ? ApiConfig.networkImageUrl(u.avatar!) : null;
    return InkWell(
      onTap: () => _openDmWithUser(u),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            _buildAvatar(
                name: u.name, avatarUrl: avatarUrl, colors: colors, size: 46),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u.name,
                      style: TextStyle(
                          color: text,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  if (u.username.isNotEmpty)
                    Text('@${u.username}',
                        style: TextStyle(color: muted, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chat_bubble_outline_rounded, color: muted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _convTile(
    BuildContext context,
    ConversationModel c,
    Color bg,
    Color text,
    Color muted,
    Color subtext,
  ) {
    final other = c.otherUser;
    final name = other?.name ?? 'User';
    final colors = _avatarColors(name);
    final avatarUrl =
        other?.avatar != null ? ApiConfig.networkImageUrl(other!.avatar!) : null;
    final online = other?.online == true;

    return Dismissible(
      key: ValueKey(c.id),
      background: _SwipeBg(label: c.isPinned ? 'Unpin' : 'Pin', alignLeft: true),
      secondaryBackground:
          _SwipeBg(label: c.isArchived ? 'Unarchive' : 'Archive', alignLeft: false),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          await _togglePin(c);
        } else {
          await _toggleArchive(c);
        }
        return false;
      },
      child: GestureDetector(
        onTap: () => _openChat(c),
        onLongPress: () => _showMenu(c),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              // Avatar
              GestureDetector(
                onTap: () => _openProfile(other),
                child: Stack(
                  children: [
                    _buildAvatar(
                        name: name,
                        avatarUrl: avatarUrl,
                        colors: colors,
                        size: 52,
                        badgeCount: c.unreadCount),
                    if (online)
                      Positioned(
                        bottom: 1,
                        right: 1,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                            border: Border.all(color: bg, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (c.isPinned)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(Icons.push_pin,
                                size: 13, color: muted),
                          ),
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              color: text,
                              fontWeight: c.unreadCount > 0
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatTime(c.lastMessageAt),
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      c.lastMessage.isNotEmpty ? c.lastMessage : '📷 Photo',
                      style: TextStyle(
                        color: c.unreadCount > 0 ? subtext : muted,
                        fontSize: 13,
                        fontWeight: c.unreadCount > 0
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(Color text, Color muted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
      child: Column(
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 52, color: muted),
          const SizedBox(height: 14),
          Text(
            'No messages yet',
            style: TextStyle(
                color: text, fontWeight: FontWeight.w800, fontSize: 17),
          ),
          const SizedBox(height: 6),
          Text(
            'Start a conversation by tapping the + button',
            style: TextStyle(color: muted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Avatar builder ─────────────────────────────────────────────────────────────
Widget _buildAvatar({
  required String name,
  required String? avatarUrl,
  required List<Color> colors,
  required double size,
  int badgeCount = 0,
  Color? bgColor,
}) {
  final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
  Widget avatar;
  if (avatarUrl != null) {
    avatar = ClipOval(
      child: CachedNetworkImage(
        imageUrl: avatarUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _initialCircle(
            initial: initial, colors: colors, size: size),
        placeholder: (_, __) =>
            _initialCircle(initial: initial, colors: colors, size: size),
      ),
    );
  } else {
    avatar = _initialCircle(initial: initial, colors: colors, size: size);
  }

  if (badgeCount <= 0) return SizedBox(width: size, height: size, child: avatar);

  return Stack(
    children: [
      SizedBox(width: size, height: size, child: avatar),
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: _kPrimary,
            shape: BoxShape.circle,
            border: Border.all(
              color: bgColor ?? const Color(0xFF060B14),
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$badgeCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
      ),
    ],
  );
}

Widget _initialCircle({
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
        fontSize: size * 0.34,
        height: 1,
      ),
    ),
  );
}

// ── Active Now row ─────────────────────────────────────────────────────────────
class _ActiveNowRow extends StatelessWidget {
  final List<ConversationModel> conversations;
  final void Function(ConversationModel) onTap;

  const _ActiveNowRow({required this.conversations, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final bg = isDark ? const Color(0xFF060B14) : Theme.of(context).scaffoldBackgroundColor;
    final subtext = isDark ? const Color(0xFF94A3B8) : cs.onSurfaceVariant;

    return SizedBox(
      height: 86,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: conversations.length,
        itemBuilder: (_, i) {
          final c = conversations[i];
          final name = c.otherUser?.name ?? 'User';
          final avatarUrl = c.otherUser?.avatar != null
              ? ApiConfig.networkImageUrl(c.otherUser!.avatar!)
              : null;
          final colors = _avatarColors(name);
          final firstName = name.split(' ').first;

          return GestureDetector(
            onTap: () => onTap(c),
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      _buildAvatar(
                          name: name,
                          avatarUrl: avatarUrl,
                          colors: colors,
                          size: 54),
                      Positioned(
                        bottom: 1,
                        right: 1,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                            border: Border.all(color: bg, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    firstName,
                    style: TextStyle(
                      color: subtext,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Swipe background ──────────────────────────────────────────────────────────
class _SwipeBg extends StatelessWidget {
  final String label;
  final bool alignLeft;

  const _SwipeBg({required this.label, required this.alignLeft});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: alignLeft
          ? const Color(0xFF1E3A5F)
          : const Color(0xFF2D1B1B),
      child: Text(
        label,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
