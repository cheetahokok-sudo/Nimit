import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/nimit_theme.dart';
import '../../core/widgets/number_pill.dart';
import '../../core/widgets/section.dart';
import '../../core/widgets/source_badge.dart';
import '../../data/providers.dart';

class FortuneScreen extends ConsumerWidget {
  const FortuneScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final fortune = ref.watch(fortuneProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text('ดวงของฉัน',
            style: textTheme.headlineSmall!
                .copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        fortune.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => const DisclaimerText('โหลดข้อมูลไม่สำเร็จ'),
          data: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DarkCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data.lagnaTh,
                              style: textTheme.titleLarge!.copyWith(
                                  color: NimitColors.onDark,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(data.monthThemeTh,
                              style: textTheme.bodySmall!
                                  .copyWith(color: NimitColors.onDarkSoft)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: NimitColors.gold,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(data.profileCompleteTh,
                                style: textTheme.labelSmall!.copyWith(
                                    color: NimitColors.aubergineDeep,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                    const _OrbitMark(),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const SectionHeader('เลขประจำดวงเดือนนี้',
                  caption: 'เลขที่สอดคล้องกับดวง ไม่ใช่เลขที่จะออก'),
              const SizedBox(height: 10),
              NumberPillRow(data.monthlyNumbers),
              const SizedBox(height: 20),
              const SectionHeader('ที่มาของคำแปล'),
              const SizedBox(height: 10),
              for (final card in data.sourceCards) ...[
                SectionCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SourceBadge(card.tier, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(card.titleTh,
                                style: textTheme.titleSmall!
                                    .copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(card.bodyTh,
                                style: textTheme.bodySmall!
                                    .copyWith(color: NimitColors.inkSoft)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SectionCard(
                color: NimitColors.successBg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('คำแนะนำวันนี้',
                        style: textTheme.titleSmall!.copyWith(
                            color: NimitColors.successInk,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(data.dailyAdviceTh,
                        style: textTheme.bodyMedium!
                            .copyWith(color: NimitColors.successInk)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Simple orbit decoration echoing the birth-chart mark on the UI board.
class _OrbitMark extends StatelessWidget {
  const _OrbitMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: NimitColors.onDarkSoft, width: 1),
            ),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: NimitColors.gold,
              shape: BoxShape.circle,
            ),
          ),
          const Align(
            alignment: Alignment.topCenter,
            child: _OrbitDot(),
          ),
          const Align(
            alignment: Alignment.centerRight,
            child: _OrbitDot(),
          ),
          const Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 8, bottom: 8),
              child: _OrbitDot(),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitDot extends StatelessWidget {
  const _OrbitDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: NimitColors.onDark,
        shape: BoxShape.circle,
      ),
    );
  }
}
