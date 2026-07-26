import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nimit/data/models/dream.dart';
import 'package:nimit/data/models/lottery.dart';
import 'package:nimit/data/models/source.dart';

void main() {
  group('SourceTier.fromCode fails closed', () {
    test('resolves known codes, case and whitespace insensitive', () {
      expect(SourceTier.fromCode('A1'), SourceTier.a1);
      expect(SourceTier.fromCode('a1'), SourceTier.a1);
      expect(SourceTier.fromCode('  b2 '), SourceTier.b2);
      expect(SourceTier.fromCode('D'), SourceTier.d);
    });

    // The direction of this fallback is a correctness requirement, not style:
    // unrecognised content must never be badged as a historical original.
    test('unknown, empty and null codes degrade to D (ยังไม่ยืนยัน)', () {
      expect(SourceTier.fromCode('ZZ'), SourceTier.d);
      expect(SourceTier.fromCode(''), SourceTier.d);
      expect(SourceTier.fromCode(null), SourceTier.d);
      expect(SourceTier.fromCode('A99'), SourceTier.d);
    });

    test('never silently upgrades trust', () {
      for (final bogus in ['', ' ', 'x', 'A', '1', 'AA1', 'ก']) {
        expect(SourceTier.fromCode(bogus), SourceTier.d,
            reason: 'input "$bogus" must not resolve above tier D');
      }
    });
  });

  group('DreamAnalysis serialization', () {
    final analysis = DreamAnalysis(
      headlineTh: 'งูสีขาว • หน้าบ้าน • ฝนเบา',
      themeTh: 'การเปลี่ยนแปลงที่เข้ามาอย่างสงบ',
      symbols: const [
        DreamSymbol(nameTh: 'งู', count: 6, slug: 'snake'),
        DreamSymbol(nameTh: 'บ้าน', count: 9),
      ],
      interpretations: const [
        SymbolInterpretation(
          tier: SourceTier.a1,
          sourceNameTh: 'ตำราโบราณที่ตรวจสอบได้',
          textTh: 'การพบงูใกล้บ้านมักถูกตีความว่ามีเรื่องใหม่เข้ามา',
          locatorTh: 'ผูกที่ ๓ หน้า ๑๒',
        ),
      ],
      numbers: const ['16', '61'],
      sourceCount: 3,
    );

    test('round-trips through JSON preserving Thai text and tier', () {
      final decoded =
          DreamAnalysis.fromJson(jsonDecode(jsonEncode(analysis.toJson())));

      expect(decoded.headlineTh, analysis.headlineTh);
      expect(decoded.themeTh, analysis.themeTh);
      expect(decoded.numbers, ['16', '61']);
      expect(decoded.sourceCount, 3);
      expect(decoded.symbols.map((s) => s.nameTh), ['งู', 'บ้าน']);
      expect(decoded.symbols.first.slug, 'snake');
      expect(decoded.symbols.last.slug, isNull);
      expect(decoded.interpretations.single.tier, SourceTier.a1);
      expect(decoded.interpretations.single.locatorTh, 'ผูกที่ ๓ หน้า ๑๒');
    });

    test('a corrupt tier in stored JSON degrades to D rather than throwing', () {
      final payload = analysis.toJson();
      (payload['interpretations'] as List).first['tier'] = 'NOPE';

      final decoded = DreamAnalysis.fromJson(jsonDecode(jsonEncode(payload)));
      expect(decoded.interpretations.single.tier, SourceTier.d);
    });

    test('quoteTh is omitted entirely when absent', () {
      final json = analysis.interpretations.single.toJson();
      expect(json.containsKey('quoteTh'), isFalse);
    });
  });

  group('DreamEntry backward compatibility', () {
    // Payloads already on user devices under `nimit.journal.v1` predate the
    // analysis field; they must keep parsing after the schema grew.
    test('parses a v1 payload written before analysis existed', () {
      const legacy = '{"id":"1","text":"ฝันเห็นงู",'
          '"createdAt":"2026-07-24T10:00:00.000","feelingTh":"สงบ",'
          '"timeOfNightTh":null,"headlineTh":null,"numbers":["16"]}';

      final entry = DreamEntry.fromJson(jsonDecode(legacy));

      expect(entry.id, '1');
      expect(entry.text, 'ฝันเห็นงู');
      expect(entry.feelingTh, 'สงบ');
      expect(entry.numbers, ['16']);
      expect(entry.analysis, isNull);
    });

    test('parses a payload with no numbers key at all', () {
      const older =
          '{"id":"2","text":"ฝัน","createdAt":"2026-07-24T10:00:00.000"}';

      final entry = DreamEntry.fromJson(jsonDecode(older));
      expect(entry.numbers, isEmpty);
      expect(entry.analysis, isNull);
    });

    test('round-trips an entry carrying an analysis snapshot', () {
      final entry = DreamEntry(
        id: '3',
        text: 'ฝันเห็นงูสีขาว',
        createdAt: DateTime(2026, 7, 26, 8, 30),
        numbers: const ['16'],
        analysis: const DreamAnalysis(
          headlineTh: 'งูสีขาว',
          themeTh: 'การเปลี่ยนแปลง',
          symbols: [DreamSymbol(nameTh: 'งู', count: 6)],
          interpretations: [],
          numbers: ['16'],
          sourceCount: 1,
        ),
      );

      final decoded =
          DreamEntry.fromJson(jsonDecode(jsonEncode(entry.toJson())));

      expect(decoded.createdAt, entry.createdAt);
      expect(decoded.analysis, isNotNull);
      expect(decoded.analysis!.headlineTh, 'งูสีขาว');
      expect(decoded.analysis!.symbols.single.count, 6);
    });
  });

  group('SavedTicket.quantity is additive and cannot break old payloads', () {
    // Devices already hold nimit.tickets.v1 entries written before `quantity`
    // existed. If parsing one throws, _decodeListOrEmpty SKIPS it and the next
    // save() rewrites the list without it — the user's numbers are gone,
    // silently and permanently. These tests pin the behaviour that prevents it.
    test('a legacy entry with no quantity reads as 1', () {
      final t = SavedTicket.fromJson({
        'number': '639214',
        'savedAt': '2026-07-01T10:00:00.000',
      });
      expect(t.quantity, 1);
      expect(t.number, '639214');
    });

    test('quantity round-trips through JSON', () {
      final t = SavedTicket(
          number: '639214', savedAt: DateTime(2026, 7, 1), quantity: 5);
      final decoded =
          SavedTicket.fromJson(jsonDecode(jsonEncode(t.toJson())));
      expect(decoded.quantity, 5);
      expect(decoded.number, '639214');
      expect(decoded.savedAt, t.savedAt);
    });

    test('a quantity stored as a double parses (web JSON yields 2.0)', () {
      final t = SavedTicket.fromJson({
        'number': '639214',
        'savedAt': '2026-07-01T10:00:00.000',
        'quantity': 2.0,
      });
      expect(t.quantity, 2);
    });

    test('a corrupt quantity clamps to 1 rather than zeroing a win', () {
      for (final bad in [0, -3]) {
        final t = SavedTicket.fromJson({
          'number': '639214',
          'savedAt': '2026-07-01T10:00:00.000',
          'quantity': bad,
        });
        expect(t.quantity, 1);
      }
    });

    test('a null quantity reads as 1', () {
      final t = SavedTicket.fromJson({
        'number': '639214',
        'savedAt': '2026-07-01T10:00:00.000',
        'quantity': null,
      });
      expect(t.quantity, 1);
    });
  });

  group('DrawStatus fails closed', () {
    test('unknown codes never resolve to announced', () {
      for (final code in [null, '', 'ANNOUNCED', 'Announced', 'partial ', 'x']) {
        expect(DrawStatus.fromCode(code), isNot(DrawStatus.announced),
            reason: 'code "$code" must not resolve to announced');
      }
    });

    test('known codes resolve exactly', () {
      expect(DrawStatus.fromCode('announced'), DrawStatus.announced);
      expect(DrawStatus.fromCode('partial'), DrawStatus.partial);
      expect(DrawStatus.fromCode('scheduled'), DrawStatus.scheduled);
    });
  });

  group('DrawSummary — the light history row', () {
    test('parses the compact payload including a leading-zero prize', () {
      final s = DrawSummary.fromJson({
        'drawDate': '2024-12-16',
        'labelTh': '16 ธันวาคม 2567',
        'yearBe': 2567,
        'first': '097863',
        'last2': '21',
        'complete': true,
      });
      expect(s.drawDate, DateTime(2024, 12, 16));
      expect(s.yearBe, 2567);
      // Must stay a String — '097863' is not 97863.
      expect(s.firstPrize, '097863');
      expect(s.last2, '21');
      expect(s.complete, isTrue);
    });

    test('tolerates a งวด whose prize numbers are absent', () {
      final s = DrawSummary.fromJson({
        'drawDate': '2026-08-01',
        'labelTh': '1 สิงหาคม 2569',
        'yearBe': 2569,
        'first': null,
        'last2': null,
        'complete': false,
      });
      expect(s.firstPrize, isNull);
      expect(s.complete, isFalse);
    });

    test('the year changes across a งวด boundary, which is what groups the list',
        () {
      // Two draws per month means a month name appears twice in a row. Without
      // a year heading that reads as duplicated rows — an actual user report.
      final dec = DrawSummary.fromJson({
        'drawDate': '2024-12-16',
        'labelTh': '16 ธันวาคม 2567',
        'yearBe': 2567,
      });
      final jan = DrawSummary.fromJson({
        'drawDate': '2025-01-02',
        'labelTh': '2 มกราคม 2568',
        'yearBe': 2568,
      });
      expect(dec.yearBe, isNot(jan.yearBe));
    });
  });

  group('MatchKind refuses to guess', () {
    test('an unknown rule is null, not a default', () {
      expect(MatchKind.fromCode('middle4'), isNull);
      expect(MatchKind.fromCode(null), isNull);
      expect(MatchKind.fromCode(''), isNull);
    });

    test('known rules resolve exactly', () {
      expect(MatchKind.fromCode('exact6'), MatchKind.exact6);
      expect(MatchKind.fromCode('prefix3'), MatchKind.prefix3);
      expect(MatchKind.fromCode('suffix3'), MatchKind.suffix3);
      expect(MatchKind.fromCode('suffix2'), MatchKind.suffix2);
    });
  });
}
