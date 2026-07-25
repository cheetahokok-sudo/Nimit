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

abstract interface class LotteryRepository {
  Future<DrawInfo> currentDraw();

  /// Returns a Thai status message for the checked [number].
  Future<String> check(String number);
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
