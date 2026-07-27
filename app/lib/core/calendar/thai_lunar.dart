/// สุริยยาตร์ — the arithmetic behind the Thai luni-solar calendar.
///
/// WHY THIS FILE IS NARROW ON PURPOSE.
///
/// ดวงของฉัน needs the Thai lunar MONTH of a birth date, because every ตำรา
/// that reads by เดือนเกิด means เดือนอ้าย/ยี่/สาม — not January. เดือนอ้าย
/// falls around November–December, so mapping "month 1" to January is wrong at
/// the level of the system, not by a few days.
///
/// The conversion is not derivable from a Gregorian month alone: the lunar year
/// is 354, 355 or 384 days depending on whether an extra day lands in month 7
/// (อธิกวาร / adhikawan) or month 8 repeats (อธิกมาส / adhikamat). Which of
/// those happens depends on the year. So the input has to be a full date.
///
/// SOURCE. J. C. Eade, "Rules for interpolation in the Thai calendar:
/// Suriyayatra versus the Sasana", Journal of the Siam Society 88.1 & 2 (2000)
/// pp. 195–203. The four stages below are Appendix A, stages 1–5, and the
/// adhikawan thresholds are quoted verbatim from p. 196. Eade's worked example
/// for CS 1325 is pinned as a test, so a mistyped constant fails immediately
/// rather than shifting somebody's birth month by a year.
///
/// WHAT THIS CANNOT DO, STATED UP FRONT. Eade's conclusion about the
/// ecclesiastical rule is blunt: it is "inoperable, false", and "we have no
/// guarantee that the precise and accurate suriyaytara rule will be obeyed."
/// Prasert na Nagara found that historically intercalation had no fixed
/// principles at all. So a computed lunar month is *a* defensible answer, not
/// the only one — the ปฏิทินหลวง can and does differ in individual years. Any
/// screen built on this must say which system it used, which is why
/// [ThaiLunarDate] carries [system] rather than presenting a bare month.
library;

/// Which authority produced a lunar date. Displayed, never hidden: two systems
/// legitimately disagree, and a user comparing the app against a temple
/// calendar deserves to know which one they are looking at.
enum ThaiCalendarSystem {
  /// Computed here, from the สุริยยาตร์ arithmetic.
  suriyayatra,

  /// Taken from an authoritative published calendar. No such table ships yet;
  /// the enum exists so adding one later is not a breaking change.
  royalAlmanac,
}

/// How many months a Chulasakarat year holds, and whether month 7 gained a day.
enum ThaiYearType {
  /// 12 months, 354 days.
  normal,

  /// อธิกวาร — 12 months, 355 days: month 7 takes 30 days instead of 29.
  adhikawan,

  /// อธิกมาส — 13 months, 384 days: month 8 is repeated (เดือน ๘ สองหน).
  adhikamat,
}

/// The intermediate quantities of the สุริยยาตร์ New Year computation.
///
/// Exposed rather than kept private because they are the only things that can
/// be checked against the literature — Eade prints all five for CS 1325, and
/// the test asserts every one. A wrapper that only exposed a final month would
/// be untestable against any published source.
class SuriyayatraYear {
  const SuriyayatraYear({
    required this.csYear,
    required this.horakhun,
    required this.kammacubala,
    required this.uccabala,
    required this.avoman,
    required this.masaken,
    required this.newYearDay,
  });

  /// Chulasakarat (จุลศักราช) year.
  final int csYear;

  /// หรคุณ — days elapsed since the epoch, 25 March 638 AD.
  final int horakhun;

  /// กัมมัชผล — declares a leap solar year at 207 or less.
  final int kammacubala;

  /// อุจจพล — position of the moon's apogee. Carried for completeness; the
  /// adhikawan decision does not read it.
  final int uccabala;

  /// อวมาน — declares an extra day, against a threshold that depends on
  /// whether the solar year is leap.
  final int avoman;

  /// มาสเกณฑ์ — elapsed synodic months.
  final int masaken;

  /// The remainder from the masaken division: New Year's day.
  final int newYearDay;

