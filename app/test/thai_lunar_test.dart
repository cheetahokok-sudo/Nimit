import 'package:flutter_test/flutter_test.dart';
import 'package:nimit/core/calendar/thai_lunar.dart';

/// Expectations come from two independent kinds of source, never from the
/// implementation:
///
///  * J. C. Eade, "Rules for interpolation in the Thai calendar: Suriyayatra
///    versus the Sasana", JSS 88.1 & 2 (2000) — astronomical, CS 1320–1340.
///  * Published Thai Buddhist holiday records naming เดือนแปดหลัง —
///    ecclesiastical, พ.ศ. 2561–2569.
///
/// Two witnesses of different kinds, 68 years apart, is what makes the phase of
/// the 19-year cycle trustworthy rather than fitted to one table.
void main() {
  group('suriyayatra New Year values', () {
    test("reproduce Eade's worked example for CS 1325 exactly", () {
      // Appendix A, p. 199. All six printed values, because a wrong constant in
      // one stage can still leave a later stage looking plausible.
      final y = ThaiLunarCalendar.yearValues(1325);

      expect(y.horakhun, 483969, reason: 'A1 horakhun');
      expect(y.kammacubala, 552, reason: 'A2 kammacubala');
      expect(y.uccabala, 1780, reason: 'A3 uccabala');
      expect(y.avoman, 61, reason: 'A4 avoman');
      expect(y.masaken, 16388, reason: 'A5 masaken');
      expect(y.newYearDay, 23, reason: "A5 remainder = New Year's day");
    });

    test('CS 1320 kammacubala and avoman match the p.196 discussion', () {
      // p. 196: "at the start of CS 1320 the kammacubala was 787 (normal;
      // solar) and the avoman was 43".
      final y = ThaiLunarCalendar.yearValues(1320);

      expect(y.kammacubala, 787);
      expect(y.avoman, 43);
      expect(y.isSolarLeap, isFalse, reason: '787 is well above the 207 cutoff');
    });
  });

  group('year classification against Eade table, CS 1320-1340', () {
    // p. 197. "m" adhikamat, "d" adhikawan, "n" normal — the paper's own
    // worked-out sequence for 1958-1978.
    const expected = <int, ThaiYearType>{
      1320: ThaiYearType.adhikamat,
      1321: ThaiYearType.adhikawan,
      1322: ThaiYearType.normal,
      1323: ThaiYearType.adhikamat,
      1324: ThaiYearType.normal,
      1325: ThaiYearType.adhikawan,
      1326: ThaiYearType.adhikamat,
      1327: ThaiYearType.normal,
      1328: ThaiYearType.adhikamat,
      1329: ThaiYearType.normal,
      1330: ThaiYearType.adhikawan,
      1331: ThaiYearType.adhikamat,
      1332: ThaiYearType.normal,
      1333: ThaiYearType.normal,
      1334: ThaiYearType.adhikamat,
      1335: ThaiYearType.adhikawan,
      1336: ThaiYearType.normal,
      1337: ThaiYearType.adhikamat,
      1338: ThaiYearType.normal,
      1339: ThaiYearType.adhikamat,
      1340: ThaiYearType.adhikawan,
    };

    test('adhikamat years match', () {
      final ours = <int>[
        for (var cs = 1320; cs <= 1340; cs++)
          if (ThaiLunarCalendar.isAdhikamat(cs)) cs
      ];
      expect(ours, [1320, 1323, 1326, 1328, 1331, 1334, 1337, 1339]);
    });

    test('full m/d/n sequence matches', () {
      final wrong = <String>[];
      expected.forEach((cs, type) {
        final got = ThaiLunarCalendar.yearType(cs);
        if (got != type) wrong.add('CS $cs: want ${type.name}, got ${got.name}');
      });
      expect(wrong, isEmpty, reason: wrong.join('\n'));
    });

    test('no year is both adhikamat and adhikawan', () {
      // p. 196: "years with an extra month are not allowed also to have an
      // extra day". p. 199 notes the Burmese rule is the exact inverse, so this
      // is a real Thai-specific constraint, not a tautology.
      for (var cs = 1320; cs <= 1340; cs++) {
        if (ThaiLunarCalendar.isAdhikamat(cs)) {
          expect(ThaiLunarCalendar.yearType(cs), ThaiYearType.adhikamat);
        }
      }
    });
  });

  group('cross-check against published Buddhist holiday records', () {
    // วันอาสาฬหบูชา is ขึ้น ๑๕ ค่ำ เดือน ๘; in an adhikamat year it falls in
    // เดือนแปดหลัง. Published holiday listings name the month, so they witness
    // intercalation independently of any astronomical table.
    test('the four recorded เดือนแปดหลัง years are adhikamat', () {
      for (final be in [2561, 2564, 2566, 2569]) {
        final cs = ThaiLunarCalendar.csFromBeAfterSongkran(be);
        expect(ThaiLunarCalendar.isAdhikamat(cs), isTrue,
            reason: 'BE $be = CS $cs, residue ${cs % 19}');
      }
    });

    test('neighbouring years are NOT adhikamat', () {
      // Without this, a rule that answered "yes" to everything would pass above.
      for (final be in [2562, 2563, 2565, 2567, 2568]) {
        final cs = ThaiLunarCalendar.csFromBeAfterSongkran(be);
        expect(ThaiLunarCalendar.isAdhikamat(cs), isFalse, reason: 'BE $be');
      }
    });

    test('the BE-to-CS offset ties the two sources together', () {
      // Eade's CS 1320 is 1958 AD, i.e. พ.ศ. 2501. If this offset drifts, the
      // two witnesses stop corroborating each other and could silently agree
      // on the wrong phase.
      expect(ThaiLunarCalendar.csFromBeAfterSongkran(2501), 1320);
      expect(ThaiLunarCalendar.csFromBeAfterSongkran(2569), 1388);
    });
  });

  group('structural invariants', () {
    test('exactly 7 adhikamat years in every 19-year window', () {
      for (var start = 1300; start < 1400; start++) {
        var n = 0;
        for (var cs = start; cs < start + 19; cs++) {
          if (ThaiLunarCalendar.isAdhikamat(cs)) n++;
        }
        expect(n, 7, reason: 'window starting CS $start');
      }
    });

    test('gaps between adhikamat years are only 2 or 3, summing to 19', () {
      // อติชาต เกตตะพันธุ์, "ปฏิทินสุวรรณภูมิ": สูตรหาปีอธิกมาส คือ 3332332.
      final years = <int>[
        for (var cs = 1320; cs <= 1320 + 19; cs++)
          if (ThaiLunarCalendar.isAdhikamat(cs)) cs
      ];
      final gaps = <int>[
        for (var i = 1; i < years.length; i++) years[i] - years[i - 1]
      ];
      expect(gaps.every((g) => g == 2 || g == 3), isTrue, reason: '$gaps');
      expect(gaps.fold<int>(0, (a, b) => a + b), 19,
          reason: 'one full cycle must span exactly 19 years');
    });
  });
}
