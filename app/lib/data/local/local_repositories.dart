import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/dream.dart';
import '../models/lottery.dart';
import '../repositories/repositories.dart';

/// On-device persistence via shared_preferences (JSON lists).
/// Works on Android/iOS/Web; swap for Supabase later behind the same
/// repository interfaces.

class LocalJournalRepository implements JournalRepository {
  LocalJournalRepository(this._prefs);

  static const _key = 'nimit.journal.v1';
  final SharedPreferences _prefs;

  @override
  Future<List<DreamEntry>> all() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List<dynamic>)
        .map((e) => DreamEntry.fromJson(e as Map<String, dynamic>))
        .toList();
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
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => SavedTicket.fromJson(e as Map<String, dynamic>))
        .toList();
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

class LocalBudgetRepository implements BudgetRepository {
  LocalBudgetRepository(this._prefs);

  static const _key = 'nimit.budget.v1';
  final SharedPreferences _prefs;

  @override
  Future<BudgetState> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return const BudgetState(spent: 160, limit: 500);
    return BudgetState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> update(BudgetState state) async {
    await _prefs.setString(_key, jsonEncode(state.toJson()));
  }
}
