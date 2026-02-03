import 'package:flutter/material.dart';

void showSeenModal(
  BuildContext context,
  List<Map<String, dynamic>> users,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.black,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Who viewed',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (users.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No views yet',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                shrinkWrap: true,
                itemCount: users.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: Colors.white12),
                itemBuilder: (_, i) {
                  final user = users[i];
                  final avatarUrl = user['photoURL'] ?? user['avatar'];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl.toString())
                          : null,
                      backgroundColor: Colors.white24,
                    ),
                    title: Text(
                      user['name'] ?? "Unknown",
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    ),
  );
}
