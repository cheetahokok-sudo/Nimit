import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nimit/data/lottery_checker.dart';
import 'package:nimit/data/models/lottery.dart';

/// CONTRACT TEST — the real thing, end to end, offline.
///
/// The fixture in test/fixtures/ is not hand-written. It is the verbatim output
/// of `api.lottery_draw('2026-07-16')` running against a real PostgreSQL, after
/// ingesting the verbatim payload that สำนักงานสลากกินแบ่งรัฐบาล returned from
/// its live API for งวด 16 กรกฎาคม 2569.
///
/// So this test covers the one seam that unit tests with invented fixtures
/// cannot: GLO's actual JSON → our ingest SQL → our read SQL → Dart parsing →
/// prize matching. If any link changes shape, this fails.
///
/// Regenerate with:
///   psql "$PGURL" -t -A -c "select api.lottery_draw('2026-07-16'::date)"
void main() {
  late DrawResult draw;

  setUpAll(() {
    final file = File('test/fixtures/real_draw_2026_07_16.json');
    draw = DrawResult.fromJson(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>);
  });

  test('the real payload parses completely', () {
    expect(draw.status, DrawStatus.announced);
    expect(draw.complete, isTrue);
    expect(draw.hasUnreadableTier, isFalse);
    expect(draw.verdictAvailable, isTrue);
    expect(draw.periodLabelTh, 'งวดวันที่ 16 กรกฎาคม 2569');
    expect(draw.sourceCustodianTh, 'สำนักงานสลากกินแบ่งรัฐบาล');
  });

  test('it carries exactly 173 numbers across 9 tiers', () {
    expect(draw.prizes.length, 9);
    final total =
        draw.prizes.fold<int>(0, (sum, p) => sum + p.numbers.length);
    expect(total, 173,
        reason: 'a truncated draw and a real one must never look alike');
  });

  test('every tier carries its full complement and correct digit length', () {
    const expected = {
      'first': (1, 6),
      'near_first': (2, 6),
      'second': (5, 6),
      'third': (10, 6),
      'fourth': (50, 6),
      'fifth': (100, 6),
      'front3': (2, 3),
      'last3': (2, 3),
      'last2': (1, 2),
    };
    for (final entry in expected.entries) {
      final tier = draw.tier(entry.key)!;
      expect(tier.numbers.length, entry.value.$1, reason: entry.key);
      for (final n in tier.numbers) {
        expect(n.length, entry.value.$2, reason: '${entry.key}: $n');
        expect(int.tryParse(n), isNotNull, reason: '${entry.key}: $n');
      }
    }
  });

  test('the prize pool matches the published structure', () {
    final pool = draw.prizes
        .fold<int>(0, (sum, p) => sum + p.amountThb * p.winnerCount);
    expect(pool, 12018000);
    expect(draw.tier('first')!.amountThb, 6000000);
    expect(draw.tier('last2')!.amountThb, 2000);
  });

  group('matching against the genuine result', () {
    SavedTicket t(String n, {int q = 1}) =>
        SavedTicket(number: n, savedAt: DateTime(2026, 7, 1), quantity: q);

    test('the actual first-prize number wins, and stacks', () {
      // GLO published first = 639214 and last3 includes 427/746 (not 214),
      // last2 = 71. So this ticket takes the first prize only.
      final o = checkTicket(draw, t('639214'));
      expect(o.hits.map((h) => h.tierCode), contains('first'));
      expect(o.unitAmountThb, greaterThanOrEqualTo(6000000));
    });

    test('ข้างเคียง are the first prize ±1, and exclude the first prize', () {
      expect(draw.tier('near_first')!.numbers, containsAll(['639213', '639215']));
      final near = checkTicket(draw, t('639213'));
      expect(near.hits.map((h) => h.tierCode), contains('near_first'));
      expect(near.hits.where((h) => h.tierCode == 'first'), isEmpty);
    });

    test('เลขหน้า 3 ตัว really matches the leading three digits', () {
      // Published เลขหน้า for this งวด: 683 and 709.
      final front = draw.tier('front3')!.numbers;
      expect(front, containsAll(['683', '709']));
      expect(checkTicket(draw, t('${front.first}000')).hits
          .map((h) => h.tierCode), contains('front3'));
      // The same digits at the END must not win เลขหน้า.
      expect(checkTicket(draw, t('000${front.first}')).hits
          .map((h) => h.tierCode), isNot(contains('front3')));
    });

    test('เลขท้าย 3 ตัว really matches the trailing three digits', () {
      final last3 = draw.tier('last3')!.numbers;
      expect(last3, containsAll(['427', '746']));
      expect(checkTicket(draw, t('000${last3.first}')).hits
          .map((h) => h.tierCode), contains('last3'));
      expect(checkTicket(draw, t('${last3.first}000')).hits
          .map((h) => h.tierCode), isNot(contains('last3')));
    });

    test('a set of five on the first prize pays five times, gross', () {
      final o = checkTicket(draw, t('639214', q: 5));
      expect(o.totalAmountThb, o.unitAmountThb * 5);
      expect(o.totalAmountThb, greaterThanOrEqualTo(30000000));
      // Gross: the duty is carried on the draw but never applied.
      expect(draw.dutyRate, 0.005);
    });

    test('a number that did not win is a clean loss, and may be declared so',
        () {
      final o = checkTicket(draw, t('000001'));
      expect(o.hits, isEmpty);
      expect(o.invalid, isFalse);
      expect(checkAll(draw, [t('000001')]).verdictAvailable, isTrue);
    });
  });
}
