import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local/local_repositories.dart';
import 'mock/mock_repositories.dart';
import 'models/dream.dart';
import 'models/fortune.dart';
import 'models/lottery.dart';
import 'models/source.dart';
import 'models/trends.dart';
import 'repositories/repositories.dart';

/// Overridden in main() with the real instance before runApp.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in main()'),
);

// ---- Repository providers (swap these overrides for Supabase later) ----

final dreamRepositoryProvider =
    Provider<DreamRepository>((ref) => MockDreamRepository());

final trendsRepositoryProvider =
    Provider<TrendsRepository>((ref) => MockTrendsRepository());

final fortuneRepositoryProvider =
    Provider<FortuneRepository>((ref) => MockFortuneRepository());

final lotteryRepositoryProvider =
    Provider<LotteryRepository>((ref) => MockLotteryRepository());

final sourcesRepositoryProvider =
    Provider<SourcesRepository>((ref) => MockSourcesRepository());

final journalRepositoryProvider = Provider<JournalRepository>(
  (ref) => LocalJournalRepository(ref.watch(sharedPreferencesProvider)),
);

final savedTicketsRepositoryProvider = Provider<SavedTicketsRepository>(
  (ref) => LocalSavedTicketsRepository(ref.watch(sharedPreferencesProvider)),
);

final budgetRepositoryProvider = Provider<BudgetRepository>(
  (ref) => LocalBudgetRepository(ref.watch(sharedPreferencesProvider)),
);

// ---- Read-only data ----

final todaysNumbersProvider = FutureProvider<List<String>>(
  (ref) => ref.watch(dreamRepositoryProvider).todaysNumbers(),
);

class TrendsRegionNotifier extends Notifier<String> {
  @override
  String build() => 'ทั่วประเทศไทย';

  void select(String regionTh) => state = regionTh;
}

final trendsRegionProvider =
    NotifierProvider<TrendsRegionNotifier, String>(TrendsRegionNotifier.new);

final trendsProvider = FutureProvider<TrendsData>(
  (ref) => ref
      .watch(trendsRepositoryProvider)
      .fetch(ref.watch(trendsRegionProvider)),
);

final fortuneProvider = FutureProvider<FortuneData>(
  (ref) => ref.watch(fortuneRepositoryProvider).fetch(),
);

final currentDrawProvider = FutureProvider<DrawInfo>(
  (ref) => ref.watch(lotteryRepositoryProvider).currentDraw(),
);

final sourceTiersProvider = FutureProvider<List<SourceTier>>(
  (ref) => ref.watch(sourcesRepositoryProvider).tiers(),
);

final sourceLibraryCountProvider = FutureProvider<int>(
  (ref) => ref.watch(sourcesRepositoryProvider).libraryCount(),
);

// ---- Current dream session ----

/// Everything belonging to the dream currently being analyzed.
///
/// This exists because of a data-loss bug: the analysis used to travel to the
/// result screen only as a go_router `extra`, so the ORIGINAL dream text,
/// feeling and time-of-night never arrived at the save path at all — the
/// journal stored the headline as the "dream" and dropped the analysis
/// snapshot entirely, quietly destroying the only user-generated data the app
/// collects. Holding the whole session in a provider fixes the save path and
/// also survives tab switches and the home-screen route to the share card,
/// where `extra` does not.
class DreamSession {
  const DreamSession({
    required this.text,
    required this.analysis,
    this.feelingTh,
    this.timeOfNightTh,
  });

  final String text;
  final DreamAnalysis analysis;
  final String? feelingTh;
  final String? timeOfNightTh;
}

class DreamSessionNotifier extends Notifier<DreamSession?> {
  @override
  DreamSession? build() => null;

  void start(DreamSession session) => state = session;
  void clear() => state = null;
}

final dreamSessionProvider =
    NotifierProvider<DreamSessionNotifier, DreamSession?>(
        DreamSessionNotifier.new);

// ---- Persisted user state ----

class JournalNotifier extends AsyncNotifier<List<DreamEntry>> {
  @override
  Future<List<DreamEntry>> build() =>
      ref.watch(journalRepositoryProvider).all();

  Future<void> save(DreamEntry entry) async {
    await ref.read(journalRepositoryProvider).save(entry);
    ref.invalidateSelf();
  }

  Future<void> remove(String id) async {
    await ref.read(journalRepositoryProvider).remove(id);
    ref.invalidateSelf();
  }
}

final journalProvider =
    AsyncNotifierProvider<JournalNotifier, List<DreamEntry>>(
        JournalNotifier.new);

class SavedTicketsNotifier extends AsyncNotifier<List<SavedTicket>> {
  @override
  Future<List<SavedTicket>> build() =>
      ref.watch(savedTicketsRepositoryProvider).all();

  Future<void> save(String number) async {
    await ref
        .read(savedTicketsRepositoryProvider)
        .save(SavedTicket(number: number, savedAt: DateTime.now()));
    ref.invalidateSelf();
  }

  Future<void> remove(String number) async {
    await ref.read(savedTicketsRepositoryProvider).remove(number);
    ref.invalidateSelf();
  }
}

final savedTicketsProvider =
    AsyncNotifierProvider<SavedTicketsNotifier, List<SavedTicket>>(
        SavedTicketsNotifier.new);

class BudgetNotifier extends AsyncNotifier<BudgetState> {
  @override
  Future<BudgetState> build() => ref.watch(budgetRepositoryProvider).load();

  Future<void> addSpend(int amount) async {
    final current = await future;
    final next = current.copyWith(spent: current.spent + amount);
    await ref.read(budgetRepositoryProvider).update(next);
    ref.invalidateSelf();
  }

  Future<void> setLimit(int limit) async {
    final current = await future;
    final next = current.copyWith(limit: limit);
    await ref.read(budgetRepositoryProvider).update(next);
    ref.invalidateSelf();
  }

  Future<void> resetSpent() async {
    final current = await future;
    await ref.read(budgetRepositoryProvider).update(current.copyWith(spent: 0));
    ref.invalidateSelf();
  }
}

final budgetProvider =
    AsyncNotifierProvider<BudgetNotifier, BudgetState>(BudgetNotifier.new);
