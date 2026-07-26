import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/nimit_theme.dart';
import '../../core/utils/thai_date.dart';
import '../../core/widgets/section.dart';
import '../../data/lottery_checker.dart';
import '../../data/models/lottery.dart';
import '../../data/providers.dart';
import 'lottery_sub_screen.dart';
import 'lottery_widgets.dart';

/// สถิติของฉัน — the user's own history against past draws.
///
/// Computed entirely on-device by folding the saved numbers over the recent
/// draws already fetched. Nothing here is sent anywhere: the standing
/// constraint is that no request may ever carry a user's lottery number, and
/// this screen is the one most tempting to implement as a server query.
class LotteryMeScreen extends ConsumerWidget {
  const LotteryMeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(savedTicketsProvider);
    final draws = ref.watch(recentDrawsProvider);
    final budget = ref.watch(budgetProvider);

    return LotterySubScreen(
      titleTh: 'สถิติของฉัน',
      child: tickets.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => const SectionCard(
          child: DisclaimerText('ยังโหลดข้อมูลไม่ได้ ลองใหม่อีกครั้ง'),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const SectionCard(
              child: DisclaimerText(
                'ยังไม่ได้บันทึกเลขไว้ เมื่อบันทึกแล้วหน้านี้จะสรุปให้ว่า '
                'เลขของคุณเคยออกงวดไหนบ้าง',
              ),
            );
          }

          final held = list.fold<int>(0, (s, t) => s + t.quantity);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionCard(
                color: NimitColors.pastelLavender,
                child: Row(
                  children: [
                    Expanded(
                      child: _Stat(
                          labelTh: 'เลขที่บันทึก',
                          valueTh: '${list.length} เลข'),
                    ),
                    Expanded(
                      child:
                          _Stat(labelTh: 'รวมทั้งหมด', valueTh: '$held ใบ'),
                    ),
                    Expanded(
                      child: budget.maybeWhen(
                        data: (b) => _Stat(
                            labelTh: 'ใช้ไปเดือนนี้',
                            valueTh: formatBaht(b.spent)),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const SectionHeader('เลขของคุณกับงวดที่ผ่านมา'),
              const SizedBox(height: 10),
              draws.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => const SectionCard(
                  child: DisclaimerText('ยังโหลดผลย้อนหลังไม่ได้'),
                ),
                data: (history) => _History(tickets: list, draws: history),
              ),
              const SizedBox(height: 16),
              const DisclaimerText(
                'สรุปนี้คำนวณในเครื่องของคุณเอง เลขที่บันทึกไว้ไม่ถูกส่งออกไปที่ใด',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.labelTh, required this.valueTh});

  final String labelTh;
  final String valueTh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelTh,
            style: const TextStyle(fontSize: 12, color: NimitColors.inkSoft)),
        const SizedBox(height: 2),
        Text(valueTh,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: NimitColors.ink)),
      ],
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.tickets, required this.draws});

  final List<SavedTicket> tickets;
  final List<DrawResult> draws;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (draws.isEmpty) {
      return const SectionCard(
        child: DisclaimerText('ยังไม่มีผลย้อนหลังในแอป'),
      );
    }

    var totalWon = 0;
    final rows = <Widget>[];

    for (final draw in draws) {
      final outcome = checkAll(draw, tickets);
      if (!outcome.hasWin) continue;
      totalWon += outcome.totalThb;
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SectionCard(
          color: NimitColors.successBg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(formatThaiDate(draw.drawDate),
                  style: textTheme.bodySmall!
                      .copyWith(color: NimitColors.successInk)),
              const SizedBox(height: 4),
              for (final t in outcome.tickets.where((t) => t.isWin))
                Text(
                  '${t.number} · ${t.hits.map((h) => h.nameTh).join(", ")} · '
                  '${formatBaht(t.totalAmountThb)}',
                  style: textTheme.bodyMedium!.copyWith(
                      color: NimitColors.successInk,
                      fontWeight: FontWeight.w700),
                ),
            ],
          ),
        ),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          child: Row(
            children: [
              Expanded(
                child: _Stat(
                    labelTh: 'งวดที่ตรวจย้อนหลัง',
                    valueTh: '${draws.length} งวด'),
              ),
              Expanded(
                child: _Stat(
                    labelTh: 'รวมเงินรางวัลที่ถูก',
                    valueTh: formatBaht(totalWon)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (rows.isEmpty)
          const SectionCard(
            child: DisclaimerText(
              'เลขที่บันทึกไว้ยังไม่เคยตรงกับผลรางวัลในงวดที่แอปมีข้อมูล',
            ),
          )
        else
          ...rows,
      ],
    );
  }
}
