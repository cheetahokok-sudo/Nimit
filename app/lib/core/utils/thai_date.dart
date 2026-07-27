/// Thai (Buddhist-era) date formatting, e.g. "1 สิงหาคม 2569".
const List<String> thaiMonths = [
  'มกราคม',
  'กุมภาพันธ์',
  'มีนาคม',
  'เมษายน',
  'พฤษภาคม',
  'มิถุนายน',
  'กรกฎาคม',
  'สิงหาคม',
  'กันยายน',
  'ตุลาคม',
  'พฤศจิกายน',
  'ธันวาคม',
];

String formatThaiDate(DateTime date) {
  final month = thaiMonths[date.month - 1];
  final beYear = date.year + 543;
  return '${date.day} $month $beYear';
}

/// The current moment in Thailand.
///
/// Thailand has observed UTC+7 with no daylight saving since 1976 and none is
/// planned, so the fixed offset is exact — one of the few cases where
/// hardcoding an offset is correct rather than lazy.
///
/// Every "which งวด is current" decision must route through this. Without it a
/// user in London at 20:00 on 31 July is shown the wrong งวด, because it is
/// already 1 August in Bangkok.
DateTime nowInBangkok() => DateTime.now().toUtc().add(const Duration(hours: 7));

/// ESTIMATED next draw date, from the 1st/16th convention.
///
/// PREFER `DrawResult.nextDrawDate` FROM THE SERVER. This function is a
/// fallback for when no draw data is available at all, and its premise is not
/// reliable: GLO moves draws, and often. Verified against the live GLO API —
/// 1 มกราคม 2568 had no draw (it was held 2 มกราคม), and 16 มกราคม 2568 was
/// drawn on the 17th. Two of the four draws in that six-week window were moved.
///
/// When a computed date is wrong it is wrong in the dangerous direction: it
/// reports a completed draw as still pending, so a user who has won is told to
/// keep waiting. Anything built on this must present the result as an estimate
/// — see `DrawInfo.estimated`, which the banner renders as "(โดยประมาณ)".
///
/// Note also that on the 1st and the 16th this returns TODAY, not a future
/// date, which is intentional for "the งวด currently in play" but wrong if a
/// caller wants "the next one after this".
DateTime nextDrawDate(DateTime from) {
  final day = from.day;
  if (day <= 1) return DateTime(from.year, from.month, 1);
  if (day <= 16) return DateTime(from.year, from.month, 16);
  return DateTime(from.year, from.month + 1, 1);
}

/// Arabic digits to Thai numerals: 12 → ๑๒.
///
/// Used where the app speaks in the register of a ตำรา rather than a form.
/// A lunar date written "ขึ้น ๑๒ ค่ำ เดือนห้า" carries the weight the tradition
/// gives it; the same line in Arabic digits reads like a receipt. Deliberately
/// NOT used for anything the reader must treat as a quantity — money, ticket
/// numbers, ages — where familiarity beats atmosphere.
String thaiDigits(Object value) {
  const th = ['๐', '๑', '๒', '๓', '๔', '๕', '๖', '๗', '๘', '๙'];
  return value
      .toString()
      .replaceAllMapped(RegExp(r'[0-9]'), (m) => th[int.parse(m[0]!)]);
}
