import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nimit/data/models/dream.dart';
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
}
