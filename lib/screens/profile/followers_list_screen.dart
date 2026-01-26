import 'package:flutter/material.dart';
import '../../services/profile_service.dart';

class FollowersListScreen extends StatefulWidget {
  final String userId;
  final String username;

  const FollowersListScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<FollowersListScreen> createState() => _FollowersListScreenState();
}

class _FollowersListScreenState extends State<FollowersListScreen> {
  final ProfileService _profileService = ProfileService();
  bool _loading = true;
  List<Map<String, dynamic>> _followers = [];

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
    setState(() => _loading = true);
    try {
      final data = await _profileService.getFollowers(widget.userId);
      setState(() {
        _followers = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("${widget.username} • Followers"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _followers.isEmpty
              ? const Center(child: Text("No followers yet"))
              : ListView.separated(
                  itemCount: _followers.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final u = _followers[index];
                    final name = (u['name'] ?? '').toString();
                    final username = (u['username'] ?? '').toString();
                    final avatar = u['avatar']?.toString();

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage:
                            avatar != null ? NetworkImage(avatar) : null,
                        child: avatar == null && name.isNotEmpty
                            ? Text(name[0].toUpperCase())
                            : null,
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text("@$username"),
                      trailing: OutlinedButton(
                        onPressed: () {
                          // Future: view profile
                        },
                        child: const Text("View"),
                      ),
                    );
                  },
                ),
    );
  }
}
