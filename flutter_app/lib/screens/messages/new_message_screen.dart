import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../config/api_config.dart';
import '../../models/dm_user_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dm_provider.dart';
import '../../providers/dm_search_provider.dart';
import '../profile/user_profile_screen.dart';
import 'chat_screen.dart';

class NewMessageScreen extends StatefulWidget {
  const NewMessageScreen({super.key});

  @override
  State<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends State<NewMessageScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openProfile(DmUserModel u) {
    final user = User(
      uid: u.uid,
      username: u.username,
      email: '',
      name: u.name,
      avatar: u.avatar,
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

  Future<void> _openDm(DmUserModel user) async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final convoId = await context.read<DmProvider>().openDm(
          token: token,
          otherUid: user.uid,
        );

    if (convoId == null || convoId.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Failed to open chat")),
      );
      return;
    }
    navigator.pushReplacement(
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final token = auth.token;

    final search = context.watch<DmSearchProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        title: const Text("New Message"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              onChanged: (v) {
                if (token == null) return;
                context.read<DmSearchProvider>().search(token: token, query: v);
              },
              decoration: InputDecoration(
                hintText: "Search name or username",
                filled: true,
                fillColor: const Color(0xFFF2F2F2),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: search.loading
                ? const Center(child: CircularProgressIndicator())
                : search.results.isEmpty
                    ? const Center(
                        child: Text(
                          "Search users to start a chat",
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        itemCount: search.results.length,
                        itemBuilder: (context, index) {
                          final u = search.results[index];

                          return ListTile(
                            onTap: () => _openProfile(u),
                            trailing: IconButton(
                              icon: const Icon(Icons.chat_bubble_outline),
                              onPressed: () => _openDm(u),
                              tooltip: 'Message',
                            ),
                            leading: CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.black12,
                              backgroundImage: (u.avatar != null && ApiConfig.networkImageUrl(u.avatar!) != null)
                                  ? CachedNetworkImageProvider(ApiConfig.networkImageUrl(u.avatar!)!)
                                  : null,
                              child: (u.avatar == null || u.avatar!.isEmpty || ApiConfig.networkImageUrl(u.avatar!) == null)
                                  ? Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : "U")
                                  : null,
                            ),
                            title: Text(
                              u.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text("@${u.username}"),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
