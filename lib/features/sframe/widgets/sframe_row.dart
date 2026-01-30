import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/sframe_model.dart';
import '../services/sframe_service.dart';
import '../../../providers/auth_provider.dart';

class SFrameRow extends StatefulWidget {
  const SFrameRow({super.key});

  @override
  State<SFrameRow> createState() => _SFrameRowState();
}

class _SFrameRowState extends State<SFrameRow> {
  late Future<List<SFrame>> _future;

  @override
  void initState() {
    super.initState();
    // ✅ FIX: Use the correct method name 'getSFrames'
    _future = SFrameService.getSFrames();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    if (user == null) return const SizedBox.shrink();

    return FutureBuilder<List<SFrame>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 100);

        final allFrames = snapshot.data!;
        
        // Group frames by UID
        final Map<String, List<SFrame>> grouped = {};
        
        for (var f in allFrames) {
          // ✅ FIX: Handle nullable uid safely
          final uid = f.uid;
          if (uid != null && uid.isNotEmpty) {
            if (!grouped.containsKey(uid)) {
              grouped[uid] = [];
            }
            grouped[uid]!.add(f);
          }
        }

        // Separate my stories from others
        final myFrames = grouped[user.uid] ?? [];
        grouped.remove(user.uid);

        return Container(
          height: 110,
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // 1. My Story Card
              _MyStoryCard(
                userAvatar: user.avatar,
                hasStory: myFrames.isNotEmpty,
                onTap: () {
                  if (myFrames.isNotEmpty) {
                    context.push('/sframe-viewer', extra: {
                      'frames': myFrames,
                      'startIndex': 0,
                    });
                  } else {
                    context.push('/sframe-create');
                  }
                },
                onAdd: () => context.push('/sframe-create'),
              ),

              // 2. Others
              ...grouped.entries.map((entry) {
                return _UserStoryCard(
                  frames: entry.value,
                  onTap: () {
                    context.push('/sframe-viewer', extra: {
                      'frames': entry.value,
                      'startIndex': 0,
                    });
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _MyStoryCard extends StatelessWidget {
  final String? userAvatar;
  final bool hasStory;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _MyStoryCard({
    required this.userAvatar,
    required this.hasStory,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: hasStory
                      ? Border.all(color: Colors.pink, width: 2)
                      : Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundImage: userAvatar != null ? NetworkImage(userAvatar!) : null,
                  backgroundColor: Colors.grey.shade200,
                  child: userAvatar == null ? const Icon(Icons.person, color: Colors.grey) : null,
                ),
              ),
              if (!hasStory)
                Positioned(
                  bottom: 0,
                  right: 8,
                  child: GestureDetector(
                    onTap: onAdd,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 16),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Text("Your Story", style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _UserStoryCard extends StatelessWidget {
  final List<SFrame> frames;
  final VoidCallback onTap;

  const _UserStoryCard({required this.frames, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Basic extraction - assumes backend populates or use placeholders
    final frame = frames.first;
    // In real app, you'd access frame.userData or similar
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.pink, width: 2),
              ),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: Colors.grey.shade300,
                // Placeholder for other user avatar
                child: const Icon(Icons.person), 
              ),
            ),
            const SizedBox(height: 6),
            const Text("User", style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}