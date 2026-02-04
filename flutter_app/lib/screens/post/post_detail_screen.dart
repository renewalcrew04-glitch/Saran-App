import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/post_model.dart';
import '../../widgets/post_card.dart';

/// Single post view (legacy).
class PostDetailScreen extends StatelessWidget {
  final Post? post;
  final List<Post>? posts;
  final int initialIndex;

  const PostDetailScreen({
    super.key,
    this.post,
    this.posts,
    this.initialIndex = 0,
  });

  bool get _isFullScreenFeed => posts != null && posts!.isNotEmpty;

  List<Post> get _effectivePosts =>
      posts ?? (post != null ? [post!] : <Post>[]);

  int get _initialIndex =>
      posts != null ? initialIndex.clamp(0, posts!.length - 1) : 0;

  @override
  Widget build(BuildContext context) {
    if (_isFullScreenFeed) {
      return _FullScreenPostView(
        posts: _effectivePosts,
        initialIndex: _initialIndex,
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Post",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        children: [
          PostCard(
            post: post!,
            onPostDeleted: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// Full-screen post viewer: all posts in one scrollable list, starting at [initialIndex].
class _FullScreenPostView extends StatefulWidget {
  final List<Post> posts;
  final int initialIndex;

  const _FullScreenPostView({
    required this.posts,
    required this.initialIndex,
  });

  @override
  State<_FullScreenPostView> createState() => _FullScreenPostViewState();
}

class _FullScreenPostViewState extends State<_FullScreenPostView> {
  static const double _estimatedPostHeight = 420;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final offset = (widget.initialIndex * _estimatedPostHeight)
          .clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.jumpTo(offset);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            '${widget.posts.length} post${widget.posts.length == 1 ? '' : 's'}',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        body: ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
            left: 8,
            right: 8,
            bottom: MediaQuery.paddingOf(context).bottom + 24,
          ),
          itemCount: widget.posts.length,
          itemBuilder: (context, index) {
            final post = widget.posts[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PostCard(
                post: post,
                onPostDeleted: () => Navigator.of(context).pop(),
              ),
            );
          },
        ),
      ),
    );
  }
}
