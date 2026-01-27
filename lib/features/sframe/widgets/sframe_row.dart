import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/sframe_service.dart';
import '../models/sframe_model.dart';

class SFrameRow extends StatelessWidget {
  const SFrameRow({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = "me"; // TEMP placeholder

    return FutureBuilder<List<SFrame>>(
      future: SFrameService.loadFrames(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 110,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const SizedBox(
            height: 110,
            child: Center(
              child: Text(
                "Failed to load S-Frames",
                style: TextStyle(color: Colors.black54),
              ),
            ),
          );
        }

        final frames = snapshot.data ?? [];

        // One frame per user (latest)
        final map = <String, SFrame>{};
        for (final f in frames) {
          map[f.uid] = f;
        }

        final list = map.values.toList();

        return SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: list.length + 1, // +1 for create
            itemBuilder: (context, i) {
              // ================= CREATE S-FRAME =================
              if (i == 0) {
                return GestureDetector(
                  onTap: () {
                    context.push('/sframe-create');
                  },
                  child: Container(
                    width: 90,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, size: 28),
                        SizedBox(height: 6),
                        Text(
                          "Create",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // ================= USER S-FRAME =================
              final f = list[i - 1];
              final seen = f.views.contains(uid);

              return GestureDetector(
                onTap: () {
                  context.push(
                    '/sframe-viewer',
                    extra: {
                      'frames': list,
                      'startIndex': i - 1,
                    },
                  );
                },
                child: Container(
                  width: 90,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: seen ? Colors.grey : Colors.black,
                      width: 2,
                    ),
                  ),
                  child: const Icon(Icons.person),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
