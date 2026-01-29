import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../services/explore_service.dart';
import '../../widgets/app_header.dart';
import '../../widgets/explore/explore_people_tile.dart';
import '../../widgets/explore/explore_search_bar.dart';
import '../../widgets/explore/explore_tabs.dart';
import '../../widgets/explore_post_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final ExploreService _exploreService = ExploreService();

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  int _tabIndex = 0; // 0=All,1=People,2=Texts,3=Photos,4=Videos

  bool _loading = true;
  String? _error;

  List<Post> _posts = [];
  List<User> _people = [];

  @override
  void initState() {
    super.initState();
    _loadTab();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTab() async {
    setState(() {
      _loading = true;
      _error = null;
      _posts = [];
      _people = [];
    });

    try {
      if (_tabIndex == 1) {
        // People tab
        setState(() => _loading = false);
        return;
      }

      if (_tabIndex == 0) {
        final posts = await _exploreService.getExploreAll();
        setState(() {
          _posts = posts;
          _loading = false;
        });
        return;
      }

      if (_tabIndex == 2) {
        final posts = await _exploreService.getExploreByType("text");
        setState(() {
          _posts = posts;
          _loading = false;
        });
        return;
      }

      if (_tabIndex == 3) {
        final posts = await _exploreService.getExploreByType("photo");
        setState(() {
          _posts = posts;
          _loading = false;
        });
        return;
      }

      if (_tabIndex == 4) {
        final posts = await _exploreService.getExploreByType("video");
        setState(() {
          _posts = posts;
          _loading = false;
        });
        return;
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final q = value.trim();

      if (q.isEmpty) {
        setState(() {
          _people = [];
          _error = null;
        });
        return;
      }

      try {
        final users = await _exploreService.searchPeople(q);
        if (!mounted) return;
        setState(() {
          _people = users;
          _error = null;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = e.toString();
        });
      }
    });
  }

  void _onTabChanged(int index) {
    setState(() {
      _tabIndex = index;
      _searchController.clear();
      _people = [];
    });
    _loadTab();
  }

  Future<void> _follow(User user) async {
    try {
      final res = await _exploreService.followUser(user.uid);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res["message"] ?? "Done"),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Follow failed: $e")),
      );
    }
  }

  Widget _grid() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 30),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      );
    }

    if (_posts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(
          child: Text(
            "Nothing to explore yet.\nCreate posts to see them here.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(top: 14),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _posts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final post = _posts[index];
        return ExplorePostCard(
          post: post,
          onTap: () => context.push('/post', extra: post),
          onLongPress: () => _openPostActions(post),
        );
      },
    );
  }

  Widget _peopleList() {
    final q = _searchController.text.trim();

    if (q.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 30),
        child: Center(
          child: Text(
            "Search women to discover profiles.",
            style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    if (_people.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 30),
        child: Center(
          child: Text(
            "No results.",
            style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 14),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _people.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final user = _people[index];

        return ExplorePeopleTile(
          user: user,
          isPrivate: user.isPrivate == true,
          // ✅ FIX: Correctly push to the User Profile
          onOpenProfile: () {
            context.push('/user-profile', extra: user);
          },
          onFollow: () => _follow(user),
        );
      },
    );
  }

  void _openPostActions(Post post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            runSpacing: 10,
            children: [
              Container(
                height: 5,
                width: 46,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const Text(
                "Controls",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 8),

              _actionTile(
                icon: Icons.bookmark_border,
                title: "Save",
                onTap: () async {
                  Navigator.pop(context);
                  await _exploreService.savePost(post.id ?? "");
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Saved")),
                  );
                },
              ),

              _actionTile(
                icon: Icons.share_outlined,
                title: "Share inside SARAN",
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Internal share coming soon")),
                  );
                },
              ),

              _actionTile(
                icon: Icons.visibility_off_outlined,
                title: "Hide this post",
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _posts.removeWhere((p) => p.id == post.id);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Hidden")),
                  );
                },
              ),

              _actionTile(
                icon: Icons.block,
                title: "Block user",
                danger: true,
                onTap: () async {
                  Navigator.pop(context);
                  final uid = post.uid;
                  if (uid == null) return;
                  await _exploreService.blockUser(uid);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("User blocked")),
                  );
                },
              ),

              _actionTile(
                icon: Icons.report_outlined,
                title: "Report post",
                danger: true,
                onTap: () async {
                  Navigator.pop(context);
                  await _exploreService.reportPost(
                    postId: post.id ?? "",
                    reason: "Inappropriate content",
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Reported")),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: danger ? Colors.red : Colors.black),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: danger ? Colors.red : Colors.black,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppHeader(
        title: "Explore",
        unreadCount: 0,
        onOpenNotifications: () => context.push('/notifications'),
        onOpenMessages: () => context.push('/messages'),
      ),

      body: RefreshIndicator(
        onRefresh: _loadTab,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ExploreSearchBar(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onSubmitted: () {},
              onClear: () {
                setState(() {
                  _searchController.clear();
                  _people = [];
                });
              },
            ),

            const SizedBox(height: 14),

            ExploreTabs(
              selectedIndex: _tabIndex,
              onTap: _onTabChanged,
            ),

            if (_tabIndex == 1) _peopleList() else _grid(),
          ],
        ),
      ),
    );
  }
}