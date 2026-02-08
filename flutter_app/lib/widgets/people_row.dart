import 'package:flutter/material.dart';
import '../models/user_model.dart';

class PeopleRow extends StatelessWidget {
  final User user;
  final VoidCallback onFollow;
  final VoidCallback? onTap;
  /// When true, show "Following" and disable button. Use for consistent state across app.
  final bool? isFollowing;
  /// When true, show "Requested". Use for consistent state across app.
  final bool? isFollowPending;

  const PeopleRow({
    super.key,
    required this.user,
    required this.onFollow,
    this.onTap,
    this.isFollowing,
    this.isFollowPending,
  });

  @override
  Widget build(BuildContext context) {
    final profileArea = Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.grey.shade300,
          child: const Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (user.verified)
                    const Icon(Icons.verified, size: 16, color: Colors.black),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                "@${user.username} ${(user.isPrivate == true) ? "• Private" : ""}",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Expanded(
            child: onTap != null
                ? GestureDetector(
                    onTap: onTap,
                    behavior: HitTestBehavior.opaque,
                    child: profileArea,
                  )
                : profileArea,
          ),
          ElevatedButton(
            onPressed: (isFollowing == true) ? null : onFollow,
            style: ElevatedButton.styleFrom(
              backgroundColor: (isFollowing == true || isFollowPending == true) ? Colors.grey : Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(
              isFollowing == true
                  ? 'Following'
                  : isFollowPending == true
                      ? 'Requested'
                      : (user.isPrivate == true)
                          ? 'Request'
                          : 'Follow',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
