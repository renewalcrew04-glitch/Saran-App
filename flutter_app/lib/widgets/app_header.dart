import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final bool dark;
  final int unreadCount;
  final VoidCallback? onBack;
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onOpenMessages;
  final VoidCallback? onOpenSearch;
  final VoidCallback? onOpenAI;

  const AppHeader({
    super.key,
    this.title = "SARAN",
    this.showBack = false,
    this.dark = false,
    this.unreadCount = 0,
    this.onBack,
    this.onOpenNotifications,
    this.onOpenMessages,
    this.onOpenSearch,
    this.onOpenAI,
  });

  @override
  Size get preferredSize => const Size.fromHeight(50);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fg = dark ? Colors.white : colorScheme.onSurface;
    final bg = dark ? Colors.black : colorScheme.surface;

    return AppBar(
      backgroundColor: bg,
      elevation: 0,
      surfaceTintColor: bg,
      centerTitle: false,
      titleSpacing: 16,
      leading: showBack
          ? IconButton(
              onPressed: onBack ?? () => Navigator.pop(context),
              icon: Icon(Icons.chevron_left, color: fg),
            )
          : (dark
              ? Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.white, width: 1.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.star, color: Colors.white, size: 20),
                  ),
                )
              : null),
      title: Text(
        title,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 18,
          letterSpacing: 0.5,
        ),
      ),
      actions: showBack
          ? []
          : [
              if (onOpenAI != null)
                IconButton(
                  onPressed: onOpenAI,
                  icon: Image.asset(
                    'assets/ai_logo.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                  tooltip: 'SARAN AI',
                ),
              Stack(
                children: [
                  IconButton(
                    onPressed: onOpenNotifications,
                    icon: FaIcon(FontAwesomeIcons.bell, color: fg, size: 20),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: dark ? Colors.white : colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount > 99 ? "99+" : unreadCount.toString(),
                    style: TextStyle(
                      color: dark ? Colors.black : Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (onOpenSearch != null)
                IconButton(
                  onPressed: onOpenSearch,
                  icon: Icon(Icons.search, color: fg, size: 22),
                )
              else
                IconButton(
                  onPressed: onOpenMessages,
                  icon: FaIcon(FontAwesomeIcons.comment, color: fg, size: 20),
                ),
              const SizedBox(width: 6),
            ],
      bottom: dark
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
    );
  }
}
