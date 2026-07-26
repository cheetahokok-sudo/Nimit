import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/nimit_theme.dart';
import '../../core/utils/thai_date.dart';
import '../../core/widgets/section.dart';
import '../../data/models/lottery.dart';
import '../../data/providers.dart';
import 'lottery_sub_screen.dart';
import 'lottery_widgets.dart';

/// ผลย้อนหลัง — past draws, expandable to all 173 numbers.
///
/// The full tier lists live here rather than on the main screen because 173
/// numbers would bury the one thing a user opens the app for on draw day.
class LotteryHistoryScreen extends ConsumerWidget {
  const LotteryHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draws = ref.watch(recentDrawsProvider);

    return LotterySubScreen(
      titleTh: 'ผลย้อนหลัง',
      child: draws.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => const SectionCard(
          child: DisclaimerText('ยังโหลดผลย้อนหลังไม่ได้ ลองใหม่อีกครั้ง'),
        ),
        data: (list) => list.isEmpty
            ? const SectionCard(
                child: DisclaimerText('ยังไม่มีผลย้อนหลังในแอป'),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final draw in list) ...[
                    _DrawTile(draw: draw),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 8),
                  DisclaimerText('ที่มา: ${list.first.sourceCustodianTh}'),
                ],
              ),
      ),
    );
  }
}

class _DrawTile extends StatelessWidget {
  const _DrawTile({required this.draw});

  final DrawResult draw;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final first = draw.tier('first')?.numbers.firstOrNull ?? '—';
    final last2 = draw.tier('last2')?.numbers.firstOrNull ?? '—';

    return SectionCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          title: Text(formatThaiDate(draw.drawDate),
              style: textTheme.titleSmall!
                  .copyWith(fontWeight: FontWeight.w700)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'รางวัลที่ 1 · $first     ท้าย 2 ตัว · $last2',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: NimitColors.aubergine,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          children: [
            for (final tier in draw.prizes)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(tier.nameTh,
                              style: textTheme.bodySmall!.copyWith(
                                  color: NimitColors.inkSoft,
                                  fontWeight: FontWeight.w600)),
                        ),
                        Text(formatBaht(tier.amountThb),
                            style: textTheme.bodySmall!
                                .copyWith(color: NimitColors.inkSoft)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tier.numbers.isEmpty ? '—' : tier.numbers.join('   '),
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: NimitColors.ink,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            if (!draw.complete)
              const DisclaimerText('งวดนี้ข้อมูลในแอปยังไม่ครบทุกรางวัล'),
          ],
        ),
      ),
    );
  }
}
