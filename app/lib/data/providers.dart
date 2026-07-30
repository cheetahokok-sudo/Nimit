import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local/local_repositories.dart';
import 'lottery_checker.dart';
import 'mock/mock_repositories.dart';
import 'models/dream.dart';
import 'models/fortune.dart';
import 'models/library.dart';
import 'models/lottery.dart';
import 'models/source.dart';
import 'repositories/repositories.dart';

/// Overridden in main() with the real instance before runApp.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in main()'),
);

/// Retry policy for every provider in the app. Passed to the root
/// ProviderScope, and to any test that needs to see a failure the way a user
/// would.
///
/// Riverpod 3 retries a failed provider ten times with exponential backoff,
/// and holds `AsyncLoading` the whole way — so a `.when(error:)` branch is
/// unreachable for roughly forty seconds. On a Thai mobile network a dropped
/// request is the ordinary case, and forty seconds of spinner is not a slow
/// screen, it is a broken one that never says so. Two quick retries absorb a
/// genuine blip; after about a second the screen tells the truth instead.
Duration? nimitRetry(int retryCount, Object error) => retryCount >= 2
    ? null
    : Duration(milliseconds: 300 * (retryCount + 1));

// ---- Repository providers (swap these overrides for Supabase later) ----

final dreamRepositoryProvider =
    Provider<DreamRepository>((ref) => MockDreamRepository());

final birthProfileRepositoryProvider = Provider<BirthProfileRepository>(
  (ref) => LocalBirthProfileRepository(ref.watch(sharedPreferencesProvider)),
);

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

final watchedNumbersRepositoryProvider = Provider<WatchedNumbersRepository>(
  (ref) => LocalWatchedNumbersRepository(ref.watch(sharedPreferencesProvider)),
);

final budgetRepositoryProvider = Provider<BudgetRepository>(
  (ref) => LocalBudgetRepository(ref.watch(sharedPreferencesProvider)),
);

// ---- Read-only data ----

/// เลขนิมิตวันนี้ — derived from the user's OWN saved dreams.
///
/// This used to call `dreamRepository.todaysNumbers()`, and the remote
/// implementation returned four hardcoded values ('16','29','68','269') under a
/// heading that reads as tonight's omen numbers, with a caption promising they
/// came from the user's saved symbols. In a lottery-adjacent app whose entire
/// claim is verifiable sourcing, that was the worst thing in the product: a
/// user could reasonably have gone and bought them.
///
/// The journal is local, so no repository could ever answer this honestly.
/// Now it is computed here from real entries, and when there are none the UI
/// shows an empty state rather than inventing something to fill the space.
final todaysNumbersProvider = FutureProvider<List<String>>((ref) async {
  final entries = await ref.watch(journalProvider.future);
  final cutoff = DateTime.now().subtract(const Duration(days: 7));

  final seen = <String>{};
  for (final e in entries) {
    if (e.createdAt.isBefore(cutoff)) continue;
    for (final n in e.numbers) {
      if (n.trim().isEmpty) continue;
      seen.add(n.trim());
      if (seen.length >= 6) return seen.toList();
    }
  }
  return seen.toList();
});

final currentDrawProvider = FutureProvider<DrawInfo>(
  (ref) => ref.watch(lotteryRepositoryProvider).currentDraw(),
);

final latestDrawProvider = FutureProvider<DrawResult>(
  (ref) => ref.watch(lotteryRepositoryProvider).latestDraw(),
);

final recentDrawsProvider = FutureProvider<List<DrawResult>>(
  (ref) => ref.watch(lotteryRepositoryProvider).recentDraws(),
);

final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) => MockLibraryRepository(),
);

/// One symbol, everything known about it. Family-keyed by slug so opening
/// the same symbol twice does not refetch.
/// ทักษา reading for a weekday (1=Mon..7=Sun).
///
/// Family-keyed on the weekday alone. The birth date never leaves the device;
/// the only thing that travels is which of seven days it fell on.
final taksaProvider = FutureProvider.family<TaksaReading, int>(
  (ref, weekday) => ref.watch(libraryRepositoryProvider).taksa(weekday),
);

/// วงราศีตามอายุ for an age in completed years.
///
/// Family-keyed on the age alone. Like ทักษา, the birth date never leaves the
/// device — and unlike most readings of this kind, the user's sex is not sent
/// either, because the app does not hold it. Both directions come back.
final ageWheelProvider = FutureProvider.family<AgeWheelReading, int>(
  (ref, age) => ref.watch(libraryRepositoryProvider).ageWheel(age),
);

/// ปีนักษัตร for a zodiac index and lunar month.
///
/// Keyed on a record so the two arguments stay named at the call site —
/// `(index: 4, lunarMonth: 7)` cannot be transposed the way a positional pair
/// can, and transposing them here would silently return the wrong year's
/// reading rather than failing.
final zodiacYearProvider =
    FutureProvider.family<ZodiacYearReading, ({int index, int? lunarMonth})>(
  (ref, key) => ref
      .watch(libraryRepositoryProvider)
      .zodiacYear(key.index, key.lunarMonth),
);

