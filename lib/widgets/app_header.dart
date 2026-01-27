import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final int unreadCount;
  final VoidCallback? onBack;
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onOpenMessages;

  const AppHeader({
    super.key,
    this.title = "SARAN",
    this.showBack = false,
    this.unreadCount = 0,
    this.onBack,
    this.onOpenNotifications,
    this.onOpenMessages,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
  backgroundColor: Colors.white,
  elevation: 0,
  surfaceTintColor: Colors.white,
  centerTitle: false,
  titleSpacing: 16,
      leading: showBack
          ? IconButton(
              onPressed: onBack ?? () => Navigator.pop(context),
              icon: const Icon(Icons.chevron_left, color: Colors.black),
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w800,
          fontSize: 18,
          letterSpacing: 0.5,
        ),
      ),
      actions: showBack
          ? []
          : [
              // Notifications
              Stack(
                children: [
                  IconButton(
                    onPressed: onOpenNotifications,
                    icon: const FaIcon(FontAwesomeIcons.bell, color: Colors.black, size: 20),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount > 99 ? "99+" : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Messages
              IconButton(
                onPressed: onOpenMessages,
                icon: const FaIcon(FontAwesomeIcons.comment, color: Colors.black, size: 20),
              ),
              const SizedBox(width: 6),
            ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.black12,
        ),
      ),
    );
  }
}
