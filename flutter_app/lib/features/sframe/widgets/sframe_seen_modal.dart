import 'package:flutter/material.dart';
import '../../../utils/media_utils.dart';

void showSeenModal(
  BuildContext context,
  List<Map<String, dynamic>> users,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1C1C1E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              'Who viewed',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (users.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.visibility_off_rounded, color: Colors.white.withValues(alpha: 0.4), size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'No views yet',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                shrinkWrap: true,
                itemCount: users.length,
                separatorBuilder: (_, __) => Divider(
                  color: Colors.white.withValues(alpha: 0.08),
                  height: 1,
                ),
                itemBuilder: (_, i) {
                  final user = users[i];
                  final avatarUrl = user['photoURL'] ?? user['avatar'];
                  final echoed = user['echoed'] == true;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    leading: avatarUrl != null
                        ? safeAvatarNetworkImage(
                            url: avatarUrl.toString(),
                            size: 48,
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                          )
                        : CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            child: Icon(Icons.person_rounded, color: Colors.white.withValues(alpha: 0.6), size: 26),
                          ),
                    title: Text(
                      user['name'] ?? "Unknown",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: echoed
                        ? const Icon(Icons.favorite, color: Colors.red, size: 22)
                        : null,
                  );
                },
              ),
            ),
        ],
      ),
    ),
  );
}
