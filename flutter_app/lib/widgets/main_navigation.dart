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

      bottomNavigationBar: Container(
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
              _navItem(context, Icons.home_outlined, "Home", _index == 0, () => _onTabTap(0)),
              _navItem(context, Icons.explore_outlined, "Explore", _index == 1, () => _onTabTap(1)),
              GestureDetector(
                onTap: () => _onTabTap(2),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppLightTheme.sos,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppLightTheme.sos.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    "SOS",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              _navItem(context, Icons.calendar_month_outlined, "Spaces", _index == 3, () => _onTabTap(3)),
              _navItem(context, Icons.person_outline, "Profile", _index == 4, () => _onTabTap(4)),
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
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isActive ? colorScheme.primary : colorScheme.onSurfaceVariant;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
