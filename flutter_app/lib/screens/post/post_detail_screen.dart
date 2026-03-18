import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/post_model.dart';
import '../../services/comment_service.dart';
import '../../widgets/post_card.dart';
import '../../widgets/comment_tile.dart';
import '../../widgets/comment_input_bar.dart';

class PostDetailScreen extends StatefulWidget {
  final Post? post;
  final List<Post>? posts;
  final int initialIndex;
  final VoidCallback? onRepostUndone;
  final VoidCallback? onPostDeleted;

  const PostDetailScreen({
    super.key,
    this.post,
    this.posts,
    this.initialIndex = 0,
    this.onRepostUndone,
    this.onPostDeleted,
  });

  bool get _isFullScreenFeed => posts != null && posts!.isNotEmpty;

  List<Post> get _effectivePosts =>
      posts ?? (post != null ? [post!] : <Post>[]);

  int get _initialIndex =>
      posts != null ? initialIndex.clamp(0, posts!.length - 1) : 0;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentService = CommentService();
  List _comments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!widget._isFullScreenFeed && widget.post != null) {
      _loadComments();
    }
  }

  Future<void> _loadComments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _commentService.getComments(widget.post!.id);
      if (!mounted) return;
      setState(() {
        _comments = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _addComment(String text) async {
    try {
      final newComment = await _commentService.addComment(widget.post!.id, text);
      if (!mounted) return;
      if (newComment != null) {
        setState(() => _comments = [newComment, ..._comments]);
      } else {
        await _loadComments();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget._isFullScreenFeed) {
      return _FullScreenPostView(
        posts: widget._effectivePosts,
        initialIndex: widget._initialIndex,
        onRepostUndone: widget.onRepostUndone,
      );
    }

    final post = widget.post!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: scheme.onSurface),
        title: Text(
          'Post',
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Post card ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: PostCard(
              post: post,
              disableDefaultNavigation: true,
              onPostDeleted: () {
                widget.onPostDeleted?.call();
                Navigator.of(context).pop();
              },
              onUndoRepostSuccess: widget.onRepostUndone,
            ),
          ),

          // ── Divider + comments label ───────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: scheme.outlineVariant, height: 1),
                  const SizedBox(height: 12),
                  Text(
                    'Comments',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── Comments list ──────────────────────────────────────────
          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.error_outline,
                          color: scheme.onSurfaceVariant, size: 36),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _loadComments,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_comments.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 40, color: scheme.onSurfaceVariant),
                      const SizedBox(height: 10),
                      Text(
                        'No comments yet.\nBe the first to comment!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => CommentTile(
                  postId: post.id,
                  comment: _comments[i],
                  onReply: _loadComments,
                ),
                childCount: _comments.length,
              ),
            ),

          // ── Bottom padding for input bar ───────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      bottomSheet: Container(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        child: CommentInputBar(
          onSend: _addComment,
        ),
      ),
    );
  }
}

// ── Full-screen feed (unchanged) ──────────────────────────────────────────────
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
                disableDefaultNavigation: true,
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
