/// Trust tiers for interpretation sources — the labeling system from the
/// research proposal (fact / belief / opinion must be visibly separated).
enum SourceTier {
  a1('A1', 'ต้นฉบับทางประวัติศาสตร์', 'หอสมุดแห่งชาติ • กรมศิลปากร'),
  a2('A2', 'ฉบับตรวจชำระ', 'ฉบับพิมพ์โดยสถาบันที่ตรวจสอบได้'),
  b1('B1', 'งานวิชาการ', 'วิทยานิพนธ์และบทความวิจัย'),
  b2('B2', 'ตำราสมัยใหม่', 'ผู้เขียนและฉบับระบุชัดเจน'),
  c('C', 'ความเชื่อร่วมสมัย', 'สื่อและนักพยากรณ์ที่ยืนยันตัวตน'),
  d('D', 'ยังไม่ยืนยัน', 'โพสต์ไวรัลหรือคำกล่าวที่ไม่มีต้นทาง');

  const SourceTier(this.code, this.titleTh, this.descriptionTh);

  final String code;
  final String titleTh;
  final String descriptionTh;

  /// Resolves a tier code arriving from the backend or from stored JSON.
  ///
  /// Fails closed to [d] ("ยังไม่ยืนยัน"). An unrecognised or corrupt code must
  /// never be rendered with a higher-trust badge than the content has earned —
  /// labelling unverified material as a historical original is the exact trust
  /// failure the tier system exists to prevent.
  static SourceTier fromCode(String? code) {
    final normalized = code?.trim().toUpperCase();
    return values.firstWhere(
      (tier) => tier.code == normalized,
      orElse: () => SourceTier.d,
    );
  }
}
