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

    final initial = await repo.load();
    expect(initial.spent, 160);
    expect(initial.limit, 500);

    await repo.update(const BudgetState(spent: 240, limit: 600));
    final loaded = await repo.load();
    expect(loaded.spent, 240);
    expect(loaded.limit, 600);
    expect(loaded.ratio, closeTo(0.4, 0.001));
  });
}
