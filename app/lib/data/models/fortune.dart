import 'source.dart';

/// A "ที่มาของคำแปล" card on the fortune screen.
class FortuneSourceCard {
  const FortuneSourceCard({
    required this.tier,
    required this.titleTh,
    required this.bodyTh,
  });

  final SourceTier tier;
  final String titleTh;
  final String bodyTh;
}

class FortuneData {
  const FortuneData({
    required this.lagnaTh,
    required this.monthThemeTh,
    required this.profileCompleteTh,
    required this.monthlyNumbers,
    required this.sourceCards,
    required this.dailyAdviceTh,
  });

  final String lagnaTh; // e.g. "ลัคนาเมษ"
  final String monthThemeTh; // e.g. "เดือนนี้: เริ่มสิ่งใหม่อย่างมีแผน"
  final String profileCompleteTh; // e.g. "ข้อมูลเกิดครบแล้ว"
  final List<String> monthlyNumbers;
  final List<FortuneSourceCard> sourceCards;
  final String dailyAdviceTh;
}
