import 'package:flutter/material.dart';
import '../models/sframe_model.dart';
import '../screens/sframe_viewer_screen.dart';

class ProfileSFrameGrid extends StatelessWidget {
  final List<SFrame> frames;

  const ProfileSFrameGrid({super.key, required this.frames});

  @override
  Widget build(BuildContext context) {
    if (frames.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          "No S-Frames yet",
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: frames.length,
      itemBuilder: (_, i) {
        final frame = frames[i];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SFrameViewerScreen(
                  frames: frames,
                  startIndex: i,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(14),
            ),
            child: frame.mediaType == "photo"
                ? Image.network(
                    frame.mediaUrl!,
                    fit: BoxFit.cover,
                  )
                : const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                  ),
          ),
        );
      },
    );
  }
}
