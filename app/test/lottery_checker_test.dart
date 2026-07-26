import 'package:flutter_test/flutter_test.dart';
import 'package:nimit/data/lottery_checker.dart';
import 'package:nimit/data/models/lottery.dart';

/// Fixtures are literals, not the mock repository: these tests are about the
/// arithmetic of money, and they must fail when the arithmetic changes rather
/// than when a demo fixture is edited.
///
/// Numbers mirror a real draw shape — first 639214, near1 639213/639215 — so
/// the ข้างเคียง exclusivity being structural rather than special-cased is
/// exercised against realistic data.
PrizeTierResult _tier(
  String code,
  String nameTh,
  int amount,
  MatchKind? kind,
  List<String> numbers, {
  int sort = 0,
}) =>
    PrizeTierResult(
      code: code,
      nameTh: nameTh,
      shortNameTh: nameTh,
      amountThb: amount,
      winnerCount: numbers.length,
      matchKind: kind,
      sort: sort,
      numbers: numbers,
    );

DrawResult _draw({
  List<PrizeTierResult>? prizes,
  DrawStatus status = DrawStatus.announced,
  bool complete = true,
}) {
  final p = prizes ??
      [
        _tier('first', 'รางวัลที่ 1', 6000000, MatchKind.exact6, ['639214'],
            sort: 10),
        _tier('near_first', 'รางวัลข้างเคียงรางวัลที่ 1', 100000,
            MatchKind.exact6, ['639213', '639215'], sort: 20),
        _tier('second', 'รางวัลที่ 2', 200000, MatchKind.exact6, ['041103'],
            sort: 30),
        _tier('front3', 'รางวัลเลขหน้า 3 ตัว', 4000, MatchKind.prefix3,
            ['683', '709'], sort: 70),
        _tier('last3', 'รางวัลเลขท้าย 3 ตัว', 4000, MatchKind.suffix3,
            ['427', '214'], sort: 80),
        _tier('last2', 'รางวัลเลขท้าย 2 ตัว', 2000, MatchKind.suffix2, ['14'],
            sort: 90),
      ];
  return DrawResult(
    drawDate: DateTime(2026, 7, 16),
    periodLabelTh: 'งวดวันที่ 16 กรกฎาคม 2569',
    status: status,
    resultRevision: 0,
    complete: complete,
    hasUnreadableTier: p.any((t) => t.matchKind == null),
    dutyRate: 0.005,
    prizes: p,
    sourceCustodianTh: 'สำนักงานสลากกินแบ่งรัฐบาล',
  );
}

SavedTicket _ticket(String number, {int quantity = 1}) =>
    SavedTicket(number: number, savedAt: DateTime(2026, 7, 1), quantity: quantity);

