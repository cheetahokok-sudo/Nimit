/// Whether a งวด's results may be treated as final.
///
/// Fails closed to [unknown]. The direction matters and is not symmetric: an
/// unrecognised status resolving to [announced] would let the app render
/// "ไม่ถูกรางวัล" against results it does not understand. Resolving to
/// [unknown] only withholds a verdict, which is always recoverable.
enum DrawStatus {
  /// Draw date known, no numbers yet.
  scheduled,

  /// Mid-announcement. GLO publishes รางวัลที่ 1 and เลขท้าย 2 ตัว first and
  /// completes the rest over roughly two hours. Numbers present are real, but
  /// an absent number does NOT mean a ticket lost.
  partial,

  /// All nine tiers present. Only this state permits a losing verdict.
  announced,

  /// A published result was later corrected by GLO.
  superseded,

  unknown;

  static DrawStatus fromCode(String? code) => switch (code) {
        'scheduled' => DrawStatus.scheduled,
        'partial' => DrawStatus.partial,
        'announced' => DrawStatus.announced,
        'superseded' => DrawStatus.superseded,
        _ => DrawStatus.unknown,
      };
}

/// How a ticket number is compared against a prize number.
///
/// Returns null on an unknown code rather than defaulting. There is no safe
/// default: guessing [exact6] invents a prize, and silently dropping the tier
/// hides one. The only correct response to a rule this build does not
/// understand is to refuse a verdict — see [DrawResult.hasUnreadableTier].
enum MatchKind {
  exact6,
  prefix3,
  suffix3,
  suffix2;

  static MatchKind? fromCode(String? code) => switch (code) {
        'exact6' => MatchKind.exact6,
        'prefix3' => MatchKind.prefix3,
        'suffix3' => MatchKind.suffix3,
        'suffix2' => MatchKind.suffix2,
        _ => null,
      };
}

/// One prize tier of a draw, with its winning numbers and its money.
///
/// [amountThb] arrives from the server inside the same object as [numbers].
/// It is never a constant in this app: a client holding this งวด's numbers
/// beside a previous structure's amounts would show a user the wrong figure.
class PrizeTierResult {
  const PrizeTierResult({
    required this.code,
    required this.nameTh,
    required this.shortNameTh,
    required this.amountThb,
    required this.winnerCount,
    required this.matchKind,
    required this.sort,
    required this.numbers,
  });

  final String code;
  final String nameTh;
  final String shortNameTh;
  final int amountThb;
  final int winnerCount;

  /// Null when this build does not recognise the server's match rule.
  final MatchKind? matchKind;
  final int sort;
  final List<String> numbers;

  factory PrizeTierResult.fromJson(Map<String, dynamic> json) =>
      PrizeTierResult(
        code: json['code'] as String? ?? '',
        nameTh: json['nameTh'] as String? ?? '',
        shortNameTh: json['shortNameTh'] as String? ?? '',
        amountThb: (json['amountThb'] as num?)?.toInt() ?? 0,
        winnerCount: (json['winnerCount'] as num?)?.toInt() ?? 0,
        matchKind: MatchKind.fromCode(json['matchKind'] as String?),
        sort: (json['sort'] as num?)?.toInt() ?? 0,
        numbers: [
          for (final n in (json['numbers'] as List<dynamic>? ?? const []))
            '$n',
        ],
      );
}

/// A full draw: the numbers, the money that prices them, and the provenance.
class DrawResult {
  const DrawResult({
    required this.drawDate,
    required this.periodLabelTh,
    required this.status,
    required this.resultRevision,
    required this.complete,
    required this.hasUnreadableTier,
    required this.dutyRate,
    required this.prizes,
    required this.sourceCustodianTh,
    this.sourceUrl,
    this.licenceTh,
    this.retrievedAt,
    this.nextDrawDate,
    this.nextDrawEstimated = true,
    this.pdfUrl,
  });

  /// Calendar date of the งวด. Parsed to local midnight and used ONLY for
  /// display and (y, m, d) comparison — never converted to UTC and never
  /// compared against [DateTime.now] as an instant.
  final DateTime drawDate;
  final String periodLabelTh;
  final DrawStatus status;
  final int resultRevision;

