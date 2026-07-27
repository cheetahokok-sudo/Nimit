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
