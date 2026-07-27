/// The only birth information this app holds: a month.
///
/// WHY A MONTH AND NOTHING ELSE.
///
/// The screen this replaces displayed "ลัคนาเมษ" and a gold badge reading
/// "ข้อมูลเกิดครบแล้ว". A ลัคนา (ascendant) requires birth date, TIME and
/// PLACE — the app had never asked for any of it, so the chart was asserted
/// rather than computed, and the badge told users their birth data was on file
/// when no such data existed.
///
/// Scoping to a month is a deliberate product decision, and it buys three
/// things at once:
///
///   * PDPA — a birth month is not identifying. Date plus time plus place is
///     close to a unique key for a person; a month is one of twelve buckets.
///   * App Store — nothing leaves the device, so the privacy label stays at
///     "Data Not Collected" and review has nothing to verify.
///   * Citation — a month-based reading can cite one ตำรา passage. A natal
///     chart needs a computation whose method must itself be sourced, and
///     every school computes it differently.
///
/// Stored in shared_preferences and never transmitted. There is deliberately
/// no remote implementation of its repository: making this swappable would
/// invite a future version to send it somewhere.
class BirthProfile {
  const BirthProfile({this.month});

  /// 1–12, or null when the user has not said. Null is the normal state and
  /// the screen works fully without it.
  final int? month;

  bool get isSet => month != null && month! >= 1 && month! <= 12;

  Map<String, dynamic> toJson() => {'month': month};

  factory BirthProfile.fromJson(Map<String, dynamic> json) =>
      BirthProfile(month: _readMonth(json['month']));
}

/// Anything outside 1–12 becomes null rather than throwing or clamping. A
/// clamped 0 would silently become January and show someone a reading for the
/// wrong month.
int? _readMonth(Object? v) {
  final n = (v as num?)?.toInt();
  if (n == null || n < 1 || n > 12) return null;
  return n;
}