  /// Server-computed: every tier present with its full complement of numbers.
  /// Deliberately not derived in the client — it is the gate that decides
  /// whether a losing verdict may be shown at all.
  final bool complete;

  /// At least one tier used a match rule this build does not know.
  final bool hasUnreadableTier;

  /// Stamp duty withheld at claim time (0.005). CARRIED, NEVER APPLIED to a
  /// displayed figure — prize amounts are shown gross by product decision, and
  /// the duty is surfaced separately as claim guidance.
  final double dutyRate;

  final List<PrizeTierResult> prizes;
  final String sourceCustodianTh;
  final String? sourceUrl;
  final String? licenceTh;
  final DateTime? retrievedAt;

  /// The next draw. [nextDrawEstimated] is true when this is the 1st/16th
  /// convention rather than a date we actually hold — GLO moves draws often
  /// enough that presenting the estimate as fact would be wrong twice a year.
  final DateTime? nextDrawDate;
  final bool nextDrawEstimated;
  final String? pdfUrl;

  /// The only condition under which the app may tell someone they lost.
  bool get verdictAvailable =>
      status == DrawStatus.announced && complete && !hasUnreadableTier;

  PrizeTierResult? tier(String code) {
    for (final p in prizes) {
      if (p.code == code) return p;
    }
    return null;
  }

  factory DrawResult.fromJson(Map<String, dynamic> json) {
    final prizes = [
      for (final p in (json['prizes'] as List<dynamic>? ?? const []))
        PrizeTierResult.fromJson(p as Map<String, dynamic>),
    ]..sort((a, b) => a.sort.compareTo(b.sort));

    return DrawResult(
      drawDate: DateTime.parse(json['drawDate'] as String),
      periodLabelTh: json['periodLabelTh'] as String? ?? '',
      status: DrawStatus.fromCode(json['status'] as String?),
      resultRevision: (json['resultRevision'] as num?)?.toInt() ?? 0,
      complete: json['complete'] as bool? ?? false,
      // A tier whose rule we cannot read poisons the whole draw, not just that
      // tier: we can no longer prove a ticket did not win.
      hasUnreadableTier: prizes.any((p) => p.matchKind == null),
      dutyRate: (json['dutyRate'] as num?)?.toDouble() ?? 0.005,
      prizes: prizes,
      sourceCustodianTh:
          (json['source'] as Map<String, dynamic>?)?['custodianTh'] as String? ??
              'สำนักงานสลากกินแบ่งรัฐบาล',
      sourceUrl: (json['source'] as Map<String, dynamic>?)?['url'] as String?,
      licenceTh:
          (json['source'] as Map<String, dynamic>?)?['licenceTh'] as String?,
      retrievedAt: _parseDate(
          (json['source'] as Map<String, dynamic>?)?['retrievedAt']),
      nextDrawDate: _parseDate(json['nextDrawDate']),
      nextDrawEstimated: json['nextDrawEstimated'] as bool? ?? true,
      pdfUrl: json['pdfUrl'] as String?,
    );
  }
}

DateTime? _parseDate(Object? v) {
  if (v is! String || v.isEmpty) return null;
  return DateTime.tryParse(v);
}

/// Upcoming/latest draw info shown on the ตรวจหวย banner.
///
/// Kept separate from [DrawResult] because the banner must render before any
/// result exists — that is precisely the state it is most needed in.
class DrawInfo {
  const DrawInfo({
    required this.drawDate,
    required this.statusTh,
    this.status = DrawStatus.scheduled,
    this.estimated = true,
  });

  final DateTime drawDate;
  final String statusTh;
  final DrawStatus status;

  /// True when [drawDate] came from the 1st/16th convention rather than data.
  final bool estimated;

  bool get isAnnounced => status == DrawStatus.announced;
}

/// A user-saved ticket number.
///
/// [quantity] supports ซื้อเป็นชุด — several physical tickets bearing the same
/// six digits, which is how a large part of the audience buys.
///
/// RULE FOR EVERY FUTURE FIELD ON THIS CLASS: read it as nullable-with-default
/// in [fromJson]. This is not defensive style, it is data integrity.
/// `_decodeListOrEmpty` SKIPS entries whose parse throws, and
/// `LocalSavedTicketsRepository.save()` rewrites the whole list from `all()`.
/// So a `json['quantity'] as int` against a payload written by an older build
/// would drop every existing ticket from the list and then persist that loss
/// on the next save — the user's numbers gone, silently and permanently.
class SavedTicket {
  const SavedTicket({
    required this.number,
    required this.savedAt,
    this.quantity = 1,
  });

