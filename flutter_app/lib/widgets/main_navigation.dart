import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../screens/explore/explore_screen.dart';
import '../utils/screen_scale.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/sos/sos_screen.dart';
import '../screens/space/spaces_hub_screen.dart';

// ── Design tokens (mirrors HTML) ─────────────────────────────────────────────
const _kNavBg      = Color(0xFF0D1120);
const _kNavBorder  = Color(0xFF1E2535);
const _kActive     = Color(0xFFFF8132);   // orange
const _kPrimaryLt  = Color(0xFFFF9D5C);
const _kInactive   = Color(0xFF4A5568);

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  final ValueNotifier<int>  _tabIndexNotifier = ValueNotifier(0);
  final ValueNotifier<bool> _navVisible       = ValueNotifier(true);

  late final List<Widget> _screens;

  void _handleScroll(ScrollDirection direction) {
    if (direction == ScrollDirection.reverse && _navVisible.value) {
      _navVisible.value = false;
    } else if (direction == ScrollDirection.forward && !_navVisible.value) {
      _navVisible.value = true;
    }
  }

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(onScrollDirection: _handleScroll),
      const ExploreScreen(),
      const SosScreen(),
      const SpacesHubScreen(),
      ProfileScreen(tabIndexNotifier: _tabIndexNotifier),
    ];
  }

  void _onTabTap(int index) {
    setState(() => _index = index);
    _tabIndexNotifier.value = index;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: ValueListenableBuilder<bool>(
        valueListenable: _navVisible,
        builder: (context, visible, child) => AnimatedSlide(
          duration: const Duration(milliseconds: 250),
          offset: visible ? Offset.zero : const Offset(0, 1.6),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: visible ? 1.0 : 0.0,
            child: child,
          ),
        ),
        child: _NavBar(
          index: _index,
          bottomPad: bottomPad,
          onTap: _onTabTap,
        ),
      ),
    );
  }
}

// ── Floating liquid-glass capsule bottom nav bar ──────────────────────────────
class _NavBar extends StatelessWidget {
  final int index;
  final double bottomPad;
  final ValueChanged<int> onTap;

  const _NavBar({
    required this.index,
    required this.bottomPad,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sc = context.sc;

    // Capsule is 64 dp tall; outer container adds bottom margin + safe area
    final capsuleH = sc(64);
    final totalHeight = bottomPad + capsuleH + sc(16);

    return Container(
      height: totalHeight,
      color: Colors.transparent,
      alignment: Alignment.bottomCenter,
      padding: EdgeInsets.only(
        left: sc(20),
        right: sc(20),
        bottom: bottomPad + sc(14),
      ),
      child: _GlossyCapsule(
        isDark: isDark,
        height: capsuleH,
        radius: sc(40),
        child: Row(
          children: [
            _NavItem(
              icon: index == 0 ? Icons.home_rounded : Icons.home_outlined,
              active: index == 0,
              isDark: isDark,
              onTap: () => onTap(0),
            ),
            _NavItem(
              icon: index == 1 ? Icons.search_rounded : Icons.search_outlined,
              active: index == 1,
              isDark: isDark,
              onTap: () => onTap(1),
            ),
            // ── SOS: inline, larger orange circle ───────────────────────
            _SosButton(onTap: () => onTap(2)),
            _NavItem(
              icon: index == 3
                  ? Icons.calendar_month_rounded
                  : Icons.calendar_month_outlined,
              active: index == 3,
              isDark: isDark,
              onTap: () => onTap(3),
            ),
            _NavItem(
              icon: index == 4
                  ? Icons.person_rounded
                  : Icons.person_outline_rounded,
              active: index == 4,
              isDark: isDark,
              onTap: () => onTap(4),
            ),
          ],
        ),
      ),
    );
  }
}

/// Liquid-glass pill widget — gradient border + glossy fill + specular sheen.
class _GlossyCapsule extends StatelessWidget {
  final bool isDark;
  final double height;
  final double radius;
  final Widget child;

  const _GlossyCapsule({
    required this.isDark,
    required this.height,
    required this.radius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // ── Gradient border (bright top-left → gray bottom-right) ───────────
    final borderGradient = isDark
        ? [
            Colors.white.withValues(alpha: 0.28),
            Colors.white.withValues(alpha: 0.06),
          ]
        : [
            Colors.white,
            const Color(0xFFCCCCDE),
          ];

    // ── Inner fill gradient (glossy white top → warm tint bottom) ───────
    final fillGradient = isDark
        ? [
            const Color(0xFF252B45),
            const Color(0xFF1A1F35),
          ]
        : [
            Colors.white,
            const Color(0xFFF5F4F8),
          ];

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: borderGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          // Main drop shadow
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.55)
                : Colors.black.withValues(alpha: 0.12),
            blurRadius: 28,
            spreadRadius: -4,
            offset: const Offset(0, 10),
          ),
          // Soft ambient below
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFFAAAAAA).withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(0.9), // border thickness
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 0.9),
        child: Stack(
          children: [
            // ── Glossy fill ────────────────────────────────────────────
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: fillGradient,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // ── Specular sheen: bright horizontal band near top ────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: height * 0.40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: isDark ? 0.12 : 0.70),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // ── Content (icons row) ────────────────────────────────────
            Positioned.fill(child: child),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.active,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? _kActive
        : (isDark ? _kInactive : const Color(0xFF888899));
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: context.sc(10),
              vertical: context.sc(6),
            ),
            decoration: BoxDecoration(
              color: active
                  ? _kActive.withValues(alpha: isDark ? 0.18 : 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(context.sc(14)),
            ),
            child: Icon(icon, color: color, size: context.sc(23)),
          ),
        ),
      ),
    );
  }
}

// ── SOS: orange gradient circle, inline and larger than sibling icons ─────────
class _SosButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SosButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sz = context.sc(46);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Container(
            width: sz,
            height: sz,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kPrimaryLt, _kActive, Color(0xFFFF6A00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55FF8132),
                  blurRadius: 14,
                  spreadRadius: -2,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.shield_rounded,
              color: Colors.white,
              size: context.sc(24),
            ),
          ),
        ),
      ),
    );
  }
}
