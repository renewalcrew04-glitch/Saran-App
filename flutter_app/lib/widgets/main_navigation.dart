import 'dart:ui';

import 'package:flutter/material.dart';

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
  static const double _sosSize = 60;
  static const double _sosLift = 0.3;

  int _index = 0;
  final ValueNotifier<int> _tabIndexNotifier = ValueNotifier(0);
  late final List<Widget> _screens;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      extendBody: true,
      body: _screens[_index],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(40, 0, 40, 10),
        child: SizedBox(
          height: _navBarHeight + (_sosSize * _sosLift) + 20,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
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
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: SizedBox(
                    height: _navBarHeight + 20,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(child: Center(child: _navItem(context, Icons.home_outlined, Icons.home, "Home", _index == 0, () => _onTabTap(0)))),
                            Expanded(child: Center(child: _navItem(context, Icons.explore_outlined, null, "Explore", _index == 1, () => _onTabTap(1)))),
                            SizedBox(width: _sosSize),
                            Expanded(child: Center(child: _navItem(context, Icons.calendar_month_outlined, null, "Spaces", _index == 3, () => _onTabTap(3)))),
                            Expanded(child: Center(child: _navItem(context, Icons.person_outline, null, "Profile", _index == 4, () => _onTabTap(4)))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
              bottom: 8,
              child: GestureDetector(
                onTap: () => _onTabTap(2),
                child: Container(
                  width: _sosSize,
                  height: _sosSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppLightTheme.sos,
                    boxShadow: [
                      BoxShadow(
                        color: AppLightTheme.sos.withValues(alpha: 0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'S',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const ExploreScreen(),
      const SosScreen(),
      const SpaceScreen(),
      ProfileScreen(tabIndexNotifier: _tabIndexNotifier),
    ];
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
    final showIcon = isActive && activeIcon != null ? activeIcon : icon;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(showIcon, size: 22, color: color),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _onTabTap(int index) {
    setState(() => _index = index);
    _tabIndexNotifier.value = index;
  }
}
