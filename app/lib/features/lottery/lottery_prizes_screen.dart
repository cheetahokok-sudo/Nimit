import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/nimit_theme.dart';
import '../../core/widgets/section.dart';
import '../../data/models/lottery.dart';
import '../../data/providers.dart';
import 'lottery_sub_screen.dart';
import 'lottery_widgets.dart';

/// เงินรางวัลแต่ละรางวัล.
///
/// Every figure here comes from the draw payload, which carries the prize
/// structure alongside the numbers it prices. Nothing on this screen is a
/// constant in the app: if GLO restructures the prizes, this screen changes
/// when the data does, and cannot disagree with what the checker paid out.
class LotteryPrizesScreen extends ConsumerWidget {
  const LotteryPrizesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(latestDrawProvider);
    final textTheme = Theme.of(context).textTheme;

    return LotterySubScreen(
      titleTh: 'เงินรางวัลแต่ละรางวัล',
      child: latest.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => const SectionCard(
          child: DisclaimerText('ยังโหลดข้อมูลรางวัลไม่ได้ ลองใหม่อีกครั้ง'),
        ),
        data: (draw) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final p in draw.prizes) ...[
              SectionCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.nameTh,
                              style: textTheme.titleSmall!
                                  .copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(
                            '${p.winnerCount} รางวัล · ${_matchDescription(p.matchKind)}',
                            style: textTheme.bodySmall!
                                .copyWith(color: NimitColors.inkSoft),
                          ),
                        ],
                      ),
                    ),
                    Text(formatBaht(p.amountThb),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: NimitColors.aubergine,
                          fontFeatures: [FontFeature.tabularFigures()],
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 8),
            SectionCard(
              color: NimitColors.pastelCream,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ตอนขึ้นเงินรางวัล',
                      style: textTheme.titleSmall!
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    'สลากกินแบ่งรัฐบาลหักอากรแสตมป์ '
                    '${(draw.dutyRate * 100).toStringAsFixed(1)}% ของเงินรางวัล '
                    '(สลากการกุศลหัก 1%) และได้รับยกเว้นภาษีเงินได้บุคคลธรรมดา '
                    'ยอดที่แอปแสดงทุกจุดเป็นยอดเต็มก่อนหัก',
                    style: textTheme.bodySmall!
                        .copyWith(color: NimitColors.ink, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            DisclaimerText('ที่มา: ${draw.sourceCustodianTh}'),
          ],
        ),
      ),
    );
  }
}

String _matchDescription(MatchKind? kind) => switch (kind) {
      MatchKind.exact6 => 'ตรงทั้ง 6 หลัก',
      MatchKind.prefix3 => 'ตรง 3 ตัวหน้า',
      MatchKind.suffix3 => 'ตรง 3 ตัวท้าย',
      MatchKind.suffix2 => 'ตรง 2 ตัวท้าย',
      // Named honestly rather than guessed: a rule this build cannot read is
      // also a rule it cannot pay out on.
      null => 'รูปแบบใหม่ (แอปรุ่นนี้ยังไม่รองรับ)',
    };
