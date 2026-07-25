import 'package:go_router/go_router.dart';

import '../../data/models/dream.dart';
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
              GoRoute(
                path: 'result',
                builder: (context, state) => DreamResultScreen(
                  analysis: state.extra as DreamAnalysis?,
                ),
              ),
              GoRoute(
                path: 'share',
                builder: (context, state) => ShareCardScreen(
                  analysis: state.extra as DreamAnalysis?,
                ),
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
