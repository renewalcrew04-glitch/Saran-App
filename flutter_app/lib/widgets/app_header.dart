import 'dart:ui';
import 'package:flutter/material.dart';
import 'glass_box.dart';

// ── SARAN brand tokens ────────────────────────────────────────────────────
const _kSurface   = Color(0xFF0B0F1A);
const _kPrimary   = Color(0xFFFF8132);
const _kPrimaryLt = Color(0xFFFF9D5C);
const _kSubtext   = Color(0xFF94A3B8);
const _kBorder    = Color(0xFF1E2535);
const _kText      = Color(0xFFF1F5F9);

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final bool dark;
  final int unreadCount;
  final int messageUnreadCount;
  final VoidCallback? onBack;
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onOpenMessages;
  final VoidCallback? onOpenSearch;
  final VoidCallback? onOpenAI;

  const AppHeader({
    super.key,
    this.title = 'SARAN',
    this.showBack = false,
    this.dark = false,
    this.unreadCount = 0,
    this.messageUnreadCount = 0,
    this.onBack,
    this.onOpenNotifications,
    this.onOpenMessages,
    this.onOpenSearch,
    this.onOpenAI,
  });

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? _kSurface : Theme.of(context).colorScheme.surface;
    final iconFg = isDark ? _kSubtext  : Theme.of(context).colorScheme.onSurfaceVariant;
    final textFg = isDark ? _kText     : Theme.of(context).colorScheme.onSurface;

    return AppBar(
      backgroundColor: bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      automaticallyImplyLeading: false,
      titleSpacing: 16,

      // ── Logo / back button ──────────────────────────────────────────────
      leading: showBack
          ? IconButton(
              onPressed: onBack ?? () => Navigator.pop(context),
              icon: Icon(Icons.chevron_left_rounded, color: iconFg, size: 26),
            )
          : Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                children: [
                  // App logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/app_icon.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_kPrimaryLt, Color(0xFFFF6A00)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'S',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      leadingWidth: showBack ? 48 : 56,

      // ── Title ──────────────────────────────────────────────────────────
      title: showBack
          ? Text(
              title,
              style: TextStyle(
                color: textFg,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            )
          : Text(
              'SARAN',
              style: TextStyle(
                color: textFg,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),

      // ── Actions ────────────────────────────────────────────────────────
      actions: showBack
          ? []
          : [
              // ── Saran AI icon ────────────────────────────────────────────
              GestureDetector(
                onTap: onOpenAI,
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/ai_logo.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.auto_awesome,
                        color: iconFg,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // ── Bell — liquid glass circle ───────────────────────────────
              Stack(
                children: [
                  GlassIconButton(
                    icon: Icons.notifications_none_rounded,
                    onTap: onOpenNotifications,
                    size: 36,
                    iconSize: 20,
                    iconColor: iconFg,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _kPrimary,
                          shape: BoxShape.circle,
                          border: Border.all(color: bg, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 6),
              // ── Chat bubble — liquid glass circle ────────────────────────
              Stack(
                children: [
                  GlassIconButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    onTap: onOpenMessages,
                    size: 36,
                    iconSize: 19,
                    iconColor: iconFg,
                  ),
                  if (messageUnreadCount > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _kPrimary,
                          shape: BoxShape.circle,
                          border: Border.all(color: bg, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
            ],

      // ── Bottom border ──────────────────────────────────────────────────
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: isDark
              ? _kBorder
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    );
  }
}
