import 'package:go_router/go_router.dart';

import '../../features/dream/dream_entry_screen.dart';
import '../../features/dream/dream_result_screen.dart';
import '../../features/fortune/fortune_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/lottery/lottery_screen.dart';
import '../../features/share_card/share_card_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/sources/sources_screen.dart';
import '../../features/trends/trends_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/dream',
            builder: (context, state) => const DreamEntryScreen(),
            routes: [
              // Dream state travels via dreamSessionProvider, not `extra`:
              // extras die on tab switches and web refreshes, which is how the
              // save path once lost the user's actual dream text.
              GoRoute(
                path: 'result',
                builder: (context, state) => const DreamResultScreen(),
              ),
              GoRoute(
                path: 'share',
                builder: (context, state) => const ShareCardScreen(),
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/trends',
            builder: (context, state) => const TrendsScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/fortune',
            builder: (context, state) => const FortuneScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/lottery',
            builder: (context, state) => const LotteryScreen(),
          ),
        ]),
      ],
    ),
    GoRoute(
      path: '/sources',
      builder: (context, state) => const SourcesScreen(),
    ),
  ],
);
