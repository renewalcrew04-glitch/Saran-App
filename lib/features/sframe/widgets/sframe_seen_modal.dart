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
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        separatorBuilder: (_, __) =>
            const Divider(color: Colors.white12),
        itemBuilder: (_, i) {
          final user = users[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: user['photoURL'] != null
                  ? NetworkImage(user['photoURL'])
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
  );
}
