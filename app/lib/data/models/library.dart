import 'source.dart';

/// One sourced reading of a symbol, as shown on the story screen.
class SymbolReading {
  const SymbolReading({
    required this.tier,
    required this.workTh,
    this.sourceTh,
    this.custodianTh,
    this.locatorTh,
    this.bodyTh,
    this.plainTh,
    this.traditionTh,
    this.quoteTh,
    this.contextNoteTh,
  });

  final SourceTier tier;
  final String workTh;
  final String? sourceTh;
  final String? custodianTh;
  final String? locatorTh;
  final String? bodyTh;
  final String? plainTh;
  final String? traditionTh;

  /// Verbatim source text. Present ONLY where the underlying work is free —
  /// the server decides this, never the client.
  final String? quoteTh;
  final String? contextNoteTh;

  factory SymbolReading.fromJson(Map<String, dynamic> json) => SymbolReading(
        tier: SourceTier.fromCode(json['tier'] as String?),
        workTh: json['workTh'] as String? ?? '',
        sourceTh: json['sourceTh'] as String?,
        custodianTh: json['custodianTh'] as String?,
        locatorTh: json['locatorTh'] as String?,
        bodyTh: json['bodyTh'] as String?,
        plainTh: json['plainTh'] as String?,
        traditionTh: json['traditionTh'] as String?,
        quoteTh: json['quoteTh'] as String?,
        contextNoteTh: json['contextNoteTh'] as String?,
      );
}

class RelatedSymbol {
  const RelatedSymbol({required this.slug, required this.nameTh, this.kind});

  final String slug;
  final String nameTh;
  final String? kind;

  factory RelatedSymbol.fromJson(Map<String, dynamic> json) => RelatedSymbol(
        slug: json['slug'] as String? ?? '',
        nameTh: json['nameTh'] as String? ?? '',
        kind: json['kind'] as String?,
      );
}

/// The full story of one symbol: what it means, where that comes from, and
/// which numbers ตำรา tie to it.
///
/// Deliberately assembled server-side in one call. The tier badge is joined
/// from the edition rather than stored per reading, so a badge can never
/// disagree with the bibliography it cites.
class SymbolStory {
  const SymbolStory({
    required this.slug,
    required this.nameTh,
    required this.category,
    required this.numbers,
    required this.readings,
    required this.related,
    required this.narrower,
    this.nameEn,
    this.summaryTh,
    this.ethicsNoteTh,
  });

  final String slug;
  final String nameTh;
  final String category;
  final List<String> numbers;
  final List<SymbolReading> readings;
  final List<RelatedSymbol> related;
  final List<RelatedSymbol> narrower;
  final String? nameEn;
  final String? summaryTh;
  final String? ethicsNoteTh;

  bool get hasReadings => readings.isNotEmpty;
  bool get hasNumbers => numbers.isNotEmpty;

  factory SymbolStory.fromJson(Map<String, dynamic> json) => SymbolStory(
        slug: json['slug'] as String? ?? '',
        nameTh: json['nameTh'] as String? ?? '',
        category: json['category'] as String? ?? '',
        nameEn: json['nameEn'] as String?,
        summaryTh: json['summaryTh'] as String?,
        ethicsNoteTh: json['ethicsNoteTh'] as String?,
        numbers: [
          for (final n in (json['numbers'] as List<dynamic>? ?? const [])) '$n',
        ],
        readings: [
          for (final r in (json['readings'] as List<dynamic>? ?? const []))
            SymbolReading.fromJson(r as Map<String, dynamic>),
        ],
        related: [
          for (final r in (json['related'] as List<dynamic>? ?? const []))
            RelatedSymbol.fromJson(r as Map<String, dynamic>),
        ],
        narrower: [
          for (final r in (json['narrower'] as List<dynamic>? ?? const []))
            RelatedSymbol.fromJson(r as Map<String, dynamic>),
        ],
      );
}

/// A ทักษา reading for a day of the week, as returned by `api.taksa_birthday`.
///
/// [readings] is EMPTY when nothing is published yet, which is the current
/// state: the only source is a single copyrighted 1963 printing of พรหมชาติ, so
/// every row sits at draft pending a second witness. Empty is a real answer and
/// the screen renders an honest empty state for it — it is not an error and
/// must not be reported as one.
class TaksaReading {
  const TaksaReading({
    required this.slug,
    required this.nameTh,
    required this.weekday,
    required this.readings,
  });

  final String slug;
  final String nameTh;

  /// 1=Monday .. 7=Sunday, matching DateTime.weekday.
  final int weekday;

  final List<TaksaEntry> readings;

