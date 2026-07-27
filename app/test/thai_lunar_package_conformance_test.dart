import 'package:flutter_test/flutter_test.dart';
import 'package:thai_lunar/thai_lunar.dart';

/// Conformance tests for package:thai_lunar, written against the literature
/// rather than against the package.
///
/// WHY THIS FILE EXISTS. The package scores 160/160 on pana, but that measures
/// packaging hygiene — docs, examples, static analysis — not arithmetic. It is
/// version 0.1.0 with 0 likes and ~21 downloads a month, so nobody has worn the
/// edges off it, and it is about to decide which เดือน someone was born in.
///
/// It earned the job. This repo first implemented สุริยยาตร์ independently from
/// J. C. Eade, "Rules for interpolation in the Thai calendar", JSS 88 (2000),
/// and validated it against his CS 1320–1340 table and four modern holiday
/// records. That implementation was then DELETED, because a 19-year Metonic
/// rule — correct across both validation windows — gets พ.ศ. 2555 wrong, and
/// the package gets it right. The regression test for 2555 is below.
///
/// If this file goes red after a package upgrade, the upgrade is wrong until
/// proven otherwise: these expectations come from published sources.
void main() {
  group('year type, against Eade CS 1320-1340', () {
    // p.197. "m" adhikamat, "d" adhikawan, "n" normal — his own worked-out
    // sequence for 1958–1978. BE = CS + 1181 for dates after Songkran.
    const eade = <int, ThaiLunarYearType>{
      1320: ThaiLunarYearType.extraMonth,
      1321: ThaiLunarYearType.extraDay,
      1322: ThaiLunarYearType.normal,
      1323: ThaiLunarYearType.extraMonth,
      1324: ThaiLunarYearType.normal,
      1325: ThaiLunarYearType.extraDay,
      1326: ThaiLunarYearType.extraMonth,
      1327: ThaiLunarYearType.normal,
      1328: ThaiLunarYearType.extraMonth,
      1329: ThaiLunarYearType.normal,
      1330: ThaiLunarYearType.extraDay,
      1331: ThaiLunarYearType.extraMonth,
      1332: ThaiLunarYearType.normal,
      1333: ThaiLunarYearType.normal,
      1334: ThaiLunarYearType.extraMonth,
      1335: ThaiLunarYearType.extraDay,
      1336: ThaiLunarYearType.normal,
      1337: ThaiLunarYearType.extraMonth,
      1338: ThaiLunarYearType.normal,
      1339: ThaiLunarYearType.extraMonth,
      1340: ThaiLunarYearType.extraDay,
    };

    test('full m/d/n classification matches all 21 years', () {
      // Includes CS 1321, the subtlest year in the table: its extra day was
      // DEFERRED from adhikamat CS 1320 and does not qualify on its own avoman
      // (598, nowhere near the 137 threshold). Eade p.196 — "the adhikawan
      // passed to CS 1321". An implementation that misses the deferral is
      // right for 20 of 21 years, which looks correct and is not.
      final wrong = <String>[];
      eade.forEach((cs, want) {
        final got = lunarYearType(cs + 1181);
        if (got != want) wrong.add('CS $cs: Eade ${want.name}, got ${got.name}');
      });
      expect(wrong, isEmpty, reason: wrong.join('\n'));
    });

    test('isAthikamat and isAthikavar agree with lunarYearType', () {
      for (final cs in eade.keys) {
        final be = cs + 1181;
        expect(isAthikamat(be), lunarYearType(be) == ThaiLunarYearType.extraMonth,
            reason: 'CS $cs');
        expect(isAthikavar(be), lunarYearType(be) == ThaiLunarYearType.extraDay,
            reason: 'CS $cs');
      }
    });
  });

  group('against published Buddhist holiday records', () {
    // วันอาสาฬหบูชา is ขึ้น ๑๕ ค่ำ เดือน ๘, but falls in เดือนแปดหลัง in an
    // adhikamat year, and วันวิสาขบูชา shifts from เดือน ๖ to เดือน ๗. Published
    // holiday listings therefore witness intercalation independently of any
    // astronomical table.
    test('recorded เดือนแปดหลัง years are adhikamat', () {
      for (final be in [2561, 2564, 2566, 2569]) {
        expect(isAthikamat(be), isTrue, reason: 'พ.ศ. $be');
      }
    });

    test('neighbouring years are not', () {
      // Without this, a function answering "yes" to everything would pass.
      for (final be in [2562, 2563, 2565, 2567, 2568]) {
        expect(isAthikamat(be), isFalse, reason: 'พ.ศ. $be');
      }
    });

    test('พ.ศ. 2555 is adhikamat — the year a Metonic rule gets wrong', () {
      // THE REGRESSION THAT DECIDED THE IMPLEMENTATION. A pure 19-year cycle,
      // phase-fitted to Eade (1958-78) and to 2561-2569, says พ.ศ. 2555 is a
      // normal year. It is not: วันวิสาขบูชา 2555 fell on 4 มิถุนายน — shifted
      // into เดือน ๗, which only happens in an adhikamat year — and
      // วันอาสาฬหบูชา on 2 สิงหาคม.
      //
      // 2555 sits BETWEEN the two windows the Metonic rule was validated
      // against, which is exactly where an approximation hides.
      expect(isAthikamat(2555), isTrue);
    });

    test('29 Jul 2026 is ขึ้น 15 ค่ำ เดือน 8 หลัง', () {
      final d = gregorianToThaiLunar(DateTime(2026, 7, 29));
      expect(d.month, 8);
      expect(d.isSecondEighth, isTrue);
      expect(d.phase, MoonPhase.waxing);
      expect(d.day, 15);
    });
  });

  group('structural invariants', () {
    test('month 8 doubles in an adhikamat year and only then', () {
      bool hasSecondEighth(int ceYear) {
        var d = DateTime(ceYear, 1, 1);
        while (d.year == ceYear) {
          if (gregorianToThaiLunar(d).isSecondEighth) return true;
          d = d.add(const Duration(days: 1));
        }
        return false;
      }

      expect(hasSecondEighth(2026), isTrue, reason: 'พ.ศ. 2569 is adhikamat');
      expect(hasSecondEighth(2025), isFalse, reason: 'พ.ศ. 2568 is not');
      expect(hasSecondEighth(2012), isTrue, reason: 'พ.ศ. 2555 is adhikamat');
    });

    test('no year is both adhikamat and adhikavar', () {
      // Eade p.196: the Thai rule bars it. (The Burmese rule is the exact
      // inverse, p.199, so this is a real constraint and not a tautology.)
      for (var be = 2450; be <= 2620; be++) {
        expect(isAthikamat(be) && isAthikavar(be), isFalse, reason: 'พ.ศ. $be');
      }
    });

    test('adhikamat frequency stays near 7 in 19 over 170 years', () {
      var n = 0;
      for (var be = 2450; be <= 2620; be++) {
        if (isAthikamat(be)) n++;
      }
      // 171 years * 7/19 = 63. Allow slack for cycle phase at the endpoints.
      expect(n, inInclusiveRange(58, 68), reason: 'got $n');
    });

    test('every day of a decade converts without throwing', () {
      // Cheap fuzz over the range real birth dates land in. A conversion that
      // throws on some ordinary Tuesday is a crash on the ดวง screen.
      var d = DateTime(1990, 1, 1);
      while (d.year < 2000) {
        final r = gregorianToThaiLunar(d);
        expect(r.month, inInclusiveRange(1, 12));
        expect(r.day, inInclusiveRange(1, 15));
        d = d.add(const Duration(days: 1));
      }
    });
  });
}
