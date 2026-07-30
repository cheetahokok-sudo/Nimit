import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/nimit_app_bar.dart';

/// 5-tab shell: หน้าแรก • คลังตำรา • ความฝัน • ตรวจหวย • แหล่งอ้างอิง
///
/// WHY THESE FIVE, AND NOT THE PREVIOUS FIVE. The board's original bar read
/// หน้าแรก • ความฝัน • กระแส • ดวง • ตรวจหวย, and App Store review rejected
/// 1.0.0 (10) under guideline 4.3(b) — Design: Spam — on the grounds that the
/// app "primarily features astrology, horoscopes, palm reading, fortune telling
/// or zodiac reports". Read against that bar, the finding was fair: two of the
/// five labels named a saturated category outright, and the one thing that
/// genuinely distinguishes นิมิต — a corpus where every reading carries a tier
/// badge, a citation and its original ตำรา text — was not in the bar at all. It
/// sat two taps deep behind an app-bar icon.
///
/// So the bar now leads with the corpus. คลังตำรา and แหล่งอ้างอิง are
/// destinations rather than footnotes, ตรวจหวย keeps its place because checking
/// published สลากกินแบ่ง results is a utility and not a prediction, and
/// ความฝัน stays because looking a symbol up in a cited ตำรา is what this app
/// is for.
///
/// NOTHING WAS DELETED. ปฏิทินจันทรคติ (formerly ดวง) and กระแสปีนี้ are still
/// in the app, reached from หน้าแรก as routes outside this shell. They are no
/// longer primary surfaces, which is the whole of the change: the claim the
/// product page and the tab bar make about what the app IS.
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
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'คลังตำรา',
          ),
          NavigationDestination(
            icon: Icon(Icons.nightlight_outlined),
            selectedIcon: Icon(Icons.nightlight),
            label: 'ความฝัน',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'ตรวจหวย',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'แหล่งอ้างอิง',
          ),
        ],
      ),
    );
  }
}
