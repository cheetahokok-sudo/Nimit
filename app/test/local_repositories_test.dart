import 'package:flutter_test/flutter_test.dart';
import 'package:nimit/data/local/local_repositories.dart';
import 'package:nimit/data/models/dream.dart';
import 'package:nimit/data/models/fortune.dart';
import 'package:nimit/data/models/lottery.dart';
import 'package:nimit/data/repositories/repositories.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('journal saves, orders newest-first, and removes', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = LocalJournalRepository(prefs);

    final older = DreamEntry(
      id: '1',
      text: 'ฝันเห็นนกสีขาวหน้าบ้าน',
      createdAt: DateTime(2026, 7, 24),
      headlineTh: 'นกสีขาว • หน้าบ้าน',
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
    expect(all.last.headlineTh, 'นกสีขาว • หน้าบ้าน');

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

  group('adding a field must not destroy existing saved numbers', () {
    // THE FAILURE THIS GUARDS. save() reads the whole list via all(), appends,
    // and writes it back. all() uses _decodeListOrEmpty, which SKIPS entries
    // whose fromJson throws. So if a newly added field is parsed strictly, a
    // payload written by an older build loses every entry on the next save —
    // permanently, with no error anywhere. The user's numbers simply vanish.
    //
    // This is not hypothetical: `quantity` was added to SavedTicket in the
    // ตรวจหวย work, and `json['quantity'] as int` would have done exactly this.
    test('legacy entries survive a save after a new field is introduced',
        () async {
      SharedPreferences.setMockInitialValues({
        'nimit.tickets.v1': '['
            '{"number":"111111","savedAt":"2026-07-01T10:00:00.000"},'
            '{"number":"222222","savedAt":"2026-07-02T10:00:00.000"},'
            '{"number":"333333","savedAt":"2026-07-03T10:00:00.000"}]'
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = LocalSavedTicketsRepository(prefs);

      expect((await repo.all()).length, 3, reason: 'legacy payload must parse');

      await repo.save(SavedTicket(
          number: '444444', savedAt: DateTime(2026, 7, 4), quantity: 2));

      final after = await repo.all();
      expect(after.map((t) => t.number),
          containsAll(['111111', '222222', '333333', '444444']));
      expect(after.length, 4, reason: 'no legacy entry may be dropped');

      // Legacy entries default to one ticket; the new one keeps its quantity.
      for (final t in after.where((t) => t.number != '444444')) {
        expect(t.quantity, 1);
      }
      expect(after.firstWhere((t) => t.number == '444444').quantity, 2);

      // And the loss must not have been persisted either.
      final raw = prefs.getString('nimit.tickets.v1')!;
      for (final n in ['111111', '222222', '333333', '444444']) {
        expect(raw.contains(n), isTrue, reason: '$n missing from stored JSON');
      }
    });

    test('quantity persists across a reload', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = LocalSavedTicketsRepository(prefs);

      await repo.save(SavedTicket(
          number: '639214', savedAt: DateTime(2026, 7, 1), quantity: 5));

      final reloaded = await LocalSavedTicketsRepository(prefs).all();
      expect(reloaded.single.quantity, 5);
    });

    test('saving the same number again replaces it without duplicating',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = LocalSavedTicketsRepository(prefs);

      await repo.save(SavedTicket(
          number: '639214', savedAt: DateTime(2026, 7, 1), quantity: 1));
      await repo.save(SavedTicket(
          number: '639214', savedAt: DateTime(2026, 7, 2), quantity: 5));

      final all = await repo.all();
      expect(all.length, 1);
      expect(all.single.quantity, 5);
    });
  });

  group('birth date', () {
    test('starts empty, and empty is a working state', () async {
      final prefs = await SharedPreferences.getInstance();
      final p = await LocalBirthProfileRepository(prefs).load();

      expect(p.date, isNull);
      expect(p.isComplete, isFalse);
      expect(p.isEmpty, isTrue);
    });

    test('round-trips a date through storage', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = LocalBirthProfileRepository(prefs);

      await repo.save(BirthProfile(date: DateTime(1993, 7, 15)));

      final back = await LocalBirthProfileRepository(prefs).load();
      expect(back.date, DateTime(1993, 7, 15));
      expect(back.isComplete, isTrue);
    });

    test('a legacy month-only profile is migrated, not discarded', () async {
      // The month-only version of this app wrote nimit.birthmonth.v1. Users who
      // set a month before the field widened must not find it silently gone.
      SharedPreferences.setMockInitialValues(
          {'nimit.birthmonth.v1': '{"month": 7}'});
      final prefs = await SharedPreferences.getInstance();

      final p = await LocalBirthProfileRepository(prefs).load();

      expect(p.legacyMonth, 7);
      expect(p.needsUpgrade, isTrue,
          reason: 'the screen must ask for the rest of the date');
      expect(p.isComplete, isFalse,
          reason: 'a month alone cannot produce a lunar month');
    });

    test('saving a full date retires the legacy key', () async {
      SharedPreferences.setMockInitialValues(
          {'nimit.birthmonth.v1': '{"month": 7}'});
      final prefs = await SharedPreferences.getInstance();
      final repo = LocalBirthProfileRepository(prefs);

      await repo.save(BirthProfile(date: DateTime(1993, 7, 15)));

      expect(prefs.getString('nimit.birthmonth.v1'), isNull,
          reason: 'birth data must not linger under a key nothing reads');
      expect((await repo.load()).date, DateTime(1993, 7, 15));
    });

    test('clearing removes BOTH keys, not just the current one', () async {
      // The privacy card promises "ลบแล้วหายทันที". Leaving the legacy month
      // behind would let the next load resurrect it.
      SharedPreferences.setMockInitialValues(
          {'nimit.birthmonth.v1': '{"month": 3}'});
      final prefs = await SharedPreferences.getInstance();
      final repo = LocalBirthProfileRepository(prefs);

      await repo.save(BirthProfile(date: DateTime(1980, 3, 2)));
      await repo.save(const BirthProfile());

      expect(prefs.getKeys().where((k) => k.contains('birth')), isEmpty);
      expect((await repo.load()).isEmpty, isTrue);
    });

    test('a corrupt payload reads as empty instead of throwing', () async {
      SharedPreferences.setMockInitialValues(
          {'nimit.birth.v2': 'not json at all'});
      final prefs = await SharedPreferences.getInstance();

      expect((await LocalBirthProfileRepository(prefs).load()).isEmpty, isTrue);
    });

    test('an unparseable date reads as empty, never as a guess', () async {
      // A half-understood date would hand somebody a stranger's lunar month.
      for (final bad in ['15/07/1993', '1993-13-45', '', 'null']) {
        SharedPreferences.setMockInitialValues(
            {'nimit.birth.v2': '{"date": "$bad"}'});
        final prefs = await SharedPreferences.getInstance();

        expect((await LocalBirthProfileRepository(prefs).load()).date, isNull,
            reason: 'date "$bad" should not resolve');
      }
    });

    test('an out-of-range legacy month reads as absent, never clamped', () async {
      for (final bad in [0, 13, -1]) {
        SharedPreferences.setMockInitialValues(
            {'nimit.birthmonth.v1': '{"month": $bad}'});
        final prefs = await SharedPreferences.getInstance();

        expect(
            (await LocalBirthProfileRepository(prefs).load()).legacyMonth, isNull,
            reason: 'month $bad should not become a real month');
      }
    });

    test('a stored time component is dropped', () async {
      // Time of day is deliberately not collected; if some future writer put
      // one in, it must not leak into equality or the conversion.
      SharedPreferences.setMockInitialValues(
          {'nimit.birth.v2': '{"date": "1993-07-15T23:45:00"}'});
      final prefs = await SharedPreferences.getInstance();

      expect((await LocalBirthProfileRepository(prefs).load()).date,
          DateTime(1993, 7, 15));
    });
  });

  // ── เลขที่ตามอยู่ ─────────────────────────────────────────────────────────
  //
  // The cap silently destroyed saved numbers: keeping a twenty-first evicted the
  // oldest and told nobody, on the one screen in the app that is about money.
  // save() now reports what it dropped so the UI can say so, and these hold that
  // contract — including the case that made it easy to get wrong.
  group('watched numbers', () {
    WatchedNumber num(String n) =>
        WatchedNumber(number: n, savedAt: DateTime(2026, 7, 30));

    test('saving under the cap drops nothing and keeps newest first', () async {
      final repo =
          LocalWatchedNumbersRepository(await SharedPreferences.getInstance());

      expect(await repo.save(num('12')), isNull);
      expect(await repo.save(num('34')), isNull);

      expect([for (final w in await repo.all()) w.number], ['34', '12']);
    });

    test('past the cap it reports the number pushed out', () async {
      final repo =
          LocalWatchedNumbersRepository(await SharedPreferences.getInstance());
      const max = WatchedNumbersRepository.maxWatched;

      // 00..19 — the first saved is '00', so it is the oldest and goes first.
      for (var i = 0; i < max; i++) {
        expect(await repo.save(num(i.toString().padLeft(2, '0'))), isNull,
            reason: 'nothing should drop while filling to the cap');
      }
      expect(await repo.all(), hasLength(max));

      expect(await repo.save(num('99')), '00',
          reason: 'the oldest is evicted, and save must name it');
      final after = await repo.all();
      expect(after, hasLength(max), reason: 'the cap still holds');
      expect(after.first.number, '99');
      expect([for (final w in after) w.number], isNot(contains('00')));
    });

    test('re-saving a number already held is a move, not an eviction', () async {
      // The trap: the eviction check has to run AFTER the duplicate is removed.
      // Checking length first reports a drop that never happened, and the UI
      // would tell the user it had thrown away a number it still has.
      final repo =
          LocalWatchedNumbersRepository(await SharedPreferences.getInstance());
      const max = WatchedNumbersRepository.maxWatched;

      for (var i = 0; i < max; i++) {
        await repo.save(num(i.toString().padLeft(2, '0')));
      }

      expect(await repo.save(num('05')), isNull,
          reason: 'the list was full but this number was already in it');
      final after = await repo.all();
      expect(after, hasLength(max));
      expect(after.first.number, '05', reason: 'moved to the top');
      expect([for (final w in after) w.number].where((n) => n == '05'),
          hasLength(1), reason: 'and not duplicated');
    });

    test('remove takes a number out', () async {
      final repo =
          LocalWatchedNumbersRepository(await SharedPreferences.getInstance());
      await repo.save(num('12'));
      await repo.save(num('34'));

      await repo.remove('12');

      expect([for (final w in await repo.all()) w.number], ['34']);
    });
  });
}