  bool get hasReading => readings.isNotEmpty;

  factory TaksaReading.fromJson(Map<String, dynamic> json) => TaksaReading(
        slug: json['slug'] as String? ?? '',
        nameTh: json['nameTh'] as String? ?? '',
        weekday: (json['weekday'] as num?)?.toInt() ?? 0,
        readings: [
          for (final r in (json['readings'] as List? ?? const []))
            TaksaEntry.fromJson(r as Map<String, dynamic>)
        ],
      );
}

class TaksaEntry {
  const TaksaEntry({
    required this.bodyTh,
    required this.summaryTh,
    required this.contextNoteTh,
    required this.sourceTh,
  });

  final String bodyTh;
  final String summaryTh;
  final String contextNoteTh;

  /// A single rendered citation line. Assembled here rather than in the widget
  /// so a reading can never appear on screen without one.
  final String sourceTh;

  factory TaksaEntry.fromJson(Map<String, dynamic> json) {
    final s = json['source'] as Map<String, dynamic>? ?? const {};
    final parts = <String>[
      if (s['titleTh'] != null) s['titleTh'] as String,
      if (s['authorTh'] != null) s['authorTh'] as String,
      if (s['yearBe'] != null) 'พ.ศ. ${s['yearBe']}',
      if (s['locator'] != null) s['locator'] as String,
    ];
    return TaksaEntry(
      bodyTh: json['bodyTh'] as String? ?? '',
      summaryTh: json['summaryTh'] as String? ?? '',
      contextNoteTh: json['contextNoteTh'] as String? ?? '',
      sourceTh: parts.join(' · '),
    );
  }
}

/// วงราศีตามอายุ — the พรหมชาติ age-wheel verdict, as returned by
/// `api.agewheel_age`.
///
/// The ตำรา counts twelve figures from เจดีย์, one step per year of age, with
/// men going one way round the circle and women the other. This model carries
/// BOTH results rather than one, because the app never asks the user's sex —
/// see the API migration for why. The screen labels the two and shows them
/// side by side.
///
/// [male] and [female] are null when the wheel symbols are not published, and
/// their [AgeWheelFigure.readings] are empty when the symbols exist but no
/// reading has cleared the two-source rule. Both are real answers, not errors,
/// and the screen renders an honest empty state for them.
class AgeWheelReading {
  const AgeWheelReading({
    required this.age,
    required this.male,
    required this.female,
  });

  /// Completed years, matching what the client sent. The ตำรา says
  /// เท่าจำนวนอายุปัจจุบัน without settling whether the year of birth counts as
  /// year one, so the screen states which convention it used.
  final int age;

  final AgeWheelFigure? male;
  final AgeWheelFigure? female;

  bool get hasAnyReading =>
      (male?.readings.isNotEmpty ?? false) ||
      (female?.readings.isNotEmpty ?? false);

  /// True when the figures resolved but carry no published reading — the
  /// expected state until the compilation is corroborated.
  bool get hasFiguresOnly =>
      (male != null || female != null) && !hasAnyReading;

  factory AgeWheelReading.fromJson(Map<String, dynamic> json) {
    AgeWheelFigure? figure(String key) {
      final raw = json[key];
      return raw is Map<String, dynamic> ? AgeWheelFigure.fromJson(raw) : null;
    }

    return AgeWheelReading(
      age: (json['age'] as num?)?.toInt() ?? 0,
      male: figure('male'),
      female: figure('female'),
    );
  }

  static AgeWheelReading empty(int age) =>
      AgeWheelReading(age: age, male: null, female: null);
}

/// One figure on the wheel, with whatever readings have been published for it.
class AgeWheelFigure {
  const AgeWheelFigure({
    required this.position,
    required this.slug,
    required this.nameTh,
    required this.readings,
  });

  /// 1–12, counted from เจดีย์. Provisional: หน้า ๓'s diagram orders the
  /// figures differently from the numbered list on หน้า ๑–๒, and that is not
  /// settled. Recorded so the screen can show it and be checked against the
  /// book rather than trusted.
  final int position;

  final String slug;
  final String nameTh;
  final List<TaksaEntry> readings;

  factory AgeWheelFigure.fromJson(Map<String, dynamic> json) => AgeWheelFigure(
        position: (json['position'] as num?)?.toInt() ?? 0,
        slug: json['slug'] as String? ?? '',
        nameTh: json['nameTh'] as String? ?? '',
        readings: [
          for (final r in (json['readings'] as List? ?? const []))
            TaksaEntry.fromJson(r as Map<String, dynamic>),
        ],
      );
}
