import 'package:flutter_test/flutter_test.dart';
import 'package:nimit/core/calendar/thai_lunar_birth.dart';

/// The package's own arithmetic is held to published sources in
/// thai_lunar_package_conformance_test.dart. This file tests only what this
/// layer decides: which civil day a birth belongs to, Thai naming, and refusal.
void main() {
  const service = ThaiLunarBirthService();

  group('adhikamat year: the doubled month 8', () {
    // พ.ศ. 2569 is adhikamat, corroborated by วันอาสาฬหบูชา falling in
    // เดือนแปดหลัง on 29 ก.ค. 2569.
    test('a birth in the first month 8 is named เดือนแปดแรก', () {
      final r = service.convert(DateTime(2026, 6, 15));

      expect(r.isAdhikamatYear, isTrue);
      expect(r.lunar.month, 8);
      expect(r.lunar.isSecondEighth, isFalse);
      expect(r.monthOccurrence, ThaiLunarMonthOccurrence.firstEighth);
      expect(r.monthNameTh, 'เดือนแปดแรก');
    });

    test('a birth in the second month 8 is named เดือนแปดหลัง', () {
      final r = service.convert(DateTime(2026, 7, 29));

      expect(r.lunar.month, 8);
      expect(r.lunar.isSecondEighth, isTrue);
      expect(r.monthOccurrence, ThaiLunarMonthOccurrence.secondEighth);
      expect(r.isIntercalaryMonth, isTrue);
      expect(r.monthNameTh, 'เดือนแปดหลัง');
      expect(r.lunarDateTh, 'ขึ้น 15 ค่ำ เดือนแปดหลัง พ.ศ. 2569');
    });

    test('เดือนแปดหลัง is explained as intercalary, not as เดือนเก้า', () {
      // The one thing a user will get wrong unaided: they were born in a month
      // that does not exist in most years, and the next month is still 9.
      final r = service.convert(DateTime(2026, 7, 29));
      expect(r.intercalationNoteTh, contains('เดือนแปดหลัง'));
      expect(r.intercalationNoteTh, contains('ไม่ใช่เดือนเก้า'));
    });

    test('in a normal year month 8 is just เดือนแปด', () {
      // พ.ศ. 2568 is not adhikamat, so no first/second distinction exists and
      // claiming one would be inventing structure.
      final r = service.convert(DateTime(2025, 7, 10));
      if (r.lunar.month == 8) {
        expect(r.monthOccurrence, ThaiLunarMonthOccurrence.standard);
        expect(r.monthNameTh, 'เดือนแปด');
      }
    });
  });

  group('Thai month naming', () {
    test('months 1 and 2 use their names, not their numbers', () {
      // เดือนอ้าย / เดือนยี่ are the whole reason this feature cannot key on a
      // Gregorian month: they fall around November–December.
      const names = {1: 'เดือนอ้าย', 2: 'เดือนยี่'};
      var found = <int>{};
      var d = DateTime(2025, 11, 1);
      while (d.isBefore(DateTime(2026, 3, 1))) {
        final r = service.convert(d);
        if (names.containsKey(r.lunar.month)) {
          expect(r.monthNameTh, names[r.lunar.month]);
          found.add(r.lunar.month);
        }
        d = d.add(const Duration(days: 1));
      }
      expect(found, {1, 2}, reason: 'both months must occur in this window');
    });

    test('เดือนอ้าย sits around Nov-Dec and is never a spring month', () {
      // Pins the fact the whole design rests on: lunar month 1 is not January.
      //
      // It is not *only* Nov–Dec either. A lunar month runs about 29 days, so
      // เดือนอ้าย begins in November or December and spills into early January
      // — 1 ม.ค. 2565 is such a day. The first version of this test asserted
      // Nov–Dec only and failed on exactly that, which is the test being
      // overconfident rather than the calendar being wrong.
      final gregorianMonths = <int>{};
      var d = DateTime(2020, 1, 1);
      while (d.year < 2027) {
        if (service.convert(d).lunar.month == 1) gregorianMonths.add(d.month);
        d = d.add(const Duration(days: 1));
      }

      expect(gregorianMonths.difference({11, 12, 1}), isEmpty,
          reason: 'เดือนอ้าย appeared in $gregorianMonths');
      // And it genuinely is a late-year month, not a January one that happens
      // to touch December.
      expect(gregorianMonths, containsAll(<int>[11, 12]));
    });
  });

  group('day boundary', () {
    test('civil date is the default and never shifts anything', () {
      final r = service.convert(DateTime(2026, 7, 15, 1));
      expect(r.effectiveCivilDate, DateTime(2026, 7, 15));
      expect(r.boundaryPolicy, BirthDayBoundaryPolicy.civilDate);
    });

    test('dawn policy moves a pre-dawn birth to the previous day', () {
      final r = service.convert(
        DateTime(2026, 7, 15, 5, 30),
        boundaryPolicy: BirthDayBoundaryPolicy.thaiDawnApproximation,
      );
      expect(r.effectiveCivilDate, DateTime(2026, 7, 14));
    });

    test('dawn policy leaves a birth at exactly dawn alone', () {
      final r = service.convert(
        DateTime(2026, 7, 15, 6),
        boundaryPolicy: BirthDayBoundaryPolicy.thaiDawnApproximation,
      );
      expect(r.effectiveCivilDate, DateTime(2026, 7, 15));
    });

    test('the two policies can give different lunar months, and say so', () {
      // 15 ก.ค. 2569 opens เดือนแปดหลัง; the day before closes เดือนแปดแรก. So
      // a 05:30 birth genuinely lands in a different month under each policy —
      // which is exactly why the choice is explicit and labelled.
      final civil = service.convert(DateTime(2026, 7, 15, 5, 30));
      final dawn = service.convert(
        DateTime(2026, 7, 15, 5, 30),
        boundaryPolicy: BirthDayBoundaryPolicy.thaiDawnApproximation,
      );

      expect(civil.monthOccurrence, ThaiLunarMonthOccurrence.secondEighth);
      expect(dawn.monthOccurrence, ThaiLunarMonthOccurrence.firstEighth);
      expect(dawn.boundaryNoteTh, contains('ประมาณ'));
    });
  });

  group('refusal', () {
    test('rejects dates below the corroborated range', () {
      expect(() => service.convert(DateTime(1899, 12, 31)), throwsRangeError);
    });

    test('rejects dates above it', () {
      expect(() => service.convert(DateTime(2051, 1, 1)), throwsRangeError);
    });

    test('range is checked on the resolved date, not the entered one', () {
      // 1 Jan 1900 at 03:00 under the dawn policy resolves into 1899. Checking
      // the input year would let it through and convert an out-of-range date.
      expect(
        () => service.convert(
          DateTime(1900, 1, 1, 3),
          boundaryPolicy: BirthDayBoundaryPolicy.thaiDawnApproximation,
        ),
        throwsRangeError,
      );
      // The same instant under the default policy is inside the range.
      expect(service.convert(DateTime(1900, 1, 1, 3)).lunar.beYear,
          isNot(throwsRangeError));
    });
  });

  group('internal consistency', () {
    test('a second month 8 can only occur in an adhikamat year', () {
      // Ties the date-level result to the year-level classification: if these
      // ever disagree the screen would show เดือนแปดหลัง in a year it says has
      // no extra month.
      var d = DateTime(2005, 1, 1);
      while (d.year < 2030) {
        final r = service.convert(d);
        if (r.lunar.isSecondEighth) {
          expect(r.isAdhikamatYear, isTrue,
              reason: '${d.toIso8601String()} → ${r.lunarDateTh}');
        }
        d = d.add(const Duration(days: 1));
      }
    });

    test('year type text is never empty and matches the flags', () {
      final r = service.convert(DateTime(2026, 7, 29));
      expect(r.yearTypeTh, 'อธิกมาส · ปกติวาร');
      expect(r.isAdhikamatYear, isTrue);
      expect(r.isAdhikawanYear, isFalse);
    });
  });

  group('derived facts', () {
    test('วันเกิด is the real weekday', () {
      // 29 ก.ค. 2569 was a Wednesday.
      expect(service.convert(DateTime(2026, 7, 29)).weekdayTh, 'วันพุธ');
      expect(service.convert(DateTime(2026, 7, 30)).weekdayTh, 'วันพฤหัสบดี');
      expect(service.convert(DateTime(2026, 8, 2)).weekdayTh, 'วันอาทิตย์');
    });

    test('วันเกิด honours the dawn boundary, which is the point of it', () {
      // A 03:00 Monday birth is a Sunday birth in Thai reckoning. This is the
      // payoff for making the boundary policy explicit instead of assuming one
      // — the weekday is what ทักษา keys on, so getting it wrong would poison
      // every future reading built on it.
      final monday = DateTime(2026, 7, 27, 3);
      expect(service.convert(monday).weekdayTh, 'วันจันทร์');
      expect(
        service
            .convert(monday,
                boundaryPolicy: BirthDayBoundaryPolicy.thaiDawnApproximation)
            .weekdayTh,
        'วันอาทิตย์',
      );
    });

    test('ปีนักษัตร matches known years', () {
      // พ.ศ. 2569 is ปีมะเมีย, 2568 ปีมะเส็ง, 2567 ปีมะโรง.
      expect(service.convert(DateTime(2026, 7, 29)).zodiacYearTh, 'มะเมีย');
      expect(service.convert(DateTime(2025, 7, 10)).zodiacYearTh, 'มะเส็ง');
      expect(service.convert(DateTime(2024, 7, 10)).zodiacYearTh, 'มะโรง');
    });

    test('ปีนักษัตร cycles through all twelve without repeating', () {
      final seen = <String>[];
      for (var y = 2015; y < 2027; y++) {
        seen.add(service.convert(DateTime(y, 7, 10)).zodiacYearTh);
      }
      expect(seen.toSet().length, 12, reason: '\$seen');
    });

    test('an early-year birth is flagged as reckoning-sensitive', () {
      // The royal calendar turns the นักษัตร year at สงกรานต์, traditional
      // lunar reckoning at the lunar year. They disagree for Jan-Apr births, so
      // the screen must not present one answer as the answer.
      final early = service.convert(DateTime(2000, 2, 10));
      expect(early.zodiacIsBoundarySensitive, isTrue);
      expect(early.zodiacNoteTh, contains('สงกรานต์'));

      final midYear = service.convert(DateTime(2000, 8, 10));
      expect(midYear.zodiacIsBoundarySensitive, isFalse);
      expect(midYear.zodiacNoteTh, isNot(contains('สงกรานต์')));
    });
  });
}
