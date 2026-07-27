/// The birth information this app holds: a date, on the device only.
///
/// WHY IT GREW FROM A MONTH TO A DATE.
///
/// The first version stored a Gregorian month, on the reasoning that a month is
/// one of twelve buckets and therefore barely identifying. Right instinct,
/// wrong field: every ตำรา that reads by เดือนเกิด means เดือนอ้าย / ยี่ / สาม —
/// the Thai LUNAR month. เดือนอ้าย falls around November–December, so "month 1"
/// is not January, and no function maps one to the other. The lunar year is
/// 354, 355 or 384 days depending on whether month 7 gains a day or month 8
/// repeats, and which of those happens depends on the year. Converting needs
/// day, month and year together.
///
/// So a month-only profile could never produce a reading at all. A date can.
///
/// WHAT THIS COSTS, STATED PLAINLY. A full date of birth is meaningfully more
/// identifying than a month — it is a routine component of identity checks.
/// What keeps the posture intact is that it is never transmitted: no network
/// call on the ดวง screen, no account, and no remote implementation of its
/// repository. Apple's "Data Not Collected" and PDPA both turn on collection
/// and transmission, not on local storage. The privacy card on the screen names
/// the field, so the promise matches the payload.
///
/// Time of day is deliberately NOT stored. It is needed only for the dawn
/// boundary rule, which is opt-in and not surfaced yet, and collecting a field
/// nothing reads is the opposite of data minimisation.
class BirthProfile {
  const BirthProfile({this.date, this.legacyMonth});

  /// Date of birth, local, no time component. Null until the user says.
  final DateTime? date;

  /// A Gregorian month carried over from the month-only version of this app.
  ///
  /// Only ever set when [date] is null. It is not enough to compute a lunar
  /// month, so it cannot produce a reading — but discarding it would silently
  /// throw away something the user typed. Kept so the screen can say "you told
  /// us the month, add the day and year" instead of appearing to have
  /// forgotten.
  final int? legacyMonth;

  bool get isComplete => date != null;

  /// The old month survived but the full date has not been supplied.
  bool get needsUpgrade => date == null && legacyMonth != null;

  bool get isEmpty => date == null && legacyMonth == null;

  Map<String, dynamic> toJson() => {
        if (date != null) 'date': _iso(date!),
        if (date == null && legacyMonth != null) 'month': legacyMonth,
      };

  /// Reads BOTH shapes: current `{date: "YYYY-MM-DD"}` and legacy `{month: N}`.
  ///
  /// A throwing fromJson would not merely fail to read — the repository
  /// rewrites storage from what it loads, so a throw becomes deletion on the
  /// next save. Every branch here returns a profile rather than raising.
  factory BirthProfile.fromJson(Map<String, dynamic> json) {
    final date = _readDate(json['date']);
    if (date != null) return BirthProfile(date: date);
    return BirthProfile(legacyMonth: _readMonth(json['month']));
  }
}

String _iso(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Anything unparseable reads as null rather than throwing or being coerced.
/// A half-understood date is worse than an absent one: it would quietly hand
/// somebody a stranger's lunar month.
///
/// `DateTime.tryParse` ALONE IS NOT ENOUGH, and this is the trap. It does not
/// reject impossible components, it rolls them over: `tryParse('1993-13-45')`
/// returns 1994-02-14. A corrupt stored value would therefore become a
/// perfectly plausible wrong birthday, and the screen would render a confident
/// lunar month for a day the user never lived. So the parsed value is checked
/// back against the digits it came from, which also catches 31 February
/// rolling into March.
final _isoDate = RegExp(r'^(\d{4})-(\d{2})-(\d{2})(?:[T ].*)?$');

DateTime? _readDate(Object? v) {
  if (v is! String) return null;
  final m = _isoDate.firstMatch(v);
  if (m == null) return null;

  final year = int.parse(m.group(1)!);
  final month = int.parse(m.group(2)!);
  final day = int.parse(m.group(3)!);

  // Drop any time component a future writer might include, so equality and the
  // lunar conversion both behave predictably.
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) return null;
  return date;
}

/// Outside 1–12 becomes null rather than clamping. A clamped 0 would become
/// January and show someone a month they were not born in.
int? _readMonth(Object? v) {
  final n = (v as num?)?.toInt();
  if (n == null || n < 1 || n > 12) return null;
  return n;
}