  /// Eade p. 196: "if the kammacubala value is 207 or less, then the year is a
  /// leap year."
  bool get isSolarLeap => kammacubala <= 207;

  /// Eade p. 196, verbatim: "in a leap year, if the avoman is 126 or less, the
  /// year will have an extra day / in a normal year, if the avoman is 137 or
  /// less the year will have an extra day."
  ///
  /// This is the raw suriyayatra verdict. The Thai subsidiary rule — that a
  /// year with an extra month may not also take an extra day — is applied in
  /// [ThaiLunarCalendar.yearType], not here, so the two rules stay separable
  /// and separately testable.
  bool get wantsExtraDay => isSolarLeap ? avoman <= 126 : avoman <= 137;
}

class ThaiLunarCalendar {
  const ThaiLunarCalendar._();

  /// Appendix A stages 1–5. Every constant is from the paper; none is tuned.
  ///
  /// Integer arithmetic throughout and no doubles anywhere: these are exact
  /// quotient-and-remainder operations, and a floating-point intermediate would
  /// round a boundary year to the wrong side without any visible symptom.
  static SuriyayatraYear yearValues(int csYear) {
    // A1. horakhun = (cs * 292207 + 373) / 800 + 1, remainder retained.
    final a = csYear * 292207 + 373;
    final horakhun = a ~/ 800 + 1;
    final remainder = a % 800;

    // A2. kammacubala = 800 - remainder.
    final kammacubala = 800 - remainder;

    // A3. uccabala = (horakhun + 2611) mod 3232.
    final uccabala = (horakhun + 2611) % 3232;

    // A4. avoman = (horakhun * 11 + 650) mod 692, quotient carried to A5.
    final b = horakhun * 11 + 650;
    final avomanQuotient = b ~/ 692;
    final avoman = b % 692;

    // A5. masaken = (avomanQuotient + horakhun) / 30, remainder = New Year day.
    final c = avomanQuotient + horakhun;
    final masaken = c ~/ 30;
    final newYearDay = c % 30;

    return SuriyayatraYear(
      csYear: csYear,
      horakhun: horakhun,
      kammacubala: kammacubala,
      uccabala: uccabala,
      avoman: avoman,
      masaken: masaken,
      newYearDay: newYearDay,
    );
  }

  /// Months contained in a Chulasakarat year, from the growth of มาสเกณฑ์.
  ///
  /// masaken counts elapsed synodic months, so the months belonging to year Y
  /// are masaken(Y+1) - masaken(Y): 13 means month 8 repeated.
  static int monthsInYear(int csYear) =>
      yearValues(csYear + 1).masaken - yearValues(csYear).masaken;

  /// Classify a year by the masaken-growth derivation.
  ///
  /// UNVERIFIED, AND KNOWN TO DIVERGE. Do not build a user-facing month on
  /// this yet.
  ///
  /// The stages this rests on ([yearValues]) reproduce Eade's printed example
  /// exactly. This classifier does not: across his table for CS 1320–1340 it
  /// agrees on the count of intercalary years (8 in 20) and on the 3-3-2
  /// rhythm, but places four of the eight a year early —
  ///
  ///   Eade:   1320 1323 1326 1328 1331 1334 1337 1339
  ///   here:   1320 1322 1325 1328 1331 1333 1336 1339
  ///
  /// The offset is not constant, so it is not an indexing slip; deriving
  /// adhikamat from masaken growth is simply not the rule the Thai calendar
  /// follows. Eade's own position (pp. 197–199) is that the ecclesiastical rule
  /// is "inoperable, false" and that even the suriyayatra rule carries "no
  /// guarantee" of being obeyed, so the placement most likely has to come from
  /// published calendar data rather than from arithmetic at all.
  ///
  /// Tuning the constants until these 21 years agreed would be fitting to 21
  /// data points, and would put a wrong birth month in front of a user with no
  /// symptom. So this stays labelled instead.
  static ThaiYearType suriyayatraYearType(int csYear) {
    if (monthsInYear(csYear) == 13) return ThaiYearType.adhikamat;
    return yearValues(csYear).wantsExtraDay
        ? ThaiYearType.adhikawan
        : ThaiYearType.normal;
  }
}
