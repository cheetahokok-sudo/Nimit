import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/nimit_app_bar.dart';

/// 5-tab shell from the UI board:
/// หน้าแรก • ความฝัน • กระแส • ดวง • ตรวจหวย
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NimitAppBar(),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'หน้าแรก',
          ),
          NavigationDestination(
            icon: Icon(Icons.nightlight_outlined),
            selectedIcon: Icon(Icons.nightlight),
            label: 'ความฝัน',
          ),
          NavigationDestination(
            icon: Icon(Icons.trending_up),
            label: 'กระแส',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'ดวง',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'ตรวจหวย',
          ),
        ],
      ),
    );
  }
}