final symbolStoryProvider = FutureProvider.family<SymbolStory, String>(
  (ref, slug) => ref.watch(libraryRepositoryProvider).story(slug),
);

/// คลังตำรา search, family-keyed on the trimmed query so retyping the same
/// word does not refetch. The screen never asks below two characters — the
/// server would reject it, and the guard belongs before the round trip.
final librarySearchProvider =
    FutureProvider.family<List<SymbolSearchResult>, String>(
  (ref, query) => ref.watch(libraryRepositoryProvider).search(query),
);

/// กระแสปีนี้ — real draws joined to ตำรา meaning.
final yearTrendsProvider = FutureProvider<YearTrends>(
  (ref) => ref.watch(lotteryRepositoryProvider).yearTrends(),
);

final digitStatsProvider = FutureProvider<DigitStats>(
  (ref) => ref.watch(lotteryRepositoryProvider).digitStats(),
);

/// Two years of draws as a light list (~6 KB). The heavy per-draw detail is
/// loaded on demand by [drawByDateProvider] when a row is expanded.
final lotteryHistoryProvider = FutureProvider<List<DrawSummary>>(
  (ref) => ref.watch(lotteryRepositoryProvider).history(),
);

final drawByDateProvider =
    FutureProvider.family<DrawResult, DateTime>((ref, date) =>
        ref.watch(lotteryRepositoryProvider).drawFor(date));

/// The user's saved numbers checked against the latest announced draw.
///
/// Composed here rather than in the widget so the matching runs once per
/// (draw, tickets) pair instead of on every rebuild. The match itself is pure
/// and local — no ticket number is sent anywhere.
final checkOutcomeProvider = FutureProvider<CheckOutcome>((ref) async {
  final draw = await ref.watch(latestDrawProvider.future);
  final tickets = await ref.watch(savedTicketsProvider.future);
  return checkAll(draw, tickets);
});

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

  /// [quantity] is how many physical tickets bear this number (ซื้อเป็นชุด).
  /// Positional [number] is kept so existing call sites compile unchanged.
  Future<void> save(String number, {int quantity = 1}) async {
    await ref.read(savedTicketsRepositoryProvider).save(SavedTicket(
          number: number,
          savedAt: DateTime.now(),
          quantity: quantity < 1 ? 1 : quantity,
        ));
    ref.invalidateSelf();
  }

  Future<void> setQuantity(String number, int quantity) async {
    final tickets = await future;
    for (final t in tickets) {
      if (t.number == number) {
        await ref
            .read(savedTicketsRepositoryProvider)
            .save(t.copyWith(quantity: quantity < 1 ? 1 : quantity));
        ref.invalidateSelf();
        return;
      }
    }
  }

  Future<void> remove(String number) async {
    await ref.read(savedTicketsRepositoryProvider).remove(number);
    ref.invalidateSelf();
  }
}

final savedTicketsProvider =
    AsyncNotifierProvider<SavedTicketsNotifier, List<SavedTicket>>(
        SavedTicketsNotifier.new);

class WatchedNumbersNotifier extends AsyncNotifier<List<WatchedNumber>> {
  @override
  Future<List<WatchedNumber>> build() =>
      ref.watch(watchedNumbersRepositoryProvider).all();

  /// Returns the number the cap pushed out, or null if nothing was dropped, so
  /// the caller can tell the user rather than lose a saved number in silence.
  Future<String?> watch(String number, {String? sourceTh}) async {
    final dropped =
        await ref.read(watchedNumbersRepositoryProvider).save(WatchedNumber(
              number: number.trim(),
              savedAt: DateTime.now(),
              sourceTh: sourceTh,
            ));
    ref.invalidateSelf();
    return dropped;
  }

  Future<void> remove(String number) async {
    await ref.read(watchedNumbersRepositoryProvider).remove(number);
    ref.invalidateSelf();
  }
}

final watchedNumbersProvider =
    AsyncNotifierProvider<WatchedNumbersNotifier, List<WatchedNumber>>(
        WatchedNumbersNotifier.new);

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

/// Birth month. Never leaves the device; see [BirthProfile] for why it is only
/// a month.
class BirthProfileNotifier extends AsyncNotifier<BirthProfile> {
  @override
  Future<BirthProfile> build() =>
      ref.watch(birthProfileRepositoryProvider).load();

  Future<void> setDate(DateTime date) async {
    final next = BirthProfile(date: DateTime(date.year, date.month, date.day));
    await ref.read(birthProfileRepositoryProvider).save(next);
    ref.invalidateSelf();
  }

  /// Deleting it must be as easy as setting it — the screen offers this, so a
  /// user who changes their mind is not stuck with data they no longer want on
  /// their phone. Clears the legacy month key too.
  Future<void> clear() async {
    await ref.read(birthProfileRepositoryProvider).save(const BirthProfile());
    ref.invalidateSelf();
  }
}

final birthProfileProvider =
    AsyncNotifierProvider<BirthProfileNotifier, BirthProfile>(
        BirthProfileNotifier.new);
