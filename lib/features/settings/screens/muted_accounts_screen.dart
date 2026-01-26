import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../services/settings_api.dart';

class MutedAccountsScreen extends StatefulWidget {
  const MutedAccountsScreen({super.key});

  @override
  State<MutedAccountsScreen> createState() => _MutedAccountsScreenState();
}

class _MutedAccountsScreenState extends State<MutedAccountsScreen> {
  final api = SettingsApi();
  bool loading = true;
  List muted = [];

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
      final list = await api.getMuted();
      setState(() {
        muted = list;
        loading = false;
      });
    } catch (_) {
      setState(() => loading = false);
    }
  }

  Future<void> _mute() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;

    final uid = uidController.text.trim();
    if (uid.isEmpty) return;

    api.setToken(auth.token!);

    await api.muteUser(uid);
    uidController.clear();
    await _load();
  }

  Future<void> _unmute(String uid) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;

    api.setToken(auth.token!);

    await api.unmuteUser(uid);
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
        title: const Text("Muted Accounts"),
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
                            hintText: "Enter UID to mute",
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
                          onPressed: _mute,
                          child: const Text("Mute"),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: muted.isEmpty
                      ? const Center(child: Text("No muted accounts"))
                      : ListView.separated(
                          itemCount: muted.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final u = muted[index];
                            final uid = u["uid"] ?? "";
                            final username = u["username"] ?? "";
                            final name = u["name"] ?? "";

                            return ListTile(
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Text("@$username"),
                              trailing: TextButton(
                                onPressed: () => _unmute(uid),
                                child: const Text("Unmute", style: TextStyle(color: Colors.red)),
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