  final String number;
  final DateTime savedAt;
  final int quantity;

  SavedTicket copyWith({int? quantity}) => SavedTicket(
        number: number,
        savedAt: savedAt,
        quantity: quantity ?? this.quantity,
      );

  Map<String, dynamic> toJson() => {
        'number': number,
        'savedAt': savedAt.toIso8601String(),
        'quantity': quantity,
      };

  factory SavedTicket.fromJson(Map<String, dynamic> json) => SavedTicket(
        number: json['number'] as String,
        savedAt: DateTime.parse(json['savedAt'] as String),
        quantity: _readQuantity(json['quantity']),
      );
}

/// `num` rather than `int` because a value round-tripped through some web JSON
/// paths surfaces as `2.0`, and `as int` throws on a double. Clamped to >= 1 so
/// a corrupted 0 cannot silently zero out a real win.
int _readQuantity(Object? v) {
  final n = (v as num?)?.toInt() ?? 1;
  return n < 1 ? 1 : n;
}

/// Responsible-use entertainment budget (งบความบันเทิง), in THB.
class BudgetState {
  const BudgetState({required this.spent, required this.limit});

  final int spent;
  final int limit;

  double get ratio => limit <= 0 ? 0 : (spent / limit).clamp(0.0, 1.0);

  BudgetState copyWith({int? spent, int? limit}) =>
      BudgetState(spent: spent ?? this.spent, limit: limit ?? this.limit);

  Map<String, dynamic> toJson() => {'spent': spent, 'limit': limit};

  factory BudgetState.fromJson(Map<String, dynamic> json) => BudgetState(
        spent: (json['spent'] as num).toInt(),
        limit: (json['limit'] as num).toInt(),
      );
}

/// One bucket of the เลขท้าย 2 ตัว frequency table.
class Last2Bucket {
  const Last2Bucket({required this.number, required this.count, this.lastSeen});

  final String number;
  final int count;
  final DateTime? lastSeen;

  factory Last2Bucket.fromJson(Map<String, dynamic> json) => Last2Bucket(
        number: json['n'] as String? ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
        lastSeen: _parseDate(json['lastSeenDate']),
      );
}

/// Digit frequency over a window of past draws.
///
/// [noteTh] is served by the database rather than written here on purpose: the
/// caveat that past draws do not predict future ones arrives in the same object
/// as the numbers, so the UI cannot render one without the other.
class DigitStats {
  const DigitStats({
    required this.windowDraws,
    required this.last2,
    required this.positionDigits,
    required this.neverSeenLast2,
    required this.noteTh,
    this.fromDate,
    this.toDate,
    this.sourceTh,
  });

  final int windowDraws;
  final List<Last2Bucket> last2;

  /// Six positions of รางวัลที่ 1, each with counts for digits 0-9.
  final List<List<int>> positionDigits;
  final int neverSeenLast2;
  final String noteTh;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? sourceTh;

  factory DigitStats.fromJson(Map<String, dynamic> json) {
    final positions = <List<int>>[];
    for (final p in (json['positionDigits'] as List<dynamic>? ?? const [])) {
      final digits = (p as Map<String, dynamic>)['digits'] as List<dynamic>? ??
          const [];
      positions.add([
        for (final d in digits)
          ((d as Map<String, dynamic>)['count'] as num?)?.toInt() ?? 0,
      ]);
    }
    return DigitStats(
      windowDraws: (json['windowDraws'] as num?)?.toInt() ?? 0,
      last2: [
        for (final b in (json['last2'] as List<dynamic>? ?? const []))
          Last2Bucket.fromJson(b as Map<String, dynamic>),
      ],
      positionDigits: positions,
      neverSeenLast2: (json['neverSeenLast2'] as num?)?.toInt() ?? 0,
      noteTh: json['noteTh'] as String? ?? '',
      fromDate: _parseDate(json['fromDate']),
      toDate: _parseDate(json['toDate']),
      sourceTh: json['sourceTh'] as String?,
    );
  }
}
