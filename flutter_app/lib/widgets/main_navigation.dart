import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../core/theme/app_light_theme.dart';
import '../screens/explore/explore_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/sos/sos_screen.dart';
import '../screens/space/space_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  static const double _navBarHeight = 35;
  static const double _sosSize = 65;
  static const double _sosLift = 0.3;

  int _index = 0;

  final ValueNotifier<int> _tabIndexNotifier = ValueNotifier(0);
  final ValueNotifier<bool> _navVisible = ValueNotifier(true);

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
      const SpaceScreen(),
      ProfileScreen(tabIndexNotifier: _tabIndexNotifier),
    ];
  }

  void _onTabTap(int index) {
    setState(() => _index = index);
    _tabIndexNotifier.value = index;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBody: true,
      body: _screens[_index],

      bottomNavigationBar: ValueListenableBuilder<bool>(
        valueListenable: _navVisible,
        builder: (context, visible, child) {
          return AnimatedSlide(
            duration: const Duration(milliseconds: 250),
            offset: visible ? Offset.zero : const Offset(0, 1.6),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: visible ? 1 : 0,
              child: child,
            ),
          );
        },

        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 0, 26, 10),
          child: SizedBox(
            height: _navBarHeight + (_sosSize * _sosLift) + 20,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [

                /// Glass Background
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                    child: Container(
                      height: _navBarHeight + 20,
                      decoration: BoxDecoration(
                        color: scheme.surface.withValues(alpha: 0.9),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.shadow.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                /// Navigation Items
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: SafeArea(
                    top: false,
                    bottom: false,
                    child: SizedBox(
                      height: _navBarHeight + 20,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          _navItem(
                            context,
                            Icons.home_outlined,
                            Icons.home,
                            "Home",
                            _index == 0,
                            () => _onTabTap(0),
                          ),

                          const SizedBox(width: 36),

                          _navItem(
                            context,
                            Icons.explore_outlined,
                            null,
                            "Explore",
                            _index == 1,
                            () => _onTabTap(1),
                          ),

                          SizedBox(width: _sosSize + 36),

                          _navItem(
                            context,
                            Icons.calendar_month_outlined,
                            null,
                            "Spaces",
                            _index == 3,
                            () => _onTabTap(3),
                          ),

                          const SizedBox(width: 36),

                          _navItem(
                            context,
                            Icons.person_outline,
                            null,
                            "Profile",
                            _index == 4,
                            () => _onTabTap(4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                /// Floating SARAN Logo Button
Positioned(
  bottom: 8,
  child: GestureDetector(
    onTap: () => _onTabTap(2),
    child: ClipOval(
      child: Container(
        width: _sosSize,
        height: _sosSize,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Image.asset(
          "assets/images/SARAN Logo New.png",
          fit: BoxFit.cover,
        ),
      ),
    ),
  ),
),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    IconData icon,
    IconData? activeIcon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isActive ? colorScheme.primary : colorScheme.onSurfaceVariant;

    final displayIcon = isActive && activeIcon != null ? activeIcon : icon;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(displayIcon, size: 24, color: color),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
