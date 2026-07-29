import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nimit_theme.dart';
import '../../core/utils/thai_date.dart';
import '../../core/widgets/section.dart';
import '../../core/widgets/source_badge.dart';
import '../../data/models/dream.dart';
import '../../data/providers.dart';

class DreamResultScreen extends ConsumerStatefulWidget {
  const DreamResultScreen({super.key});

  @override
  ConsumerState<DreamResultScreen> createState() => _DreamResultScreenState();
}

class _DreamResultScreenState extends ConsumerState<DreamResultScreen> {
  bool _saved = false;

  Future<void> _saveToJournal(DreamSession session) async {
    // Persist the user's actual dream and the analysis snapshot — the journal
    // freezes what the user wrote and what they were shown, not a headline.
    await ref.read(journalProvider.notifier).save(
          DreamEntry(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: session.text,
            createdAt: DateTime.now(),
            feelingTh: session.feelingTh,
            timeOfNightTh: session.timeOfNightTh,
            headlineTh: session.analysis.headlineTh,
            numbers: session.analysis.numbers,
            analysis: session.analysis,
          ),
        );
    if (mounted) setState(() => _saved = true);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final session = ref.watch(dreamSessionProvider);
    final analysis = session?.analysis;

    if (session == null || analysis == null) {
      // Deep link or web refresh without a session — send back to entry.
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('ยังไม่มีความฝันที่วิเคราะห์'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/dream'),
                child: const Text('เล่าความฝันก่อน'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text('คำแปลความฝัน',
            style: textTheme.headlineSmall!
                .copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(analysis.headlineTh,
                            style: textTheme.titleMedium!.copyWith(
                                color: NimitColors.onDark,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('ธีมหลัก: ${analysis.themeTh}',
                            style: textTheme.bodySmall!
                                .copyWith(color: NimitColors.onDarkSoft)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _saved
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: NimitColors.gold,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text('บันทึกแล้ว',
                              style: textTheme.labelSmall!.copyWith(
                                  color: NimitColors.aubergineDeep,
                                  fontWeight: FontWeight.w700)),
                        )
                      : TextButton.icon(
                          style: TextButton.styleFrom(
                              foregroundColor: NimitColors.gold),
                          onPressed: () => _saveToJournal(session),
                          icon: const Icon(Icons.bookmark_add_outlined,
                              size: 18),
                          label: const Text('บันทึก'),
                        ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionHeader('สัญลักษณ์ที่พบ'),
        const SizedBox(height: 10),
        if (analysis.symbols.isEmpty)
          const SectionCard(
            color: NimitColors.pastelLavender,
            child: DisclaimerText(
                'ยังไม่พบสัญลักษณ์ที่รู้จักในคลัง — ลองเล่าด้วยคำที่เจาะจงขึ้น '
                'เช่น สิ่งที่เห็น สัตว์ สถานที่ หรือเหตุการณ์ในฝัน'),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in analysis.symbols)
                Chip(label: Text('${s.nameTh}  •  ${s.count}')),
            ],
          ),
        const SizedBox(height: 16),
        if (analysis.symbols.isNotEmpty && analysis.interpretations.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: DisclaimerText(
                'พบสัญลักษณ์ในคลัง แต่ยังไม่มีคำแปลที่ผ่านการตรวจสอบแหล่งที่มา — '
                'นิมิตจะไม่แต่งคำแปลขึ้นเองโดยไม่มีตำรารองรับ'),
          ),
        // NUMBERS BEFORE PROSE, and this is an audience decision rather than a
        // hierarchy-of-truth one. The people this app is for look for the เลข
        // first and read the ตำรา afterwards; burying the numbers under two
        // sections of prose asked them to scroll past the thing they opened the
        // screen for. Nothing about the claim changes by moving it — the
        // caption still says these are symbolic, not odds, and they still come
        // only from published number_association rows.
        //
        // The honest-absence line moves with it. A reader looking for numbers
        // should learn there are none in the same place they would have found
        // them, not after scrolling to the bottom to discover the section is
        // missing.
        if (analysis.numbers.isNotEmpty) ...[
          const SectionHeader('เลขเชิงสัญลักษณ์',
              caption: 'สร้างจากสัญลักษณ์ในฝัน ไม่ใช่โอกาสถูกรางวัล'),
          const SizedBox(height: 10),
          _WatchableNumbers(
            numbers: analysis.numbers,
            sourceTh: 'จากฝัน ${formatThaiDate(DateTime.now())}'
                '${analysis.headlineTh.isEmpty ? '' : ' · ${analysis.headlineTh}'}',
          ),
          const SizedBox(height: 20),
        ] else if (analysis.interpretations.isNotEmpty) ...[
          // Honest absence: Buddhist canonical sources never map to numbers,
          // so a canon-only result correctly has none — say so rather than
          // showing an empty header.
          const DisclaimerText(
              'แหล่งที่อ้างอิงในผลนี้ไม่ผูกเลขกับสัญลักษณ์'),
          const SizedBox(height: 16),
        ],
        // ภาษาชาวบ้านก่อนเสมอ: the audience reads two lines, not paragraphs.
        // These are editorial compressions of the cited text below — same
        // review rules, same sources — never generated on the fly.
        if (analysis.interpretations
            .any((i) => i.summaryPlainTh != null)) ...[
          const SectionHeader('แปลง่าย ๆ ได้ใจความ',
              caption: 'สรุปสั้นจากตำรา ไม่ใช่คำทำนายผล'),
          const SizedBox(height: 10),
          SectionCard(
            color: NimitColors.pastelCream,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final interp in analysis.interpretations)
                  if (interp.summaryPlainTh != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (interp.symbolTh != null)
                            Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: NimitColors.gold,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(interp.symbolTh!,
                                  style: textTheme.labelMedium!.copyWith(
                                      color: NimitColors.aubergineDeep,
                                      fontWeight: FontWeight.w700)),
                            ),
                          Expanded(
                            child: Text(interp.summaryPlainTh!,
                                style: textTheme.bodyLarge!
                                    .copyWith(height: 1.45)),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionHeader('อ้างอิงตำรา',
              caption: 'ฉบับเต็มพร้อมที่มา สำหรับผู้อยากอ่านลึก'),
          const SizedBox(height: 10),
        ],
        for (final interp in analysis.interpretations) ...[
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SourceBadge(interp.tier, size: 32),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(interp.sourceNameTh,
                              style: textTheme.labelMedium!
                                  .copyWith(color: NimitColors.inkSoft)),
                          if (interp.locatorTh != null)
                            Text(interp.locatorTh!,
                                style: textTheme.labelSmall!
                                    .copyWith(color: NimitColors.inkSoft)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(interp.textTh, style: textTheme.bodyMedium),
                if (interp.quoteTh != null) ...[
                  const SizedBox(height: 10),
                  // Verbatim source text — present only when the server
                  // decided the underlying work's rights permit it.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: NimitColors.creamDeep,
                      borderRadius: BorderRadius.circular(12),
                      border: const Border(
                          left: BorderSide(
                              color: NimitColors.goldDeep, width: 3)),
                    ),
                    child: Text(interp.quoteTh!,
                        style: textTheme.bodySmall!.copyWith(
                            fontStyle: FontStyle.italic,
                            color: NimitColors.ink)),
                  ),
                ],
                if (interp.contextNoteTh != null) ...[
                  const SizedBox(height: 10),
                  Text(interp.contextNoteTh!,
                      style: textTheme.bodySmall!
                          .copyWith(color: NimitColors.warnInk)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: FilledButton(
                onPressed: () => context.go('/dream/share'),
                child: const Text('สร้างการ์ดแชร์'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: OutlinedButton(
                onPressed: () => context.push('/sources'),
                child: const Text('อ่านทุกแหล่ง'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// เลขเชิงสัญลักษณ์ that can be carried over to ตรวจหวย.
///
/// Tapping a number adds it to เลขที่ตามอยู่ — a watch list, NOT the saved
/// ticket list. These are two or three digits; a ticket is six. The app can
/// tell the user later whether the number came out, and it deliberately cannot
/// tell them they won money, because holding a number is not holding a ticket.
class _WatchableNumbers extends ConsumerWidget {
  const _WatchableNumbers({required this.numbers, required this.sourceTh});

  final List<String> numbers;
  final String sourceTh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watched = ref.watch(watchedNumbersProvider).value ?? const [];
    final watchedSet = {for (final w in watched) w.number};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final n in numbers)
              _WatchChip(
                number: n,
                isWatched: watchedSet.contains(n),
                onTap: () async {
                  final notifier = ref.read(watchedNumbersProvider.notifier);
                  if (watchedSet.contains(n)) {
                    await notifier.remove(n);
                    return;
                  }
                  await notifier.watch(n, sourceTh: sourceTh);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('เก็บเลข $n ไว้ดูตอนหวยออก'),
                    action: SnackBarAction(
                      label: 'ไปตรวจหวย',
                      onPressed: () => context.go('/lottery'),
                    ),
                  ));
                },
              ),
          ],
        ),
        const SizedBox(height: 10),
        const DisclaimerText(
          'แตะเพื่อเก็บไว้ดูตอนหวยออก — แอปจะบอกว่าเลขนี้ออกหรือไม่ '
          'แต่ไม่ได้แปลว่าถูกรางวัล ต้องมีสลากตัวจริงเท่านั้น',
        ),
      ],
    );
  }
}

class _WatchChip extends StatelessWidget {
  const _WatchChip({
    required this.number,
    required this.isWatched,
    required this.onTap,
  });

  final String number;
  final bool isWatched;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isWatched ? NimitColors.aubergine : NimitColors.gold,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(number,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isWatched
                      ? NimitColors.onDark
                      : NimitColors.aubergineDeep,
                  fontFeatures: const [FontFeature.tabularFigures()],
                )),
            const SizedBox(width: 8),
            Icon(isWatched ? Icons.check : Icons.add,
                size: 18,
                color:
                    isWatched ? NimitColors.gold : NimitColors.aubergineDeep),
          ],
        ),
      ),
    );
  }
}
