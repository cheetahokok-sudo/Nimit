import 'package:flutter_test/flutter_test.dart';
import 'package:nimit/data/local/local_repositories.dart';
import 'package:nimit/data/models/dream.dart';
import 'package:nimit/data/models/lottery.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('journal saves, orders newest-first, and removes', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = LocalJournalRepository(prefs);

    final older = DreamEntry(
      id: '1',
      text: 'ฝันเห็นงูสีขาวหน้าบ้าน',
      createdAt: DateTime(2026, 7, 24),
      headlineTh: 'งูสีขาว • หน้าบ้าน',
      numbers: const ['16', '61'],
    );
    final newer = DreamEntry(
      id: '2',
      text: 'ฝันเห็นน้ำท่วม',
      createdAt: DateTime(2026, 7, 25),
      numbers: const ['29'],
    );

    await repo.save(older);
    await repo.save(newer);

    final all = await repo.all();
    expect(all.length, 2);
    expect(all.first.id, '2');
    expect(all.last.numbers, ['16', '61']);
    expect(all.last.headlineTh, 'งูสีขาว • หน้าบ้าน');

    await repo.remove('1');
    expect((await repo.all()).map((e) => e.id), ['2']);
  });

  test('saved tickets deduplicate by number', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = LocalSavedTicketsRepository(prefs);

    await repo.save(SavedTicket(number: '269161', savedAt: DateTime(2026, 7, 25)));
    await repo.save(SavedTicket(number: '269161', savedAt: DateTime(2026, 7, 25)));
    await repo.save(SavedTicket(number: '123456', savedAt: DateTime(2026, 7, 25)));

    final all = await repo.all();
    expect(all.length, 2);
    expect(all.first.number, '123456');

    await repo.remove('269161');
    expect((await repo.all()).map((t) => t.number), ['123456']);
  });

  test('budget defaults then persists updates', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = LocalBudgetRepository(prefs);

    // A fresh install has spent nothing. The old default of 160 was demo data
    // leaking into a responsible-use feature.
    final initial = await repo.load();
    expect(initial.spent, 0);
    expect(initial.limit, 500);

    await repo.update(const BudgetState(spent: 240, limit: 600));
    final loaded = await repo.load();
    expect(loaded.spent, 240);
    expect(loaded.limit, 600);
    expect(loaded.ratio, closeTo(0.4, 0.001));
  });

  group('corrupt persisted data must not brick the app', () {
    // On web, shared_preferences is localStorage — users and extensions edit
    // it, and old payloads survive redeploys. A decode exception out of all()
    // would not just blank the list: save() calls all() first, so every
    // future WRITE would also throw, permanently, until site data is cleared.

    test('journal: garbage payload reads as empty and save self-heals',
        () async {
      SharedPreferences.setMockInitialValues(
          {'nimit.journal.v1': 'not json {{{'});
      final prefs = await SharedPreferences.getInstance();
      final repo = LocalJournalRepository(prefs);

      expect(await repo.all(), isEmpty);

      // The write path must work over the corrupt blob and overwrite it.
      await repo.save(DreamEntry(
          id: 'x', text: 'ฝัน', createdAt: DateTime(2026, 7, 26)));
      expect((await repo.all()).single.id, 'x');
    });

    test('journal: one damaged entry is skipped, the rest survive', () async {
      SharedPreferences.setMockInitialValues({
        'nimit.journal.v1':
            '[{"id":"good","text":"ฝันดี","createdAt":"2026-07-25T08:00:00.000"},'
            '{"id":"bad","text":123,"createdAt":false},'
            '{"broken":true}]'
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = LocalJournalRepository(prefs);

      final entries = await repo.all();
      expect(entries.map((e) => e.id), ['good']);
    });

    test('tickets: garbage payload reads as empty', () async {
      SharedPreferences.setMockInitialValues({'nimit.tickets.v1': '"oops"'});
      final prefs = await SharedPreferences.getInstance();
      expect(await LocalSavedTicketsRepository(prefs).all(), isEmpty);
    });

    test('budget: garbage payload falls back to the fresh default', () async {
      SharedPreferences.setMockInitialValues({'nimit.budget.v1': '[1,2,3]'});
      final prefs = await SharedPreferences.getInstance();
      final budget = await LocalBudgetRepository(prefs).load();
      expect(budget.spent, 0);
      expect(budget.limit, 500);
    });
  });
}
