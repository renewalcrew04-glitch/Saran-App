import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/post_model.dart';
import '../../widgets/post_card.dart';

/// Single post view (legacy).
class PostDetailScreen extends StatelessWidget {
  final Post? post;
  final List<Post>? posts;
  final int initialIndex;
  /// Called when user undoes a repost (e.g. so profile can refresh and remove from Reposted tab).
  final VoidCallback? onRepostUndone;

  const PostDetailScreen({
    super.key,
    this.post,
    this.posts,
    this.initialIndex = 0,
    this.onRepostUndone,
  });

  bool get _isFullScreenFeed => posts != null && posts!.isNotEmpty;

  List<Post> get _effectivePosts =>
      posts ?? (post != null ? [post!] : <Post>[]);

  int get _initialIndex =>
      posts != null ? initialIndex.clamp(0, posts!.length - 1) : 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_isFullScreenFeed) {
      return _FullScreenPostView(
        posts: _effectivePosts,
        initialIndex: _initialIndex,
        onRepostUndone: onRepostUndone,
      );
    }
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        title: Text(
          "Post",
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        children: [
          PostCard(
            post: post!,
            onPostDeleted: () => Navigator.of(context).pop(),
            onUndoRepostSuccess: onRepostUndone,
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
  final VoidCallback? onRepostUndone;

  const _FullScreenPostView({
    required this.posts,
    required this.initialIndex,
    this.onRepostUndone,
  });

  @override
  State<_FullScreenPostView> createState() => _FullScreenPostViewState();
}

class _FullScreenPostViewState extends State<_FullScreenPostView> {
  static const double _estimatedPostHeight = 420;
  late ScrollController _scrollController;
  List<Post> _posts = [];

  @override
  void initState() {
    super.initState();
    _posts = List<Post>.from(widget.posts);
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final idx = widget.initialIndex.clamp(0, _posts.length - 1);
      final offset = (idx * _estimatedPostHeight)
          .clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.jumpTo(offset);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onUndoRepost(Post post) {
    setState(() {
      _posts.removeWhere((p) => p.id == post.id);
    });
    widget.onRepostUndone?.call();
    if (_posts.isEmpty && mounted) {
      Navigator.of(context).pop();
    }
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
            '${_posts.length} post${_posts.length == 1 ? '' : 's'}',
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
            left: 0,
            right: 0,
            bottom: MediaQuery.paddingOf(context).bottom + 24,
          ),
          itemCount: _posts.length,
          itemBuilder: (context, index) {
            final post = _posts[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PostCard(
                post: post,
                onPostDeleted: () => Navigator.of(context).pop(),
                onUndoRepostSuccess: () => _onUndoRepost(post),
              ),
            );
          },
        ),
      ),
    );
  }
}
