import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/router/app_router.dart';
import 'core/theme/nimit_theme.dart';
import 'data/providers.dart';
import 'data/remote/postgrest_dream_repository.dart';
import 'data/remote/postgrest_lottery_repository.dart';
import 'data/remote/postgrest_sources_repository.dart';

/// Set via --dart-define. When enabled and configured, the sources screen
/// reads live library data from Supabase; everything else stays on mocks.
/// Tests never set these, so `flutter test` remains hermetic.
const _useRemote = bool.fromEnvironment('NIMIT_REMOTE');
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Thai glyphs ship as bundled assets (assets/google_fonts/); never fetch
  // from fonts.gstatic.com at runtime. An all-Thai UI rendering fallback
  // glyphs on a blocked or offline network is a total failure, not a
  // degradation.
  GoogleFonts.config.allowRuntimeFetching = false;
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        if (_useRemote && _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty) ...[
          sourcesRepositoryProvider.overrideWithValue(
            PostgrestSourcesRepository(
              baseUrl: _supabaseUrl,
              anonKey: _supabaseAnonKey,
            ),
          ),
          // The core loop: เล่าความฝัน → real analysis from the live library.
          dreamRepositoryProvider.overrideWithValue(
            PostgrestDreamRepository(
              baseUrl: _supabaseUrl,
              anonKey: _supabaseAnonKey,
            ),
          ),
          // ตรวจหวย: official GLO results, ingested server-side. Ticket
          // matching stays on-device, so no number leaves the phone.
          lotteryRepositoryProvider.overrideWithValue(
            PostgrestLotteryRepository(
              baseUrl: _supabaseUrl,
              anonKey: _supabaseAnonKey,
            ),
          ),
        ],
      ],
      child: const NimitApp(),
    ),
  );
}

class NimitApp extends StatelessWidget {
  const NimitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'นิมิต',
      debugShowCheckedModeBanner: false,
      theme: buildNimitTheme(),
      routerConfig: appRouter,
      locale: const Locale('th'),
      supportedLocales: const [Locale('th'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
