import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/dream.dart';
import '../models/fortune.dart';
import '../models/lottery.dart';
import '../repositories/repositories.dart';

/// On-device persistence via shared_preferences (JSON lists).
/// Works on Android/iOS/Web; swap for Supabase later behind the same
/// repository interfaces.
///
/// Corrupt data policy: a payload that fails to decode is treated as absent
/// rather than thrown. Stored JSON can be damaged outside our control
/// (interrupted writes, users editing web localStorage, migration bugs), and
/// an exception out of `all()` would permanently brick that screen — every
/// load re-throws until the user clears app data. Losing a broken cache is
/// the better failure. Entries that individually fail to parse are skipped so
/// one bad record does not take the rest of the journal with it.

List<T> _decodeListOrEmpty<T>(
    String? raw, T Function(Map<String, dynamic>) fromJson) {
  if (raw == null) return [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    final out = <T>[];
    for (final e in decoded) {
      try {
        out.add(fromJson(e as Map<String, dynamic>));
      } catch (_) {
        // Skip the damaged entry, keep the rest.
      }
    }
    return out;
  } catch (_) {
    return [];
  }
}

class LocalJournalRepository implements JournalRepository {
  LocalJournalRepository(this._prefs);

  static const _key = 'nimit.journal.v1';
  final SharedPreferences _prefs;

  @override
  Future<List<DreamEntry>> all() async {
    final list = _decodeListOrEmpty(_prefs.getString(_key), DreamEntry.fromJson);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<void> save(DreamEntry entry) async {
    final entries = await all();
    entries.removeWhere((e) => e.id == entry.id);
    entries.insert(0, entry);
    await _prefs.setString(
        _key, jsonEncode([for (final e in entries) e.toJson()]));
  }

  @override
  Future<void> remove(String id) async {
    final entries = await all();
    entries.removeWhere((e) => e.id == id);
    await _prefs.setString(
        _key, jsonEncode([for (final e in entries) e.toJson()]));
  }
}

class LocalSavedTicketsRepository implements SavedTicketsRepository {
  LocalSavedTicketsRepository(this._prefs);

  static const _key = 'nimit.tickets.v1';
  final SharedPreferences _prefs;

  @override
  Future<List<SavedTicket>> all() async {
    return _decodeListOrEmpty(_prefs.getString(_key), SavedTicket.fromJson);
  }

  @override
  Future<void> save(SavedTicket ticket) async {
    final tickets = await all();
    tickets.removeWhere((t) => t.number == ticket.number);
    tickets.insert(0, ticket);
    await _prefs.setString(
        _key, jsonEncode([for (final t in tickets) t.toJson()]));
  }

  @override
  Future<void> remove(String number) async {
    final tickets = await all();
    tickets.removeWhere((t) => t.number == number);
    await _prefs.setString(
        _key, jsonEncode([for (final t in tickets) t.toJson()]));
  }
}

class LocalWatchedNumbersRepository implements WatchedNumbersRepository {
  LocalWatchedNumbersRepository(this._prefs);

  static const _key = 'nimit.watched.v1';
  final SharedPreferences _prefs;

  /// Enough to cover a few dreams without the ตรวจหวย screen turning into a
  /// wall of numbers, which is the shape a เลขเด็ด tip sheet takes.
  static const _max = WatchedNumbersRepository.maxWatched;

  @override
  Future<List<WatchedNumber>> all() async {
    return _decodeListOrEmpty(_prefs.getString(_key), WatchedNumber.fromJson);
  }

  @override
  Future<String?> save(WatchedNumber number) async {
    final list = await all();
    list.removeWhere((n) => n.number == number.number);
    list.insert(0, number);

    // Re-saving a number already on the list is a move to the top, not an
    // addition, so the eviction check has to come after the removeWhere above or
    // it reports a drop that never happened.
    String? dropped;
    if (list.length > _max) {
      dropped = list[_max].number;
      list.removeRange(_max, list.length);
    }

    await _prefs.setString(
        _key, jsonEncode([for (final n in list) n.toJson()]));
    return dropped;
  }

  @override
  Future<void> remove(String number) async {
    final list = await all();
    list.removeWhere((n) => n.number == number);
    await _prefs.setString(
        _key, jsonEncode([for (final n in list) n.toJson()]));
  }
}

class LocalBudgetRepository implements BudgetRepository {
  LocalBudgetRepository(this._prefs);

  static const _key = 'nimit.budget.v1';
  final SharedPreferences _prefs;

  // A fresh install has spent NOTHING. The previous default of ฿160 was a
  // demo figure from the UI board leaking into reality — for a
  // responsible-use feature, showing money as already spent is a factual
  // mis-statement to a brand-new user.
  static const _fresh = BudgetState(spent: 0, limit: 500);

  @override
  Future<BudgetState> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return _fresh;
    try {
      return BudgetState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Damaged budget payload: fall back to defaults rather than bricking
      // the lottery screen. The user re-enters two numbers; nothing else lost.
      return _fresh;
    }
  }

  @override
  Future<void> update(BudgetState state) async {
    await _prefs.setString(_key, jsonEncode(state.toJson()));
  }
}

/// Birth month, on this device and nowhere else.
///
/// Deliberately its own tiny repository rather than a field on some larger
/// settings blob: keeping it separate makes it obvious in a privacy review
/// exactly what birth information the app holds, and a `grep` for this key
/// finds every place it is touched.
class LocalBirthProfileRepository implements BirthProfileRepository {
  LocalBirthProfileRepository(this._prefs);

  /// The current key. Named for what it now holds — a date, not a month.
  static const _key = 'nimit.birth.v2';

  /// The month-only key this replaced. Still READ, never written.
  ///
  /// A new key normally orphans a user's data, which is why the saved-tickets
  /// key was deliberately never bumped. Here the field genuinely changed
  /// meaning, so the key follows it and the old one is migrated on read
  /// instead. What must not happen is a month the user typed silently
  /// vanishing because the payload shape moved on.
  static const _legacyKey = 'nimit.birthmonth.v1';

  final SharedPreferences _prefs;

  @override
  Future<BirthProfile> load() async {
    final profile = _decode(_prefs.getString(_key));
    if (!profile.isEmpty) return profile;
    // Nothing under the new key: fall back to the month-only one. The result
    // reports needsUpgrade, so the screen asks for the rest of the date rather
    // than pretending it never knew.
    return _decode(_prefs.getString(_legacyKey));
  }

  BirthProfile _decode(String? raw) {
    if (raw == null) return const BirthProfile();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return const BirthProfile();
      return BirthProfile.fromJson(decoded);
    } catch (_) {
      // Same policy as the journal and budget: corrupt storage reads as empty
      // rather than throwing, because a throw here would also break every
      // future save.
      return const BirthProfile();
    }
  }

  @override
  Future<void> save(BirthProfile profile) async {
    if (profile.isEmpty) {
      await _clearAll();
      return;
    }
    await _prefs.setString(_key, jsonEncode(profile.toJson()));
    // A completed date supersedes the legacy month; leaving it behind would
    // mean birth data lingering under a key nothing reads any more.
    if (profile.isComplete) await _prefs.remove(_legacyKey);
  }

  /// Both keys, because the screen promises "ลบแล้วหายทันที" and that has to be
  /// true of the disk. Removing only the current key would leave a month
  /// behind that the next load would happily resurrect.
  Future<void> _clearAll() async {
    await _prefs.remove(_key);
    await _prefs.remove(_legacyKey);
  }
}
