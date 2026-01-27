import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../services/settings_api.dart';

class NotificationsListScreen extends StatefulWidget {
  const NotificationsListScreen({super.key});

  @override
  State<NotificationsListScreen> createState() => _NotificationsListScreenState();
}

class _NotificationsListScreenState extends State<NotificationsListScreen> {
  final api = SettingsApi();
  bool loading = true;
  List items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);

    // token must exist
    if (auth.token == null) {
      setState(() => loading = false);
      return;
    }

    api.setToken(auth.token!);

    try {
      final data = await api.getNotifications();
      setState(() {
        items = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(child: Text("No notifications"))
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final n = items[index];
                    final title = n['title'] ?? 'Notification';
                    final body = n['body'] ?? '';

                    return ListTile(
                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(body),
                    );
                  },
                ),
    );
  }
}
