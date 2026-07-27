import 'package:thai_lunar/thai_lunar.dart';

import '../utils/thai_date.dart';

/// Resolving a birth date to a Thai lunar date, for ดวงของฉัน.
///
/// The arithmetic is package:thai_lunar. This repo implemented สุริยยาตร์
/// independently first, from J. C. Eade (JSS 88, 2000), and then deleted it:
/// a 19-year Metonic rule fitted to Eade's 1958–78 table and to พ.ศ. 2561–2569
/// still gets พ.ศ. 2555 wrong, and the package gets it right. See
/// test/thai_lunar_package_conformance_test.dart, which holds the package to
/// the published sources rather than the other way round.
///
/// What this layer adds is everything the package deliberately does not decide:
/// which civil day a birth belongs to, how to name the result in Thai, and how
/// to refuse politely when asked something it cannot answer.

/// How a birth time resolves to a civil date.
enum BirthDayBoundaryPolicy {
  /// Use the date exactly as entered. The default, because it is the only
  /// option that cannot silently move somebody's birthday.
  civilDate,

  /// Treat a time before dawn as belonging to the previous day, the way Thai
  /// day-reckoning traditionally does.
  ///
  /// An approximation, and never applied without being asked for: real dawn in
  /// Thailand runs roughly 05:40–06:30 depending on latitude and season, so a
  /// birth inside that band can land either side of the boundary. A user who
  /// was not offered the choice would have no way to know their reading came
  /// from a different day than the one on their ID card.
  thaiDawnApproximation,
}

/// Which occurrence of month 8 a date falls in.
///
/// Only meaningful in an อธิกมาส year, where เดือน ๘ runs twice. Kept as an
/// enum rather than a magic month number: an earlier draft of this code used
/// `88` to mean เดือนแปดหลัง, and a value outside 1–12 in a field called
/// "month" is the same defect as a lottery `matchKind` that guesses — anything
/// comparing or sorting on it is wrong without warning. The package already
/// models it correctly as `month: 8` plus `isSecondEighth`.
enum ThaiLunarMonthOccurrence { standard, firstEighth, secondEighth }

class ThaiLunarBirth {
  const ThaiLunarBirth({
    required this.inputDateTime,
    required this.effectiveCivilDate,
    required this.lunar,
    required this.yearType,
    required this.boundaryPolicy,
  });

  final DateTime inputDateTime;

  /// The civil date actually converted, which differs from [inputDateTime]
  /// only under [BirthDayBoundaryPolicy.thaiDawnApproximation]. Surfaced so a
  /// screen can show its work instead of asking to be believed.
  final DateTime effectiveCivilDate;

  final ThaiLunarDate lunar;
  final ThaiLunarYearType yearType;
  final BirthDayBoundaryPolicy boundaryPolicy;

  bool get isAdhikamatYear => yearType == ThaiLunarYearType.extraMonth;
  bool get isAdhikawanYear => yearType == ThaiLunarYearType.extraDay;
  bool get isIntercalaryMonth => lunar.isSecondEighth;

  ThaiLunarMonthOccurrence get monthOccurrence {
    if (lunar.month != 8) return ThaiLunarMonthOccurrence.standard;
    if (lunar.isSecondEighth) return ThaiLunarMonthOccurrence.secondEighth;
    return isAdhikamatYear
        ? ThaiLunarMonthOccurrence.firstEighth
        : ThaiLunarMonthOccurrence.standard;
  }

  String get phaseTh => lunar.phase == MoonPhase.waxing ? 'ขึ้น' : 'แรม';

  static const _monthNames = <int, String>{
    1: 'เดือนอ้าย',
    2: 'เดือนยี่',
    3: 'เดือนสาม',
    4: 'เดือนสี่',
    5: 'เดือนห้า',
    6: 'เดือนหก',
    7: 'เดือนเจ็ด',
    9: 'เดือนเก้า',
    10: 'เดือนสิบ',
    11: 'เดือนสิบเอ็ด',
    12: 'เดือนสิบสอง',
  };

  String get monthNameTh {
    if (lunar.month == 8) {
      return switch (monthOccurrence) {
        ThaiLunarMonthOccurrence.firstEighth => 'เดือนแปดแรก',
        ThaiLunarMonthOccurrence.secondEighth => 'เดือนแปดหลัง',
        ThaiLunarMonthOccurrence.standard => 'เดือนแปด',
      };
    }
    return _monthNames[lunar.month] ?? 'เดือน ${lunar.month}';
  }

  String get yearTypeTh => switch (yearType) {
        ThaiLunarYearType.normal => 'ปกติมาส · ปกติวาร',
        ThaiLunarYearType.extraDay => 'ปกติมาส · อธิกวาร',
        ThaiLunarYearType.extraMonth => 'อธิกมาส · ปกติวาร',
      };

  String get lunarDateTh =>
      '$phaseTh ${lunar.day} ค่ำ $monthNameTh พ.ศ. ${lunar.beYear}';

  /// The same date in the register a ตำรา uses: Thai numerals, no year.
  ///
  /// "ขึ้น ๑๒ ค่ำ เดือนห้า" is how the tradition names a day, and it is what
  /// the screen leads with. [lunarDateTh] keeps Arabic digits and the year for
  /// places that need to be read as data rather than felt.
  String get lunarDateArchaicTh =>
      '$phaseTh ${thaiDigits(lunar.day)} ค่ำ $monthNameTh';


  static const _weekdayNames = <String>[
    'วันจันทร์',
    'วันอังคาร',
    'วันพุธ',
    'วันพฤหัสบดี',
    'วันศุกร์',
    'วันเสาร์',
    'วันอาทิตย์',
  ];

