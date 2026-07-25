import 'source.dart';

/// A symbol detected in a dream, with its count of textual cues.
class DreamSymbol {
  const DreamSymbol({required this.nameTh, required this.count});

  final String nameTh;
  final int count;

  Map<String, dynamic> toJson() => {'nameTh': nameTh, 'count': count};

  factory DreamSymbol.fromJson(Map<String, dynamic> json) => DreamSymbol(
        nameTh: json['nameTh'] as String,
        count: json['count'] as int,
      );
}

/// One cultural interpretation, always attributed to a trust-tiered source.
class SymbolInterpretation {
  const SymbolInterpretation({
    required this.tier,
    required this.sourceNameTh,
    required this.textTh,
  });

  final SourceTier tier;
  final String sourceNameTh;
  final String textTh;
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
}

/// A journal entry: the dream text plus the analysis snapshot worth keeping.
class DreamEntry {
  const DreamEntry({
    required this.id,
    required this.text,
    required this.createdAt,
    this.feelingTh,
    this.timeOfNightTh,
    this.headlineTh,
    this.numbers = const [],
  });

  final String id;
  final String text;
  final DateTime createdAt;
  final String? feelingTh;
  final String? timeOfNightTh;
  final String? headlineTh;
  final List<String> numbers;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'feelingTh': feelingTh,
        'timeOfNightTh': timeOfNightTh,
        'headlineTh': headlineTh,
        'numbers': numbers,
      };

  factory DreamEntry.fromJson(Map<String, dynamic> json) => DreamEntry(
        id: json['id'] as String,
        text: json['text'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        feelingTh: json['feelingTh'] as String?,
        timeOfNightTh: json['timeOfNightTh'] as String?,
        headlineTh: json['headlineTh'] as String?,
        numbers: (json['numbers'] as List<dynamic>? ?? []).cast<String>(),
      );
}
