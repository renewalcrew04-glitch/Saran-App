import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../services/settings_api.dart';

class CloseFriendsScreen extends StatefulWidget {
  const CloseFriendsScreen({super.key});

  @override
  State<CloseFriendsScreen> createState() => _CloseFriendsScreenState();
}

class _CloseFriendsScreenState extends State<CloseFriendsScreen> {
  final api = SettingsApi();
  bool loading = true;
  List friends = [];

  final TextEditingController uidController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) {
      setState(() => loading = false);
      return;
    }

    api.setToken(auth.token!);

    try {
      final list = await api.getCloseFriends();
      setState(() {
        friends = list;
        loading = false;
      });
    } catch (_) {
      setState(() => loading = false);
    }
  }

  Future<void> _add() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;

    final uid = uidController.text.trim();
    if (uid.isEmpty) return;

    api.setToken(auth.token!);

    await api.addCloseFriend(uid);
    uidController.clear();
    await _load();
  }

  Future<void> _remove(String uid) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;

    api.setToken(auth.token!);

    await api.removeCloseFriend(uid);
    await _load();
  }

  @override
  void dispose() {
    uidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Close Friends"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: uidController,
                          decoration: const InputDecoration(
                            hintText: "Enter UID to add",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _add,
                          child: const Text("Add"),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: friends.isEmpty
                      ? const Center(child: Text("No close friends yet"))
                      : ListView.separated(
                          itemCount: friends.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final u = friends[index];
                            final uid = u["uid"] ?? "";
                            final username = u["username"] ?? "";
                            final name = u["name"] ?? "";

                            return ListTile(
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Text("@$username"),
                              trailing: TextButton(
                                onPressed: () => _remove(uid),
                                child: const Text("Remove", style: TextStyle(color: Colors.red)),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
