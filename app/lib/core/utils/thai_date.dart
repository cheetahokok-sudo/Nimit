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

/// Next government-lottery draw date (1st or 16th) on or after [from].
DateTime nextDrawDate(DateTime from) {
  final day = from.day;
  if (day <= 1) return DateTime(from.year, from.month, 1);
  if (day <= 16) return DateTime(from.year, from.month, 16);
  return DateTime(from.year, from.month + 1, 1);
}
