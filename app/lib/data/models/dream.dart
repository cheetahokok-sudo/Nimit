import 'source.dart';

/// A symbol detected in a dream.
///
/// [symbolId] and [slug] are populated only when the symbol resolved to a real
/// library entry, so the UI can deep-link into the library; they stay null for
/// locally-derived or unmatched symbols.
class DreamSymbol {
  const DreamSymbol({
    required this.nameTh,
    required this.count,
    this.symbolId,
    this.slug,
  });

  final String nameTh;
  final int count;
  final String? symbolId;
  final String? slug;

  Map<String, dynamic> toJson() => {
        'nameTh': nameTh,
        'count': count,
        if (symbolId != null) 'symbolId': symbolId,
        if (slug != null) 'slug': slug,
      };

  factory DreamSymbol.fromJson(Map<String, dynamic> json) => DreamSymbol(
        nameTh: json['nameTh'] as String,
        count: json['count'] as int,
        symbolId: json['symbolId'] as String?,
        slug: json['slug'] as String?,
      );
}

/// One cultural interpretation, always attributed to a trust-tiered source.
///
/// [quoteTh] carries verbatim source text and is populated **only when the
/// server decides the rights status permits it**. The client never decides
/// whether quoting is lawful — it renders what it is given.
class SymbolInterpretation {
  const SymbolInterpretation({
    required this.tier,
    required this.sourceNameTh,
    required this.textTh,
    this.symbolTh,
    this.summaryPlainTh,
    this.sourceId,
    this.locatorTh,
    this.quoteTh,
    this.contextNoteTh,
  });

  final SourceTier tier;
  final String sourceNameTh;

  /// Which symbol this reading belongs to — lets the UI group plain-language
  /// lines by symbol name.
  final String? symbolTh;

  /// ภาษาชาวบ้าน: the editor's one-to-two-line compression of [textTh],
  /// shown FIRST for readers who will not read long prose. Editorial text
  /// under the same review rules — never generated.
  final String? summaryPlainTh;

  /// Original editorial prose. Always safe to display.
  final String textTh;

  final String? sourceId;

  /// Where in the source the claim appears, e.g. "ผูกที่ ๓ หน้า ๑๒".
  final String? locatorTh;

  final String? quoteTh;

  /// Editorial framing the reader needs alongside the claim — e.g. that
  /// Buddhist dream literature is social prophecy, not lottery guidance.
  final String? contextNoteTh;

  Map<String, dynamic> toJson() => {
        'tier': tier.code,
        'sourceNameTh': sourceNameTh,
        'textTh': textTh,
        if (symbolTh != null) 'symbolTh': symbolTh,
        if (summaryPlainTh != null) 'summaryPlainTh': summaryPlainTh,
        if (sourceId != null) 'sourceId': sourceId,
        if (locatorTh != null) 'locatorTh': locatorTh,
        if (quoteTh != null) 'quoteTh': quoteTh,
        if (contextNoteTh != null) 'contextNoteTh': contextNoteTh,
      };

  factory SymbolInterpretation.fromJson(Map<String, dynamic> json) =>
      SymbolInterpretation(
        tier: SourceTier.fromCode(json['tier'] as String?),
        sourceNameTh: json['sourceNameTh'] as String,
        textTh: json['textTh'] as String,
        symbolTh: json['symbolTh'] as String?,
        summaryPlainTh: json['summaryPlainTh'] as String?,
        sourceId: json['sourceId']?.toString(),
        locatorTh: json['locatorTh'] as String?,
        quoteTh: json['quoteTh'] as String?,
        contextNoteTh: json['contextNoteTh'] as String?,
      );
}

/// Result of analyzing a dream: theme, symbols, sourced interpretations,
/// and symbolic numbers (เลขเชิงสัญลักษณ์ — explicitly not a prediction).
class DreamAnalysis {
  const DreamAnalysis({
    required this.headlineTh,
    required this.themeTh,
    required this.symbols,
    required this.interpretations,
    required this.numbers,
    required this.sourceCount,
  });

  final String headlineTh; // e.g. "งูสีขาว • หน้าบ้าน • ฝนเบา"
  final String themeTh; // e.g. "การเปลี่ยนแปลงที่เข้ามาอย่างสงบ"
  final List<DreamSymbol> symbols;
  final List<SymbolInterpretation> interpretations;
  final List<String> numbers;
  final int sourceCount;

  Map<String, dynamic> toJson() => {
        'headlineTh': headlineTh,
        'themeTh': themeTh,
        'symbols': [for (final s in symbols) s.toJson()],
        'interpretations': [for (final i in interpretations) i.toJson()],
        'numbers': numbers,
        'sourceCount': sourceCount,
      };

  factory DreamAnalysis.fromJson(Map<String, dynamic> json) => DreamAnalysis(
        headlineTh: json['headlineTh'] as String,
        themeTh: json['themeTh'] as String,
        symbols: [
          for (final s in (json['symbols'] as List<dynamic>? ?? []))
            DreamSymbol.fromJson(s as Map<String, dynamic>),
        ],
        interpretations: [
          for (final i in (json['interpretations'] as List<dynamic>? ?? []))
            SymbolInterpretation.fromJson(i as Map<String, dynamic>),
        ],
        numbers: (json['numbers'] as List<dynamic>? ?? []).cast<String>(),
        sourceCount: json['sourceCount'] as int? ?? 0,
      );
}

/// A journal entry: the dream text plus the analysis snapshot worth keeping.
///
/// [analysis] freezes what the user was actually shown. The library is edited
/// continuously, so re-deriving an old entry later would rewrite the user's
/// own history.
///
/// Every field added here must stay nullable or defaulted: entries already
/// persisted under the `nimit.journal.v1` key on user devices are parsed by
/// [fromJson], and a newly-required field would throw on existing data.
class DreamEntry {
  const DreamEntry({
    required this.id,
    required this.text,
    required this.createdAt,
    this.feelingTh,
    this.timeOfNightTh,
    this.headlineTh,
    this.numbers = const [],
    this.analysis,
  });

  final String id;
  final String text;
  final DateTime createdAt;
  final String? feelingTh;
  final String? timeOfNightTh;
  final String? headlineTh;
  final List<String> numbers;
  final DreamAnalysis? analysis;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'feelingTh': feelingTh,
        'timeOfNightTh': timeOfNightTh,
        'headlineTh': headlineTh,
        'numbers': numbers,
        if (analysis != null) 'analysis': analysis!.toJson(),
      };

  factory DreamEntry.fromJson(Map<String, dynamic> json) => DreamEntry(
        id: json['id'] as String,
        text: json['text'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        feelingTh: json['feelingTh'] as String?,
        timeOfNightTh: json['timeOfNightTh'] as String?,
        headlineTh: json['headlineTh'] as String?,
        numbers: (json['numbers'] as List<dynamic>? ?? []).cast<String>(),
        analysis: json['analysis'] == null
            ? null
            : DreamAnalysis.fromJson(json['analysis'] as Map<String, dynamic>),
      );
}
