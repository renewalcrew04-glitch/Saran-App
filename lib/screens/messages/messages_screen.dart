import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../../models/conversation_model.dart';
import '../../services/message_service.dart';
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
      final auth = context.read<AuthProvider>();
      final token = auth.token;
      if (token == null) return;

      await context.read<MessageProvider>().loadConversations(token: token);
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
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
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
          otherName: other.name ?? "User",
          otherAvatar: other.avatar,
        ),
      ),
    );
  }

  Widget _tile(ConversationModel c) {
    final other = c.otherUser;

    final name = other?.name ?? "User";
    final avatar = other?.avatar;
    final online = other?.online == true;

    return Dismissible(
      key: ValueKey(c.id),
      background: _SwipeActionBg(
        label: c.isPinned == true ? "Unpin" : "Pin",
        color: Colors.black,
        alignLeft: true,
      ),
      secondaryBackground: _SwipeActionBg(
        label: c.isArchived == true ? "Unarchive" : "Archive",
        color: Colors.red,
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[200]!, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: (avatar != null && avatar.isNotEmpty)
                          ? CachedNetworkImageProvider(avatar)
                          : null,
                      child: (avatar == null || avatar.isEmpty)
                          ? Text(
                              name[0].toUpperCase(),
                              style: TextStyle(
                                color: Colors.grey[700],
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
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                      ),
                    ),
                ],
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
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.lastMessage.isNotEmpty ? c.lastMessage : "Photo",
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                  color: Colors.black12,
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
                title: const Text(
                  "Delete chat",
                  style: TextStyle(color: Colors.red),
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

    final pinned = provider.pinnedConversations;
    final normal = provider.normalConversations;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 0.5, color: Colors.grey[300]),
        ),
        title: const Text(
          'Messages',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _refresh,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.black),
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

          // search
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: provider.setSearch,
                decoration: InputDecoration(
                  hintText: 'Search messages',
                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 15),
                  prefixIcon: Icon(Icons.search, size: 22, color: Colors.grey[600]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                ),
              ),
            ),
          ),

          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : provider.visibleConversations.isEmpty
                    ? _buildEmptyState(provider.showArchived)
                    : ListView(
                        children: [
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
                          const SizedBox(height: 10),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool archivedTab) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            archivedTab ? "No archived chats" : "No messages yet",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            archivedTab ? "Archive chats to see them here" : "Start a conversation from someone's profile",
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.black : const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