void main() {
  group('single-tier matching', () {
    test('the first prize pays 6,000,000', () {
      final o = checkTicket(_draw(), _ticket('639214'));
      expect(o.hits.map((h) => h.tierCode), contains('first'));
      expect(o.isWin, isTrue);
      expect(o.invalid, isFalse);
    });

    test('a number matching nothing wins nothing but is not invalid', () {
      final o = checkTicket(_draw(), _ticket('555555'));
      expect(o.hits, isEmpty);
      expect(o.totalAmountThb, 0);
      expect(o.invalid, isFalse);
    });

    test('เลขหน้า 3 ตัว matches the FIRST three digits, not the last', () {
      // front3 = 683. '683999' must win; '999683' must not.
      expect(checkTicket(_draw(), _ticket('683999')).hits.map((h) => h.tierCode),
          contains('front3'));
      expect(checkTicket(_draw(), _ticket('999683')).hits.map((h) => h.tierCode),
          isNot(contains('front3')));
    });

    test('เลขท้าย 3 ตัว matches the LAST three digits, not the first', () {
      // last3 = 427. '999427' must win; '427999' must not.
      expect(checkTicket(_draw(), _ticket('999427')).hits.map((h) => h.tierCode),
          contains('last3'));
      expect(checkTicket(_draw(), _ticket('427999')).hits.map((h) => h.tierCode),
          isNot(contains('last3')));
    });
  });

  group('stacking', () {
    test('first + last3 + last2 stack and the payouts add', () {
      // 639214: first=639214, last3=214, last2=14.
      final o = checkTicket(_draw(), _ticket('639214'));
      // Assert the COUNT as well as the sum: a total that still looks large
      // would otherwise mask a dropped tier.
      expect(o.hits.length, 3);
      expect(o.hits.map((h) => h.tierCode),
          containsAll(['first', 'last3', 'last2']));
      expect(o.unitAmountThb, 6000000 + 4000 + 2000);
      expect(o.unitAmountThb, 6006000);
    });

    test('ข้างเคียง and รางวัลที่ 1 are mutually exclusive', () {
      // Side numbers are first ±1, so no six-digit string can satisfy both.
      final first = checkTicket(_draw(), _ticket('639214'));
      expect(first.hits.where((h) => h.tierCode == 'near_first'), isEmpty);

      final near = checkTicket(_draw(), _ticket('639213'));
      expect(near.hits.map((h) => h.tierCode), contains('near_first'));
      expect(near.hits.where((h) => h.tierCode == 'first'), isEmpty);
    });

    test('a tier pays at most once even if it lists a number twice', () {
      final d = _draw(prizes: [
        _tier('fifth', 'รางวัลที่ 5', 20000, MatchKind.exact6,
            ['123456', '123456']),
      ]);
      final o = checkTicket(d, _ticket('123456'));
      expect(o.hits.length, 1);
      expect(o.unitAmountThb, 20000);
    });

    test('the maximum realistic stack is not clamped', () {
      // 6,000,000 + 4,000 + 4,000 + 2,000 = 6,010,000.
      final d = _draw(prizes: [
        _tier('first', 'รางวัลที่ 1', 6000000, MatchKind.exact6, ['639214']),
        _tier('front3', 'เลขหน้า', 4000, MatchKind.prefix3, ['639']),
        _tier('last3', 'เลขท้าย 3', 4000, MatchKind.suffix3, ['214']),
        _tier('last2', 'เลขท้าย 2', 2000, MatchKind.suffix2, ['14']),
      ]);
      final o = checkTicket(d, _ticket('639214'));
      expect(o.hits.length, 4);
      expect(o.unitAmountThb, 6010000);
    });
  });

  group('leading zeros — every one of these is an int.parse bug waiting', () {
    test('all-zero ticket matches all-zero prizes', () {
      final d = _draw(prizes: [
        _tier('front3', 'เลขหน้า', 4000, MatchKind.prefix3, ['000']),
        _tier('last3', 'เลขท้าย 3', 4000, MatchKind.suffix3, ['000']),
        _tier('last2', 'เลขท้าย 2', 2000, MatchKind.suffix2, ['00']),
      ]);
      final o = checkTicket(d, _ticket('000000'));
      expect(o.hits.length, 3);
      expect(o.unitAmountThb, 10000);
    });

    test('000123 splits into 000 / 123 / 23', () {
      final d = _draw(prizes: [
        _tier('front3', 'เลขหน้า', 4000, MatchKind.prefix3, ['000']),
        _tier('last3', 'เลขท้าย 3', 4000, MatchKind.suffix3, ['123']),
        _tier('last2', 'เลขท้าย 2', 2000, MatchKind.suffix2, ['23']),
      ]);
      expect(checkTicket(d, _ticket('000123')).hits.length, 3);
    });

    test("123400 ends in '00', which must not compare as 0", () {
      final d = _draw(prizes: [
        _tier('last2', 'เลขท้าย 2', 2000, MatchKind.suffix2, ['00']),
      ]);
      expect(checkTicket(d, _ticket('123400')).unitAmountThb, 2000);
      // '0' is not '00'.
      final d2 = _draw(prizes: [
        _tier('last2', 'เลขท้าย 2', 2000, MatchKind.suffix2, ['0']),
      ]);
      expect(checkTicket(d2, _ticket('123400')).unitAmountThb, 0);
    });

    test('a real GLO first prize with a leading zero matches', () {
      // งวด 16 ธันวาคม 2567 really was 097863.
      final d = _draw(prizes: [
        _tier('first', 'รางวัลที่ 1', 6000000, MatchKind.exact6, ['097863']),
      ]);
      expect(checkTicket(d, _ticket('097863')).unitAmountThb, 6000000);
      expect(checkTicket(d, _ticket('978630')).unitAmountThb, 0);
    });
  });

  group('quantity — ซื้อเป็นชุด', () {
    test('the prize multiplies by the number of tickets held', () {
      final d = _draw(prizes: [
        _tier('last3', 'เลขท้าย 3', 4000, MatchKind.suffix3, ['214']),
      ]);
      final o = checkTicket(d, _ticket('639214', quantity: 3));
      expect(o.unitAmountThb, 4000);
      expect(o.totalAmountThb, 12000);
    });

    test('five tickets on the first prize', () {
      final o = checkTicket(_draw(), _ticket('639214', quantity: 5));
      expect(o.totalAmountThb, 6006000 * 5);
    });

    test('a corrupted quantity of 0 or -1 clamps to 1, never zeroing a win',
        () {
      for (final bad in [0, -1]) {
        final t = SavedTicket.fromJson({
          'number': '639214',
          'savedAt': DateTime(2026, 7, 1).toIso8601String(),
          'quantity': bad,
        });
        expect(t.quantity, 1);
        expect(checkTicket(_draw(), t).totalAmountThb, 6006000);
      }
    });
  });

  group('refusing to render a verdict', () {
    test('a malformed stored number is invalid, not a loss', () {
      for (final bad in ['12345', '1234567', '12345a', '', '  ']) {
        final o = checkTicket(_draw(), _ticket(bad));
        expect(o.invalid, isTrue, reason: 'expected $bad to be invalid');
        expect(o.hits, isEmpty);
      }
    });

    test('an unknown match rule suppresses the verdict for the whole draw', () {
      final d = _draw(prizes: [
        _tier('first', 'รางวัลที่ 1', 6000000, MatchKind.exact6, ['639214']),
        _tier('mystery', 'รางวัลใหม่', 5000, null, ['99']),
      ]);
      expect(d.hasUnreadableTier, isTrue);
      expect(d.verdictAvailable, isFalse);
      // The tiers we DO understand still match — we simply may not say "lost".
      expect(checkTicket(d, _ticket('639214')).isWin, isTrue);
    });

    test('a partial draw never permits a losing verdict', () {
      final d = _draw(status: DrawStatus.partial, complete: false);
      final outcome = checkAll(d, [_ticket('555555')]);
      expect(outcome.verdictAvailable, isFalse);
    });

    test('an announced but incomplete draw still permits no verdict', () {
      final d = _draw(status: DrawStatus.announced, complete: false);
      expect(d.verdictAvailable, isFalse);
    });

    test('DrawStatus fails closed and never resolves to announced', () {
      for (final code in [null, '', 'ANNOUNCED', 'announced!!', 'bogus']) {
        expect(DrawStatus.fromCode(code), isNot(DrawStatus.announced));
      }
      expect(DrawStatus.fromCode('announced'), DrawStatus.announced);
    });
  });

  group('the displayed figure is gross', () {
    // This test exists to fail if someone later "helpfully" applies the stamp
    // duty to the computed total. Showing net was considered and explicitly
    // decided against; the duty is surfaced as claim guidance in the UI.
    test('a 6,000,000 win totals 6,000,000 despite a 0.5% duty rate', () {
      final d = _draw(prizes: [
        _tier('first', 'รางวัลที่ 1', 6000000, MatchKind.exact6, ['639214']),
      ]);
      expect(d.dutyRate, 0.005);
      expect(checkTicket(d, _ticket('639214')).totalAmountThb, 6000000);
      expect(checkTicket(d, _ticket('639214', quantity: 5)).totalAmountThb,
          30000000);
    });
  });

  group('checkAll and the hope figure', () {
    test('totals across several tickets', () {
      final outcome = checkAll(_draw(), [
        _ticket('639214'), // 6,006,000
        _ticket('041103', quantity: 2), // 200,000 x2
        _ticket('555555'), // nothing
      ]);
      expect(outcome.hasWin, isTrue);
      expect(outcome.winningTicketCount, 2);
      expect(outcome.totalThb, 6006000 + 400000);
    });

    test('the hope figure multiplies the top prize by tickets held', () {
      expect(
        hopeAmountThb(_draw(), [_ticket('123456', quantity: 5)]),
        30000000,
      );
      expect(
        hopeAmountThb(_draw(), [
          _ticket('123456', quantity: 2),
          _ticket('654321', quantity: 3),
        ]),
        30000000,
      );
    });

    test('the hope figure is zero when the draw has no first-prize tier', () {
      final d = _draw(prizes: [
        _tier('last2', 'เลขท้าย 2', 2000, MatchKind.suffix2, ['14']),
      ]);
      expect(hopeAmountThb(d, [_ticket('123456', quantity: 5)]), 0);
    });
  });
}
