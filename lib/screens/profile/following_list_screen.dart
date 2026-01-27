import 'package:flutter/material.dart';
import '../../services/profile_service.dart';

class FollowingListScreen extends StatefulWidget {
  final String userId;
  final String username;

  const FollowingListScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<FollowingListScreen> createState() => _FollowingListScreenState();
}

class _FollowingListScreenState extends State<FollowingListScreen> {
  final ProfileService _profileService = ProfileService();
  bool _loading = true;
  List<Map<String, dynamic>> _following = [];

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  Future<void> _loadFollowing() async {
    setState(() => _loading = true);
    try {
      final data = await _profileService.getFollowing(widget.userId);
      setState(() {
        _following = data;
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
        title: Text("${widget.username} • Following"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _following.isEmpty
              ? const Center(child: Text("Not following anyone yet"))
              : ListView.separated(
                  itemCount: _following.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final u = _following[index];
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
                          // Future: unfollow
                        },
                        child: const Text("Following"),
                      ),
                    );
                  },
                ),
    );
  }
}
