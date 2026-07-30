import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/dream/dream_entry_screen.dart';
import '../../features/dream/dream_result_screen.dart';
import '../../features/fortune/fortune_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/library/library_search_screen.dart';
import '../../features/library/symbol_story_screen.dart';
import '../../features/lottery/lottery_history_screen.dart';
import '../../features/lottery/lottery_me_screen.dart';
import '../../features/lottery/lottery_prizes_screen.dart';
import '../../features/lottery/lottery_screen.dart';
import '../../features/lottery/lottery_stats_screen.dart';
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
        // คลังตำรา is tab 2 rather than a link two taps deep behind an app-bar
        // icon. It is the app's differentiator — a corpus where every reading
        // carries a tier badge, a citation and its original text — and burying
        // it is what let review characterise 1.0.0 (10) as one more fortune app
        // under guideline 4.3(b). See AppShell for the full account.
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/library',
            builder: (context, state) => const LibrarySearchScreen(),
            routes: [
              GoRoute(
                path: 'symbol/:slug',
                builder: (context, state) => SymbolStoryScreen(
                    slug: state.pathParameters['slug'] ?? ''),
              ),
            ],
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
            path: '/lottery',
            builder: (context, state) => const LotteryScreen(),
            // Nested so they render inside the shell: the bottom navigation
            // and app bar persist, matching how /dream/result behaves. These
            // exist to keep statistics, history and the prize table from
            // pushing the draw-day answer below the fold.
            routes: [
              GoRoute(
                path: 'stats',
                builder: (context, state) => const LotteryStatsScreen(),
              ),
              GoRoute(
                path: 'me',
                builder: (context, state) => const LotteryMeScreen(),
              ),
              GoRoute(
                path: 'history',
                builder: (context, state) => const LotteryHistoryScreen(),
              ),
              GoRoute(
                path: 'prizes',
                builder: (context, state) => const LotteryPrizesScreen(),
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/sources',
            builder: (context, state) => const SourcesScreen(),
          ),
        ]),
      ],
    ),

    // ── Kept, but no longer primary surfaces ────────────────────────────────
    //
    // ปฏิทินจันทรคติ (the screen that was ดวง) and กระแสปีนี้ live outside the
    // shell, reached from หน้าแรก. Both are real features and neither was
    // deleted; what changed is that the tab bar no longer advertises them as
    // what the app is. See AppShell for why that distinction decided a 4.3(b)
    // rejection.
    //
    // Outside the shell nothing supplies a Scaffold, so each wraps its own —
    // the same pattern the library's symbol route has always used.
    GoRoute(
      path: '/almanac',
      builder: (context, state) => const Scaffold(
        body: SafeArea(child: FortuneScreen()),
      ),
    ),
    GoRoute(
      path: '/trends',
      builder: (context, state) => const Scaffold(
        body: SafeArea(child: TrendsScreen()),
      ),
      routes: [
        GoRoute(
          path: 'symbol/:slug',
          builder: (context, state) => Scaffold(
            body: SafeArea(
              child:
                  SymbolStoryScreen(slug: state.pathParameters['slug'] ?? ''),
            ),
          ),
        ),
      ],
    ),
  ],
);
