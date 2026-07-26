import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/nimit_theme.dart';
import '../../core/widgets/section.dart';
import '../../data/models/lottery.dart';
import '../../data/providers.dart';
import 'lottery_sub_screen.dart';
import 'lottery_widgets.dart';

/// ผลย้อนหลัง — roughly two years of draws.
///
/// The list itself is deliberately light (date, รางวัลที่ 1, เลขท้าย 2 ตัว);
/// all 173 numbers for a งวด are fetched only when that row is expanded. Two
/// years the heavy way would be ~208 KB, which is not a reasonable thing to
/// send to a phone on mobile data so that most of it can go unread.
///
/// Rows are grouped under a Buddhist-era year heading. Without one, the two
/// draws every month (1st and 16th) read as duplicated rows — reported by a
/// user looking at exactly this screen.
class LotteryHistoryScreen extends ConsumerWidget {
  const LotteryHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(lotteryHistoryProvider);

    return LotterySubScreen(
      titleTh: 'ผลย้อนหลัง',
      child: history.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => const SectionCard(
          child: DisclaimerText('ยังโหลดผลย้อนหลังไม่ได้ ลองใหม่อีกครั้ง'),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const SectionCard(
              child: DisclaimerText('ยังไม่มีผลย้อนหลังในแอป'),
            );
          }

          final children = <Widget>[];
          int? currentYear;
          for (final d in list) {
            if (d.yearBe != currentYear) {
              currentYear = d.yearBe;
              children.add(Padding(
                padding: EdgeInsets.only(
                    top: children.isEmpty ? 0 : 18, bottom: 10),
                child: _YearHeading(yearBe: d.yearBe),
              ));
            }
            children.add(_DrawTile(summary: d));
            children.add(const SizedBox(height: 10));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${list.length} งวด · แตะเพื่อดูรางวัลทั้งหมด',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(color: NimitColors.inkSoft)),
              const SizedBox(height: 14),
              ...children,
              const SizedBox(height: 8),
              const DisclaimerText('ที่มา: สำนักงานสลากกินแบ่งรัฐบาล'),
            ],
          );
        },
      ),
    );
  }
}

class _YearHeading extends StatelessWidget {
  const _YearHeading({required this.yearBe});

  final int yearBe;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: NimitColors.aubergine,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text('พ.ศ. $yearBe',
              style: const TextStyle(
                color: NimitColors.onDark,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
              )),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider(color: NimitColors.border, height: 1)),
      ],
    );
  }
}

class _DrawTile extends ConsumerWidget {
  const _DrawTile({required this.summary});

  final DrawSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return SectionCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          title: Text(summary.labelTh,
              style:
                  textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w700)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                _MiniPrize(
                    labelTh: 'รางวัลที่ 1', value: summary.firstPrize ?? '—'),
                const SizedBox(width: 20),
                _MiniPrize(
                    labelTh: 'ท้าย 2 ตัว', value: summary.last2 ?? '—'),
              ],
            ),
          ),
          // The 173 numbers load only when the user asks for them.
          onExpansionChanged: (open) {
            if (open) ref.read(drawByDateProvider(summary.drawDate));
          },
          children: [
            Consumer(builder: (context, ref, _) {
              final full = ref.watch(drawByDateProvider(summary.drawDate));
              return full.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                      child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2))),
                ),
                error: (e, _) =>
                    const DisclaimerText('โหลดรายละเอียดงวดนี้ไม่สำเร็จ'),
                data: (draw) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                              tier.numbers.isEmpty
                                  ? '—'
                                  : tier.numbers.join('   '),
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
                      const DisclaimerText(
                          'งวดนี้ข้อมูลในแอปยังไม่ครบทุกรางวัล'),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _MiniPrize extends StatelessWidget {
  const _MiniPrize({required this.labelTh, required this.value});

  final String labelTh;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$labelTh ',
            style: const TextStyle(fontSize: 12, color: NimitColors.inkSoft)),
        Text(value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: NimitColors.aubergine,
              fontFeatures: [FontFeature.tabularFigures()],
            )),
      ],
    );
  }
}
