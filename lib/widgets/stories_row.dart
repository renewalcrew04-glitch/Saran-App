import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../features/sframe/models/sframe_model.dart';
import '../features/sframe/services/sframe_service.dart';
import '../providers/auth_provider.dart';

class StoriesRow extends StatefulWidget {
  const StoriesRow({super.key});

  @override
  State<StoriesRow> createState() => _StoriesRowState();
}

class _StoriesRowState extends State<StoriesRow> {
  bool _loading = true;
  List<SFrame> _frames = [];

  @override
  void initState() {
    super.initState();
    _loadFrames();
  }

  Future<void> _loadFrames() async {
    try {
      final frames = await SFrameService.getSFrames();
      if (mounted) {
        setState(() {
          _frames = frames;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    if (user == null) return const SizedBox.shrink();

    // Group frames by User UID
    final Map<String, List<SFrame>> groupedFrames = {};
    for (var frame in _frames) {
      if (frame.uid != user.uid) {
        if (!groupedFrames.containsKey(frame.uid)) {
          groupedFrames[frame.uid!] = [];
        }
        groupedFrames[frame.uid]!.add(frame);
      }
    }

    // Check if current user has an active story
    final myFrames = _frames.where((f) => f.uid == user.uid).toList();
    final hasMyStory = myFrames.isNotEmpty;

    return Container(
      height: 120, // Slightly taller for the glow/border
      margin: const EdgeInsets.only(top: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        children: [
          // 1. Create / My Story Card (Premium)
          _CreateStoryCard(
            userAvatar: user.avatar,
            hasStory: hasMyStory,
            onTap: () {
              if (hasMyStory) {
                context.push('/sframe-viewer', extra: {
                  'frames': myFrames,
                  'startIndex': 0,
                });
              } else {
                context.push('/sframe-create');
              }
            },
            onAddTap: () => context.push('/sframe-create'),
          ),

          // 2. Other Users' Stories
          ...groupedFrames.entries.map((entry) {
            final uid = entry.key;
            final frames = entry.value;
            return _StoryCard(
              frames: frames,
              onTap: () {
                context.push('/sframe-viewer', extra: {
                  'frames': frames,
                  'startIndex': 0,
                });
              },
            );
          }),
        ],
      ),
    );
  }
}

/// "Add Story" or "My Story" Card with Premium Dotted Border
class _CreateStoryCard extends StatelessWidget {
  final String? userAvatar;
  final bool hasStory;
  final VoidCallback onTap;
  final VoidCallback onAddTap;

  const _CreateStoryCard({
    required this.userAvatar,
    required this.hasStory,
    required this.onTap,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    const double size = 74; // Total size of the circle

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 85, // Width of the whole item column
        margin: const EdgeInsets.only(right: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // 1. Premium Border (Dotted if empty, Gradient if active)
                if (!hasStory)
                  CustomPaint(
                    size: const Size(size, size),
                    painter: _PremiumDottedBorderPainter(
                      color: Colors.grey.shade400,
                      dots: 20,
                      strokeWidth: 2,
                    ),
                  )
                else
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF833AB4), // Purple
                          Color(0xFFFD1D1D), // Red
                          Color(0xFFFCB045), // Orange
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFD1D1D).withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),

                // 2. White Spacer (Gap between border and avatar)
                Container(
                  width: size - 6,
                  height: size - 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),

                // 3. Avatar
                Container(
                  width: size - 12,
                  height: size - 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                    image: userAvatar != null
                        ? DecorationImage(
                            image: NetworkImage(userAvatar!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: userAvatar == null
                      ? Icon(Icons.person, color: Colors.grey.shade400, size: 30)
                      : null,
                ),

                // 4. Floating "+" Badge (Only if no story)
                if (!hasStory)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: onAddTap,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF232526), Color(0xFF414345)], // Premium Black Gradient
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              hasStory ? "Your Story" : "Create",
              style: TextStyle(
                fontSize: 12,
                fontWeight: hasStory ? FontWeight.bold : FontWeight.w500,
                color: hasStory ? Colors.black : Colors.grey.shade800,
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Other User's Story Card
class _StoryCard extends StatelessWidget {
  final List<SFrame> frames;
  final VoidCallback onTap;

  const _StoryCard({required this.frames, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const double size = 74;
    // Extract first frame data
    final frame = frames.first;
    // Placeholder extraction - ideally populate user data in backend
    final String? avatar = frame.mediaType == 'photo' ? frame.mediaUrl : null;
    const String username = "User"; // Replace with frame.userData.username if populated

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 85,
        margin: const EdgeInsets.only(right: 8),
        child: Column(
          children: [
            Container(
              width: size,
              height: size,
              padding: const EdgeInsets.all(2.5), // Gap
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                // Instagram-like gradient for unread stories
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFC13584),
                    Color(0xFFE1306C),
                    Color(0xFFFDCB5C),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 2), // Inner white border
                  image: avatar != null
                      ? DecorationImage(
                          image: NetworkImage(avatar),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: avatar == null
                    ? Icon(Icons.person_outline, color: Colors.grey[400])
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              username,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Painter for the Premium Dotted Border
class _PremiumDottedBorderPainter extends CustomPainter {
  final Color color;
  final int dots;
  final double strokeWidth;

  _PremiumDottedBorderPainter({
    required this.color,
    this.dots = 15,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round; // Rounded dots look more premium

    final double circumference = 2 * pi * radius;
    final double gap = 6.0; // Gap between dots
    final double dashWidth = (circumference / dots) - gap;

    for (int i = 0; i < dots; i++) {
      final double startAngle = (2 * pi * i) / dots;
      final double sweepAngle = dashWidth / radius;
      
      canvas.drawArc(
        Rect.fromCircle(center: Offset(radius, radius), radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}