import '../models/dream.dart';
import '../models/fortune.dart';
import '../models/lottery.dart';
import '../models/source.dart';
import '../models/trends.dart';

/// Abstract data-access contracts. Mock implementations back the scaffold;
/// a Supabase (or other) backend can replace them via provider overrides
/// without touching UI code.

abstract interface class DreamRepository {
  Future<DreamAnalysis> analyze(
    String text, {
    String? feelingTh,
    String? timeOfNightTh,
  });

  /// Today's symbolic numbers for the home screen
  /// (derived from the user's own saved symbols — never a prediction).
  Future<List<String>> todaysNumbers();
}

abstract interface class TrendsRepository {
  Future<TrendsData> fetch(String regionTh);
}

abstract interface class FortuneRepository {
  Future<FortuneData> fetch();
}

/// Official draw results. Facts only.
///
/// There is deliberately no `check(number)` here. A repository that returned a
/// ready-made Thai sentence is exactly what produced the old screen's hardcoded
/// `ยังไม่ประกาศ` pill: the UI had no data to compute a status from, so someone
/// typed a constant that was wrong for every ticket. Matching now happens
/// on-device in `lottery_checker.dart`, which also keeps the user's numbers off
/// the network.
abstract interface class LotteryRepository {
  /// Banner state. Must succeed even when no result exists — that is the state
  /// it is most needed in.
  Future<DrawInfo> currentDraw();

  /// The latest ANNOUNCED draw, with all 173 numbers and their prize amounts.
  Future<DrawResult> latestDraw();

  /// Recent announced draws, newest first, WITH all their numbers.
  ///
  /// Heavy (~4 KB each) because it carries every winning number, so it is used
  /// only where the numbers are actually needed — matching saved tickets for
  /// personal statistics. For a browsable list use [history] instead.
  Future<List<DrawResult>> recentDraws({int limit = 12});

  /// Light list for ผลย้อนหลัง: date, รางวัลที่ 1, เลขท้าย 2 ตัว.
  Future<List<DrawSummary>> history({int limit = 48});

  /// Full detail for one งวด, fetched when a history row is expanded.
  Future<DrawResult> drawFor(DateTime date);

  /// Digit frequency over a window of past draws.
  Future<DigitStats> digitStats({int windowDraws = 24});
}

abstract interface class SourcesRepository {
  Future<List<SourceTier>> tiers();
  Future<int> libraryCount();
}

abstract interface class JournalRepository {
  Future<List<DreamEntry>> all();
  Future<void> save(DreamEntry entry);
  Future<void> remove(String id);
}

abstract interface class SavedTicketsRepository {
  Future<List<SavedTicket>> all();
  Future<void> save(SavedTicket ticket);
  Future<void> remove(String number);
}

abstract interface class BudgetRepository {
  Future<BudgetState> load();
  Future<void> update(BudgetState state);
}
