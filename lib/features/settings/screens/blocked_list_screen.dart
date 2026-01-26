import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../services/settings_api.dart';

class BlockedListScreen extends StatefulWidget {
  const BlockedListScreen({super.key});

  @override
  State<BlockedListScreen> createState() => _BlockedListScreenState();
}

class _BlockedListScreenState extends State<BlockedListScreen> {
  final api = SettingsApi();
  bool loading = true;
  List<User> blockedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadBlocked();
  }

  Future<void> _loadBlocked() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;

    api.setToken(auth.token!);

    setState(() => loading = true);

    try {
      final list = await api.getBlockedUsers();
      final users = list.map((e) => User.fromJson(e)).toList();

      if (!mounted) return;
      setState(() {
        blockedUsers = users;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load blocked users")),
      );
    }
  }

  Future<void> _unblock(User user) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;

    api.setToken(auth.token!);

    try {
      await api.unblockUser(user.uid);

      if (!mounted) return;
      setState(() {
        blockedUsers.removeWhere((u) => u.uid == user.uid);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${user.username} unblocked")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to unblock")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Blocked Accounts"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadBlocked,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : blockedUsers.isEmpty
                ? const Center(
                    child: Text(
                      "No blocked accounts",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: blockedUsers.length,
                    itemBuilder: (context, index) {
                      final user = blockedUsers[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEDEDED)),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage:
                                  (user.avatar != null && user.avatar!.isNotEmpty)
                                      ? NetworkImage(user.avatar!)
                                      : null,
                              child: (user.avatar == null || user.avatar!.isEmpty)
                                  ? Text(
                                      user.name.isNotEmpty
                                          ? user.name[0].toUpperCase()
                                          : "S",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black,
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
                                    user.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "@${user.username}",
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 36,
                              child: OutlinedButton(
                                onPressed: () => _unblock(user),
                                child: const Text("Unblock"),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
