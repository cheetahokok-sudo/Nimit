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
            // Nested so the symbol story keeps the shell chrome, same as
            // /dream/result and the ตรวจหวย sub-routes.
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
            path: '/fortune',
            builder: (context, state) => const FortuneScreen(),
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
      ],
    ),
    GoRoute(
      path: '/sources',
      builder: (context, state) => const SourcesScreen(),
      routes: [
        GoRoute(
          path: 'library',
          builder: (context, state) => const LibrarySearchScreen(),
          routes: [
            // The story screen normally lives inside the shell (under
            // /trends); here it is reached from a search, so it keeps the
            // search's back stack instead — popping returns to the results,
            // not to a tab the user never visited. Outside the shell nothing
            // provides a Scaffold, hence the wrapper.
            GoRoute(
              path: 'symbol/:slug',
              builder: (context, state) => Scaffold(
                body: SafeArea(
                  child: SymbolStoryScreen(
                      slug: state.pathParameters['slug'] ?? ''),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
