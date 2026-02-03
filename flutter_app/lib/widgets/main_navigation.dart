import 'package:flutter/material.dart';

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

  List<Widget> get _screens => [
    const HomeScreen(),
    const ExploreScreen(),
    const SosScreen(),
    const SpaceScreen(),
    ProfileScreen(tabIndexNotifier: _tabIndexNotifier),
  ];

  void _onTabTap(int index) {
    setState(() => _index = index);
    _tabIndexNotifier.value = index;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],

      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                icon: Icons.home_outlined,
                label: "Home",
                isActive: _index == 0,
                onTap: () => _onTabTap(0),
              ),
              _navItem(
                icon: Icons.explore_outlined,
                label: "Explore",
                isActive: _index == 1,
                onTap: () => _onTabTap(1),
              ),
              // SOS center button – red
              GestureDetector(
                onTap: () => _onTabTap(2),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Text(
                    "SOS",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              _navItem(
                icon: Icons.calendar_month_outlined,
                label: "Spaces",
                isActive: _index == 3,
                onTap: () => _onTabTap(3),
              ),
              _navItem(
                icon: Icons.person_outline,
                label: "Profile",
                isActive: _index == 4,
                onTap: () => _onTabTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              size: 22,
              color: isActive ? Colors.black : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.black : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
