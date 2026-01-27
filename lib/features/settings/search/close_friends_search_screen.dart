import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../models/user_model.dart';

import '../../../widgets/explore/explore_search_bar.dart';

import '../services/settings_api.dart';
import 'settings_search_api.dart';
import 'widgets/settings_user_tile.dart';

class CloseFriendsSearchScreen extends StatefulWidget {
  const CloseFriendsSearchScreen({super.key});

  @override
  State<CloseFriendsSearchScreen> createState() => _CloseFriendsSearchScreenState();
}

class _CloseFriendsSearchScreenState extends State<CloseFriendsSearchScreen> {
  final SettingsApi settingsApi = SettingsApi();
  final SettingsSearchApi searchApi = SettingsSearchApi();

  final TextEditingController controller = TextEditingController();
  Timer? _debounce;

  bool loadingList = true;
  bool loadingSearch = false;

  List<User> closeFriends = [];
  List<User> results = [];

  @override
  void initState() {
    super.initState();
    _loadCloseFriends();
  }

  Future<void> _loadCloseFriends() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) {
      setState(() => loadingList = false);
      return;
    }

    settingsApi.setToken(auth.token!);

    try {
      final raw = await settingsApi.getCloseFriends();
      final list = raw.map((e) => User.fromJson(e)).toList();

      if (!mounted) return;
      setState(() {
        closeFriends = list;
        loadingList = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loadingList = false);
    }
  }

  bool _isAlreadyCloseFriend(User u) {
    return closeFriends.any((x) => x.uid == u.uid);
  }

  Future<void> _search(String q) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;

    if (q.trim().isEmpty) {
      setState(() => results = []);
      return;
    }

    searchApi.setToken(auth.token!);

    setState(() => loadingSearch = true);

    try {
      final raw = await searchApi.searchUsers(q.trim());
      final users = raw.map((e) => User.fromJson(e)).toList();

      // remove self
      final filtered = users.where((u) => u.uid != auth.user?.uid).toList();

      if (!mounted) return;
      setState(() {
        results = filtered;
        loadingSearch = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loadingSearch = false);
    }
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _search(value);
    });
    setState(() {}); // refresh clear button
  }

  Future<void> _addCloseFriend(User u) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;

    settingsApi.setToken(auth.token!);

    try {
      await settingsApi.addCloseFriend(u.uid);
      await _loadCloseFriends();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${u.name} added to Close Friends")),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to add close friend")),
      );
    }
  }

  Future<void> _removeCloseFriend(User u) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;

    settingsApi.setToken(auth.token!);

    try {
      await settingsApi.removeCloseFriend(u.uid);
      await _loadCloseFriends();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${u.name} removed")),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to remove close friend")),
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = controller.text.trim();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Close Friends"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: ExploreSearchBar(
              controller: controller,
              onClear: () {
                controller.clear();
                setState(() => results = []);
                FocusScope.of(context).unfocus();
              },
              onChanged: _onChanged,
              onSubmitted: () => _search(controller.text),
            ),
          ),

          const Divider(height: 1),

          // TOP: Current Close Friends
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: const [
                Text(
                  "Your Close Friends",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ],
            ),
          ),

          if (loadingList)
            const Padding(
              padding: EdgeInsets.all(14),
              child: CircularProgressIndicator(),
            )
          else if (closeFriends.isEmpty)
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text("No close friends yet"),
            )
          else
            SizedBox(
              height: 200,
              child: ListView.separated(
                itemCount: closeFriends.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final u = closeFriends[index];
                  return SettingsUserTile(
                    user: u,
                    buttonText: "Remove",
                    buttonColor: Colors.red,
                    onPressed: () => _removeCloseFriend(u),
                  );
                },
              ),
            ),

          const Divider(height: 1),

          // BELOW: Search results
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Text(
                  q.isEmpty ? "Search Results" : "Results for \"$q\"",
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ],
            ),
          ),

          if (loadingSearch)
            const Padding(
              padding: EdgeInsets.all(14),
              child: CircularProgressIndicator(),
            ),

          Expanded(
            child: results.isEmpty
                ? const Center(child: Text("Search women to add"))
                : ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final u = results[index];
                      final already = _isAlreadyCloseFriend(u);

                      return SettingsUserTile(
                        user: u,
                        buttonText: already ? "Added" : "Add",
                        buttonColor: already ? Colors.grey : Colors.black,
                        onPressed: already ? () {} : () => _addCloseFriend(u),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
