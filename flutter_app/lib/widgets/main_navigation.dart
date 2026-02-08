import 'package:flutter/material.dart';

import '../core/theme/app_light_theme.dart';
import '../screens/home/home_screen.dart';
import '../screens/explore/explore_screen.dart';
import '../screens/space/space_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/sos/sos_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;
  final ValueNotifier<int> _tabIndexNotifier = ValueNotifier(0);
  late final List<Widget> _screens;

  static const double _navBarHeight = 72;
  static const double _sosSize = 64; // circle diameter
  static const double _sosLift = 0.25; // 25% outside

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

  void _onTabTap(int index) {
    setState(() => _index = index);
    _tabIndexNotifier.value = index;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],

      bottomNavigationBar: SizedBox(
        height: _navBarHeight + (_sosSize * _sosLift),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Bottom bar
            Container(
              height: _navBarHeight,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _navItem(context, Icons.home_outlined, "Home", _index == 0, () => _onTabTap(0)),
                      _navItem(context, Icons.explore_outlined, "Explore", _index == 1, () => _onTabTap(1)),
                      const SizedBox(width: _sosSize), // space for SOS
                      _navItem(context, Icons.calendar_month_outlined, "Spaces", _index == 3, () => _onTabTap(3)),
                      _navItem(context, Icons.person_outline, "Profile", _index == 4, () => _onTabTap(4)),
                    ],
                  ),
                ),
              ),
            ),

            // Floating SOS button
            Positioned(
              bottom: _navBarHeight - (_sosSize * (1 - _sosLift)),
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
    );
  }

  Widget _navItem(
    BuildContext context,
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isActive ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 2),
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
}
