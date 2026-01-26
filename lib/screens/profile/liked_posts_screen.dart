import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/post_model.dart';
import '../../services/post_service.dart';

/// Instagram-style Liked Posts screen showing all posts the user has liked
class LikedPostsScreen extends StatefulWidget {
  const LikedPostsScreen({super.key});

  @override
  State<LikedPostsScreen> createState() => _LikedPostsScreenState();
}

class _LikedPostsScreenState extends State<LikedPostsScreen> {
  final PostService _postService = PostService();
  List<Post> _likedPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLikedPosts();
  }

  Future<void> _loadLikedPosts() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Fetch liked posts from API
      // For now, showing empty state
      setState(() {
        _likedPosts = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading liked posts: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 0.5,
            color: Colors.grey[300],
          ),
        ),
        title: const Text(
          'Liked Posts',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _likedPosts.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadLikedPosts,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(2),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemCount: _likedPosts.length,
                    itemBuilder: (context, index) {
                      final post = _likedPosts[index];
                      return GestureDetector(
                        onTap: () {
                          // Navigate to post detail
                        },
                        child: post.media.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: post.media.first,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.text_fields),
                              ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.pink.shade50,
            Colors.red.shade50,
            Colors.white,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.favorite_border,
                size: 64,
                color: Colors.pink.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No liked posts yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Posts you like will appear here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