  /// วันเกิด — the day of the week.
  ///
  /// Read off [effectiveCivilDate], not the entered date, so it honours the
  /// dawn boundary: under that policy a 03:00 Monday birth is a Sunday birth,
  /// which is the whole reason Thai reckoning has the rule. This is the payoff
  /// for making the policy explicit rather than assuming one.
  ///
  /// A pure calendar fact — no convention, no source needed. It matters because
  /// Thai divination overwhelmingly keys on วันเกิด (ทักษา) rather than on the
  /// month, so any future reading will want it.
  String get weekdayTh => _weekdayNames[effectiveCivilDate.weekday - 1];

  static const _zodiacNames = <String>[
    'ชวด',
    'ฉลู',
    'ขาล',
    'เถาะ',
    'มะโรง',
    'มะเส็ง',
    'มะเมีย',
    'มะแม',
    'วอก',
    'ระกา',
    'จอ',
    'กุน',
  ];

  /// ปีนักษัตร, reckoned on the LUNAR year.
  ///
  /// CONVENTION, STATED BECAUSE IT IS CONTESTED. Thai practice does not agree
  /// on when the นักษัตร year turns: the royal/official calendar changes it at
  /// สงกรานต์, while traditional lunar reckoning changes it with the lunar
  /// year. This uses [ThaiLunarDate.beYear] — the lunar year the package
  /// computed — so the boundary is at least internally consistent with the
  /// month shown beside it.
  ///
  /// For a birth in January–April the two conventions disagree, which is why
  /// [zodiacNoteTh] says so on screen instead of presenting one answer as the
  /// answer. A ตำรา that specifies its own reckoning would override this.
  String get zodiacYearTh => _zodiacNames[(lunar.beYear + 5) % 12];

  /// True when the two นักษัตร reckonings can disagree for this birth.
  bool get zodiacIsBoundarySensitive =>
      effectiveCivilDate.month >= 1 && effectiveCivilDate.month <= 4;

  String get zodiacNoteTh => zodiacIsBoundarySensitive
      ? 'นับปีนักษัตรตามปีจันทรคติ ถ้านับแบบเปลี่ยนปีที่สงกรานต์อาจได้คนละปีนักษัตร '
          'เพราะคุณเกิดต้นปี'
      : 'นับปีนักษัตรตามปีจันทรคติ';

  String get boundaryNoteTh => switch (boundaryPolicy) {
        BirthDayBoundaryPolicy.civilDate => 'นับตามวันที่ในปฏิทินที่กรอกไว้',
        BirthDayBoundaryPolicy.thaiDawnApproximation =>
          'เกิดก่อนรุ่งสาง นับเป็นวันก่อนหน้าตามธรรมเนียมไทย (เป็นการประมาณ)',
      };

  String get intercalationNoteTh {
    if (isIntercalaryMonth) {
      return 'ปีนี้มีเดือนแปดสองหน คุณเกิดในเดือนแปดหลัง ซึ่งเป็นเดือนที่แทรกเพิ่ม ไม่ใช่เดือนเก้า';
    }
    return switch (monthOccurrence) {
      ThaiLunarMonthOccurrence.firstEighth =>
        'ปีนี้มีเดือนแปดสองหน คุณเกิดในเดือนแปดแรก',
      _ when isAdhikawanYear => 'ปีนี้เป็นปีอธิกวาร มีการเพิ่มหนึ่งวันในเดือนเจ็ด',
      _ => 'ปีจันทรคตินี้ไม่มีเดือนหรือวันแทรก',
    };
  }
}

class ThaiLunarBirthService {
  const ThaiLunarBirthService({
    this.minSupportedCe = 1900,
    this.maxSupportedCe = 2050,
    this.dawnHour = 6,
  }) : assert(dawnHour >= 0 && dawnHour <= 23);

  /// Bounds on what this will answer at all.
  ///
  /// Not a claim of accuracy across the whole span — the conformance suite
  /// corroborates the package against published sources for roughly พ.ศ.
  /// 2450–2620, and nobody has checked the tails. The guard exists so that a
  /// date outside any plausible birth range throws instead of returning a
  /// confident wrong month, which is the behaviour every other unverifiable
  /// input in this app already has.
  final int minSupportedCe;
  final int maxSupportedCe;

  /// Approximate dawn, used only under [BirthDayBoundaryPolicy.thaiDawnApproximation].
  final int dawnHour;

  ThaiLunarBirth convert(
    DateTime birthDateTime, {
    BirthDayBoundaryPolicy boundaryPolicy = BirthDayBoundaryPolicy.civilDate,
  }) {
    var effective = DateTime(
      birthDateTime.year,
      birthDateTime.month,
      birthDateTime.day,
    );

    if (boundaryPolicy == BirthDayBoundaryPolicy.thaiDawnApproximation &&
        birthDateTime.hour < dawnHour) {
      effective = effective.subtract(const Duration(days: 1));
    }

    // Range-check the date actually converted, not the one entered: a 1 Jan
    // 1900 birth at 03:00 under the dawn policy resolves into 1899.
    if (effective.year < minSupportedCe || effective.year > maxSupportedCe) {
      throw RangeError.range(
        effective.year,
        minSupportedCe,
        maxSupportedCe,
        'birthDateTime.year',
        'Thai lunar conversion is only offered inside the corroborated range',
      );
    }

    final lunar = gregorianToThaiLunar(effective);

    // Classify the LUNAR year the result reports, not the Gregorian year that
    // was entered. A Thai lunar year straddles 1 January, so a birth in early
    // January belongs to the previous lunar year and takes its type.
    final type = lunarYearType(lunar.beYear);

    return ThaiLunarBirth(
      inputDateTime: birthDateTime,
      effectiveCivilDate: effective,
      lunar: lunar,
      yearType: type,
      boundaryPolicy: boundaryPolicy,
    );
  }
}
