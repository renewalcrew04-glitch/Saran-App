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
      final auth = context.read<AuthProvider>();
      final token = auth.token;
      if (token == null) return;
      final messageProvider = context.read<MessageProvider>();
      await messageProvider.loadConversations(token: token);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) return '${difference.inDays}d';
    if (difference.inHours > 0) return '${difference.inHours}h';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m';
    return 'now';
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;

    await context.read<MessageProvider>().loadConversations(token: token);
  }

  Future<void> _togglePin(ConversationModel c) async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;

    await _service.updateFlags(
      token: token,
      conversationId: c.id,
      pinned: !(c.isPinned == true),
    );

    await _refresh();
  }

  Future<void> _toggleArchive(ConversationModel c) async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;

    await _service.updateFlags(
      token: token,
      conversationId: c.id,
      archived: !(c.isArchived == true),
    );

    await _refresh();
  }

  Future<void> _toggleMute(ConversationModel c) async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;

    await _service.updateFlags(
      token: token,
      conversationId: c.id,
      muted: !(c.isMuted == true),
    );

    await _refresh();
  }

  Future<void> _deleteConversation(ConversationModel c) async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;

    await _service.deleteConversation(
      token: token,
      conversationId: c.id,
    );

    await _refresh();
  }

  Future<void> _confirmDelete(ConversationModel c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete chat?"),
        content: const Text("This will permanently delete this conversation."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              "Delete",
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _deleteConversation(c);
    }
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
        ),
      ),
    );
  }

  Future<void> _openDmWithUser(DmUserModel user) async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;

    final convoId = await context.read<DmProvider>().openDm(
          token: token,
          otherUid: user.uid,
        );

    if (!mounted) return;
    if (convoId == null || convoId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to open chat")),
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

  Widget _userSearchTile(DmUserModel u) {
    final scheme = Theme.of(context).colorScheme;
    final avatarUrl = u.avatar != null ? ApiConfig.networkImageUrl(u.avatar!) : null;
    return InkWell(
      onTap: () => _openDmWithUser(u),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: scheme.surfaceContainerHighest,
              backgroundImage: avatarUrl != null
                  ? CachedNetworkImageProvider(avatarUrl)
                  : null,
              child: avatarUrl == null
                  ? Text(
                      u.name.isNotEmpty ? u.name[0].toUpperCase() : "U",
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    u.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: scheme.onSurface,
                    ),
                  ),
                  if (u.username.isNotEmpty)
                    Text(
                      "@${u.username}",
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chat_bubble_outline, size: 20, color: scheme.onSurfaceVariant),
          ],
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
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(user: user),
      ),
    );
  }

  Widget _tile(ConversationModel c) {
    final scheme = Theme.of(context).colorScheme;
    final other = c.otherUser;

    final name = other?.name ?? "User"; // ignore: dead_null_aware_expression
    final avatar = other?.avatar;
    final avatarUrl = avatar != null ? ApiConfig.networkImageUrl(avatar) : null;
    final online = other?.online == true;

    return Dismissible(
      key: ValueKey(c.id),
      background: _SwipeActionBg(
        label: c.isPinned == true ? "Unpin" : "Pin",
        color: scheme.primary,
        alignLeft: true,
      ),
      secondaryBackground: _SwipeActionBg(
        label: c.isArchived == true ? "Unarchive" : "Archive",
        color: scheme.primary,
        alignLeft: false,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await _togglePin(c);
          return false;
        } else {
          await _toggleArchive(c);
          return false;
        }
      },
      child: InkWell(
        onTap: () => _openChat(c),
        onLongPress: () => _showMenu(c),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _openProfile(other),
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.outlineVariant, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: scheme.surfaceContainerHighest,
                        backgroundImage: avatarUrl != null
                            ? CachedNetworkImageProvider(avatarUrl)
                            : null,
                        child: avatarUrl == null
                            ? Text(
                                name[0].toUpperCase(),
                                style: TextStyle(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              )
                            : null,
                      ),
                    ),
                    if (online)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: scheme.surface, width: 2.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              if (c.isPinned == true)
                                const Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Icon(Icons.push_pin, size: 16),
                                ),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatTime(c.lastMessageAt),
                          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.lastMessage.isNotEmpty ? c.lastMessage : "Photo",
                            style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (c.unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade600, Colors.purple.shade600],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${c.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
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

  void _showMenu(ConversationModel c) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              ListTile(
                title: Text(c.isPinned == true ? "Unpin" : "Pin"),
                onTap: () async {
                  Navigator.pop(context);
                  await _togglePin(c);
                },
              ),
              ListTile(
                title: Text(c.isMuted == true ? "Unmute" : "Mute"),
                onTap: () async {
                  Navigator.pop(context);
                  await _toggleMute(c);
                },
              ),
              ListTile(
                title: Text(c.isArchived == true ? "Unarchive" : "Archive"),
                onTap: () async {
                  Navigator.pop(context);
                  await _toggleArchive(c);
                },
              ),
              ListTile(
                title: Text(
                  "Delete chat",
                  style: TextStyle(color: scheme.error),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _confirmDelete(c);
                },
              ),
              ListTile(
                title: const Text("Cancel"),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MessageProvider>();
    final scheme = Theme.of(context).colorScheme;
    final pinned = provider.pinnedConversations;
    final normal = provider.normalConversations;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 0.5, color: scheme.outlineVariant),
        ),
        title: Text(
          'Messages',
          style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: scheme.onSurface),
            onPressed: _refresh,
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: scheme.onSurface),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NewMessageScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // tabs: Inbox / Archived
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    label: "Inbox",
                    selected: provider.showArchived == false,
                    onTap: () => provider.setShowArchived(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TabButton(
                    label: "Archived",
                    selected: provider.showArchived == true,
                    onTap: () => provider.setShowArchived(true),
                  ),
                ),
              ],
            ),
          ),

          // search (filters conversations + searches users to start new chat)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) {
                  provider.setSearch(v);
                  final auth = context.read<AuthProvider>();
                  final token = auth.token;
                  if (token != null) {
                    if (v.trim().isEmpty) {
                      context.read<DmSearchProvider>().clear();
                    } else {
                      context.read<DmSearchProvider>().search(token: token, query: v);
                    }
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Search messages or users',
                  hintStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 15),
                  prefixIcon: Icon(Icons.search, size: 22, color: scheme.onSurfaceVariant),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                ),
              ),
            ),
          ),

          Expanded(
            child: Builder(
              builder: (context) {
                final dmSearch = context.watch<DmSearchProvider>();
                final searchQuery = provider.search.trim();
                final hasSearch = searchQuery.isNotEmpty;

                if (provider.loading && !hasSearch) {
                  return const Center(child: CircularProgressIndicator());
                }

                final showUserResults = hasSearch && (dmSearch.results.isNotEmpty || dmSearch.loading);
                final showConversations = provider.visibleConversations.isNotEmpty || !hasSearch;

                if (!showUserResults && !showConversations && provider.visibleConversations.isEmpty) {
                  return _buildEmptyState(provider.showArchived);
                }

                return ListView(
                  padding: const EdgeInsets.only(bottom: 10),
                  children: [
                    if (showUserResults) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 6, bottom: 6),
                        child: Text(
                          "Start chat with",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (dmSearch.loading)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                        )
                      else
                        ...dmSearch.results.map((u) => _userSearchTile(u)),
                      const SizedBox(height: 12),
                    ],
                    if (!provider.showArchived && pinned.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(left: 16, top: 6, bottom: 6),
                        child: Text(
                          "Pinned",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...pinned.map(_tile),
                      const SizedBox(height: 6),
                    ],
                    if (!provider.showArchived && normal.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(left: 16, top: 6, bottom: 6),
                        child: Text(
                          "Messages",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...normal.map(_tile),
                    ],
                    if (provider.showArchived) ...[
                      ...provider.visibleConversations.map(_tile),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool archivedTab) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: scheme.outline),
          const SizedBox(height: 16),
          Text(
            archivedTab ? "No archived chats" : "No messages yet",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: scheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            archivedTab ? "Archive chats to see them here" : "Start a conversation from someone's profile",
            style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SwipeActionBg extends StatelessWidget {
  final String label;
  final Color color;
  final bool alignLeft;

  const _SwipeActionBg({
    required this.label,
    required this.color,
    required this.alignLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: color,
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? scheme.onPrimary : scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
