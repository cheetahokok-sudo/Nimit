import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/nimit_theme.dart';
import '../../core/widgets/section.dart';
import '../../data/models/lottery.dart';
import '../../data/providers.dart';
import 'lottery_sub_screen.dart';

/// สถิติเลขย้อนหลัง — what has actually come out.
///
/// The honest framing is the product position here. Every หวย site in Thailand
/// shows frequency tables, and this audience expects them; refusing would just
/// send them elsewhere. What Nimit can do differently is show the same real
/// numbers WITHOUT dressing them as a prediction — no "เลขน่าออก", no
/// highlighted picks, and the randomness caveat carried in the same payload as
/// the counts so it cannot be dropped from the layout.
class LotteryStatsScreen extends ConsumerWidget {
  const LotteryStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(digitStatsProvider);
    final textTheme = Theme.of(context).textTheme;

    return LotterySubScreen(
      titleTh: 'สถิติเลขย้อนหลัง',
      child: stats.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => const SectionCard(
          child: DisclaimerText('ยังโหลดสถิติไม่ได้ ลองใหม่อีกครั้ง'),
        ),
        data: (s) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionCard(
              color: NimitColors.pastelBlue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('นับจาก ${s.windowDraws} งวดที่ผ่านมา',
                      style: textTheme.titleSmall!
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  // Served by the database alongside the counts, so the
                  // statistics cannot be rendered without it.
                  Text(s.noteTh,
                      style: textTheme.bodySmall!
                          .copyWith(color: NimitColors.ink, height: 1.45)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SectionHeader('เลขท้าย 2 ตัว',
                caption: 'จำนวนครั้งที่ออกในช่วงที่นับ'),
            const SizedBox(height: 10),
            _Last2Grid(buckets: s.last2),
            const SizedBox(height: 20),
            const SectionHeader('ตัวเลขแต่ละหลักของรางวัลที่ 1',
                caption: 'นับแยกตามตำแหน่ง'),
            const SizedBox(height: 10),
            _PositionTable(positions: s.positionDigits),
            const SizedBox(height: 18),
            if (s.sourceTh != null) DisclaimerText(s.sourceTh!),
            const SizedBox(height: 6),
            const DisclaimerText(
              'สถิติที่แสดงเป็นข้อเท็จจริงของงวดที่ผ่านมาเท่านั้น '
              'ไม่ได้บอกว่าเลขใดจะออกงวดหน้า และไม่ได้เพิ่มโอกาสถูกรางวัล',
            ),
          ],
        ),
      ),
    );
  }
}

/// 100 buckets, five columns.
///
/// Ten columns would give ~31px cells on a 375px screen — below the minimum
/// tap target and unreadable in sunlight. Five columns yields ~62px.
class _Last2Grid extends StatelessWidget {
  const _Last2Grid({required this.buckets});

  final List<Last2Bucket> buckets;

  @override
  Widget build(BuildContext context) {
    final maxCount =
        buckets.fold<int>(0, (m, b) => b.count > m ? b.count : m);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: buckets.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, i) {
        final b = buckets[i];
        // Weight by frequency so the eye can find the busier numbers, but
        // never label any of them "hot" or single one out as a pick.
        final t = maxCount == 0 ? 0.0 : b.count / maxCount;
        final bg = Color.lerp(NimitColors.surface, NimitColors.gold, t * 0.85)!;
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: NimitColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(b.number,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: NimitColors.ink,
                    fontFeatures: [FontFeature.tabularFigures()],
                  )),
              Text('${b.count} ครั้ง',
                  style: const TextStyle(
                      fontSize: 11, color: NimitColors.inkSoft)),
            ],
          ),
        );
      },
    );
  }
}

class _PositionTable extends StatelessWidget {
  const _PositionTable({required this.positions});

  final List<List<int>> positions;

  @override
  Widget build(BuildContext context) {
    if (positions.isEmpty) {
      return const SectionCard(
        child: DisclaimerText('ยังไม่มีข้อมูลมากพอสำหรับสถิตินี้'),
      );
    }
    return SectionCard(
      child: SingleChildScrollView(
        // Wide content scrolls inside its own box; the page never scrolls
        // sideways.
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 18,
          headingRowHeight: 34,
          dataRowMinHeight: 34,
          dataRowMaxHeight: 40,
          columns: [
            const DataColumn(label: Text('หลัก')),
            for (var d = 0; d < 10; d++) DataColumn(label: Text('$d')),
          ],
          rows: [
            for (var p = 0; p < positions.length; p++)
              DataRow(cells: [
                DataCell(Text('ที่ ${p + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w700))),
                for (var d = 0; d < 10; d++)
                  DataCell(Text(
                    d < positions[p].length ? '${positions[p][d]}' : '0',
                    style: const TextStyle(
                        fontFeatures: [FontFeature.tabularFigures()]),
                  )),
              ]),
          ],
        ),
      ),
    );
  }
}
