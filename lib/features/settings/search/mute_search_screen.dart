import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../models/user_model.dart';

import '../../../widgets/explore/explore_search_bar.dart';

import '../services/settings_api.dart';
import 'settings_search_api.dart';
import 'widgets/settings_user_tile.dart';

class MuteSearchScreen extends StatefulWidget {
  const MuteSearchScreen({super.key});

  @override
  State<MuteSearchScreen> createState() => _MuteSearchScreenState();
}

class _MuteSearchScreenState extends State<MuteSearchScreen> {
  final SettingsApi settingsApi = SettingsApi();
  final SettingsSearchApi searchApi = SettingsSearchApi();

  final TextEditingController controller = TextEditingController();
  Timer? _debounce;

  bool loadingList = true;
  bool loadingSearch = false;

  List<User> mutedList = [];
  List<User> results = [];

  @override
  void initState() {
    super.initState();
    _loadMuted();
  }

  Future<void> _loadMuted() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) {
      setState(() => loadingList = false);
      return;
    }

    settingsApi.setToken(auth.token!);

    try {
      final raw = await settingsApi.getMuted();
      final list = raw.map((e) => User.fromJson(e)).toList();

      if (!mounted) return;
      setState(() {
        mutedList = list;
        loadingList = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loadingList = false);
    }
  }

  bool _isMuted(User u) {
    return mutedList.any((x) => x.uid == u.uid);
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
    setState(() {});
  }

  Future<void> _mute(User u) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;

    settingsApi.setToken(auth.token!);

    try {
      await settingsApi.muteUser(u.uid);
      await _loadMuted();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${u.name} muted")),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to mute user")),
      );
    }
  }

  Future<void> _unmute(User u) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;

    settingsApi.setToken(auth.token!);

    try {
      await settingsApi.unmuteUser(u.uid);
      await _loadMuted();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${u.name} unmuted")),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to unmute user")),
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
        title: const Text("Muted"),
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

          // TOP: muted list
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: const [
                Text(
                  "Muted Accounts",
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
          else if (mutedList.isEmpty)
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text("No muted accounts"),
            )
          else
            SizedBox(
              height: 200,
              child: ListView.separated(
                itemCount: mutedList.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final u = mutedList[index];
                  return SettingsUserTile(
                    user: u,
                    buttonText: "Unmute",
                    buttonColor: Colors.red,
                    onPressed: () => _unmute(u),
                  );
                },
              ),
            ),

          const Divider(height: 1),

          // BELOW: search results
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
                ? const Center(child: Text("Search women to mute"))
                : ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final u = results[index];
                      final alreadyMuted = _isMuted(u);

                      return SettingsUserTile(
                        user: u,
                        buttonText: alreadyMuted ? "Muted" : "Mute",
                        buttonColor: alreadyMuted ? Colors.grey : Colors.red,
                        onPressed: alreadyMuted ? () {} : () => _mute(u),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
