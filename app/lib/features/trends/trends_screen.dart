import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nimit_theme.dart';
import '../../core/utils/thai_date.dart';
import '../../core/widgets/section.dart';
import '../../data/models/lottery.dart';
import '../../data/providers.dart';

/// กระแสปีนี้ — what actually came out over the past year, and what ตำรา say
/// each number means.
///
/// WHAT THIS REPLACED, AND WHY. The old กระแสวันนี้ shipped mock data to
/// production: a symbol trending "+38%", four numbers with mention counts, and
/// a caption stating the figures came from public posts and in-app searches.
/// None of it was measured. For a lottery audience, numbers shown with counts
/// read as consensus and get bought.
///
/// Real community trends need user data the app deliberately does not collect —
/// the journal is local and there is no auth — so they cannot exist before the
/// consent work. What DOES exist is a year of official GLO draws and a library
/// of sourced readings, and joining them is a better screen than the fiction
/// was: every row is a number that really came out, beside what ตำรา say about
/// it. Nothing here is estimated, weighted or invented.
///
/// The randomness caveat arrives inside the payload rather than being written
/// here, so the screen cannot render frequencies without it.
class TrendsScreen extends ConsumerWidget {
  const TrendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final trends = ref.watch(yearTrendsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text('กระแสปีนี้',
            style:
                textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('เลขท้าย 2 ตัว ที่ออกจริงในรอบปี พร้อมความหมายตามตำรา',
            style: textTheme.bodySmall!.copyWith(color: NimitColors.inkSoft)),
        const SizedBox(height: 16),
        trends.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => const SectionCard(
            child: DisclaimerText('ยังโหลดสถิติไม่ได้ ลองใหม่อีกครั้ง'),
          ),
          data: (t) => _Trends(trends: t),
        ),
      ],
    );
  }
}

class _Trends extends StatelessWidget {
  const _Trends({required this.trends});

  final YearTrends trends;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (trends.drawn.isEmpty) {
      return const SectionCard(
        child: DisclaimerText(
            'ยังไม่มีผลรางวัลย้อนหลังในแอป เมื่อระบบดึงผลจากสำนักงานสลากฯ แล้ว '
            'หน้านี้จะแสดงเลขที่ออกจริงพร้อมความหมายตามตำรา'),
      );
    }

    final maxTimes =
        trends.drawn.fold<int>(1, (m, d) => d.times > m ? d.times : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('นับจาก ${trends.windowDraws} งวดที่ผ่านมา',
                  style:
                      textTheme.labelMedium!.copyWith(color: NimitColors.gold)),
              if (trends.fromDate != null && trends.toDate != null) ...[
                const SizedBox(height: 4),
                Text(
                    '${formatThaiDate(trends.fromDate!)} – ${formatThaiDate(trends.toDate!)}',
                    style: textTheme.bodySmall!
                        .copyWith(color: NimitColors.onDarkSoft)),
              ],
              const SizedBox(height: 10),
              Text(
                  '${trends.drawn.length} เลขที่ออก · '
                  '${trends.coveredByLibrary} เลขมีความหมายในคลังตำรา',
                  style: textTheme.bodyMedium!
                      .copyWith(color: NimitColors.onDark)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const SectionHeader('เลขที่ออกจริง',
            caption: 'เรียงตามจำนวนครั้งที่ออกในช่วงที่นับ'),
        const SizedBox(height: 10),
        for (final d in trends.drawn) ...[
          _DrawnRow(drawn: d, maxTimes: maxTimes),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 6),
        // Served by the database alongside the counts, so a layout change can
        // never separate the caveat from the frequencies.
        SectionCard(
          color: NimitColors.pastelBlue,
          child: Text(trends.noteTh,
              style: textTheme.bodySmall!
                  .copyWith(color: NimitColors.ink, height: 1.5)),
        ),
        const SizedBox(height: 12),
        const DisclaimerText(
            'ที่มาของผลรางวัล: สำนักงานสลากกินแบ่งรัฐบาล · '
            'ความหมายจากตำราที่ระบุแหล่งอ้างอิงได้ทุกข้อ'),
      ],
    );
  }
}

/// One drawn number: how often it came out, and what ตำรา tie to it.
///
/// The meaning is the point of the row, so it is not tucked behind a tap. A
/// number with no reading says so plainly rather than being hidden — the
/// library covers about half the two-digit range so far, and quietly dropping
/// the rest would misrepresent the collection.
class _DrawnRow extends StatelessWidget {
  const _DrawnRow({required this.drawn, required this.maxTimes});

  final DrawnNumber drawn;
  final int maxTimes;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final ratio = maxTimes == 0 ? 0.0 : drawn.times / maxTimes;

    return SectionCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      onTap: drawn.hasMeaning
          ? () => context.go('/trends/symbol/${drawn.symbols.first.slug}')
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: NimitColors.gold,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(drawn.number,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: NimitColors.aubergineDeep,
                      fontFeatures: [FontFeature.tabularFigures()],
                    )),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ออก ${drawn.times} ครั้ง',
                        style: textTheme.titleSmall!
                            .copyWith(fontWeight: FontWeight.w700)),
                    if (drawn.lastSeen != null)
                      Text('ล่าสุด ${formatThaiDate(drawn.lastSeen!)}',
                          style: textTheme.bodySmall!
                              .copyWith(color: NimitColors.inkSoft)),
                  ],
                ),
              ),
              if (drawn.hasMeaning)
                const Icon(Icons.chevron_right, color: NimitColors.inkSoft),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: NimitColors.creamDeep,
              valueColor: const AlwaysStoppedAnimation(NimitColors.goldDeep),
            ),
          ),
          const SizedBox(height: 10),
          if (drawn.hasMeaning)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('ตำราว่า',
                    style: textTheme.bodySmall!
                        .copyWith(color: NimitColors.inkSoft)),
                for (final s in drawn.symbols)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: NimitColors.pastelLavender,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(s.nameTh,
                        style: textTheme.bodyMedium!
                            .copyWith(fontWeight: FontWeight.w700)),
                  ),
              ],
            )
          else
            Text('ยังไม่มีความหมายของเลขนี้ในคลังตำรา',
                style:
                    textTheme.bodySmall!.copyWith(color: NimitColors.inkSoft)),
        ],
      ),
    );
  }
}
