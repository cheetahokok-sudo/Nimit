import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nimit_theme.dart';
import '../../core/widgets/section.dart';
import '../../core/widgets/source_badge.dart';
import '../../data/models/library.dart';
import '../../data/providers.dart';

/// เรื่องราวของสัญลักษณ์ — the library browse screen.
///
/// Everything a user can ask about one symbol in one place: what the ตำรา say,
/// which book and which page each reading comes from, the original wording
/// where the work is free, the numbers tied to it, and the neighbouring
/// symbols to wander into.
///
/// Reached from กระแสปีนี้ (a number that came out → what it means) and from a
/// dream result. It is the screen that turns the library from a claim in the
/// marketing into something a reader can actually check.
class SymbolStoryScreen extends ConsumerWidget {
  const SymbolStoryScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final story = ref.watch(symbolStoryProvider(slug));
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'ย้อนกลับ',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/trends'),
              icon: const Icon(Icons.arrow_back, color: NimitColors.ink),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text('เรื่องราวของสัญลักษณ์',
                  style: textTheme.titleMedium!
                      .copyWith(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        story.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => const SectionCard(
            child: DisclaimerText(
                'ยังเปิดเรื่องราวของสัญลักษณ์นี้ไม่ได้ ลองใหม่อีกครั้ง'),
          ),
          data: (s) => _Story(story: s),
        ),
      ],
    );
  }
}

class _Story extends ConsumerWidget {
  const _Story({required this.story});

  final SymbolStory story;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(story.category,
                  style: textTheme.labelMedium!
                      .copyWith(color: NimitColors.gold)),
              const SizedBox(height: 4),
              Text(story.nameTh,
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      color: NimitColors.onDark)),
              if (story.summaryTh != null && story.summaryTh!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(story.summaryTh!,
                    style: textTheme.bodyMedium!
                        .copyWith(color: NimitColors.onDarkSoft)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Numbers first: for this audience it is the thing they came for, and
        // burying it under prose would be pretending otherwise.
        if (story.hasNumbers) ...[
          const SectionHeader('เลขประจำสัญลักษณ์',
              caption: 'ตามที่ตำราผูกไว้ ไม่ได้เพิ่มโอกาสถูกรางวัล'),
          const SizedBox(height: 10),
          _WatchableNumbers(story: story),
          const SizedBox(height: 20),
        ],

        SectionHeader('คำแปลจากตำรา',
            caption: story.hasReadings
                ? '${story.readings.length} สำนวน จากแหล่งที่ตรวจสอบได้'
                : null),
        const SizedBox(height: 10),
        if (!story.hasReadings)
          const SectionCard(
            color: NimitColors.pastelLavender,
            child: DisclaimerText(
                'สัญลักษณ์นี้อยู่ในคลังแล้ว แต่ยังไม่มีคำแปลที่ผ่านการตรวจสอบแหล่งที่มา — '
                'นิมิตจะไม่แต่งคำแปลขึ้นเองโดยไม่มีตำรารองรับ'),
          )
        else
          for (final r in story.readings) ...[
            _ReadingCard(reading: r),
            const SizedBox(height: 10),
          ],

        if (story.narrower.isNotEmpty) ...[
          const SizedBox(height: 12),
          const SectionHeader('แยกย่อยเป็น'),
          const SizedBox(height: 10),
          _SymbolChips(symbols: story.narrower),
        ],
        if (story.related.isNotEmpty) ...[
          const SizedBox(height: 18),
          const SectionHeader('สัญลักษณ์ใกล้เคียง'),
          const SizedBox(height: 10),
          _SymbolChips(symbols: story.related),
        ],

        if (story.ethicsNoteTh != null && story.ethicsNoteTh!.isNotEmpty) ...[
          const SizedBox(height: 18),
          SectionCard(
            color: NimitColors.warnBg,
            child: Text(story.ethicsNoteTh!,
                style: textTheme.bodySmall!
                    .copyWith(color: NimitColors.warnInk)),
          ),
        ],
      ],
    );
  }
}

/// Numbers here behave exactly as they do on the dream result: tapping keeps
/// one in เลขที่ตามอยู่, and the app can later say whether it came out — never
/// that the user won money, because holding a number is not holding a ticket.
class _WatchableNumbers extends ConsumerWidget {
  const _WatchableNumbers({required this.story});

  final SymbolStory story;

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
            for (final n in story.numbers)
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  final notifier = ref.read(watchedNumbersProvider.notifier);
                  if (watchedSet.contains(n)) {
                    await notifier.remove(n);
                    return;
                  }
                  await notifier.watch(n, sourceTh: 'จากตำรา · ${story.nameTh}');
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('เก็บเลข $n ไว้ดูตอนหวยออก'),
                    action: SnackBarAction(
                      label: 'ไปตรวจหวย',
                      onPressed: () => context.go('/lottery'),
                    ),
                  ));
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  decoration: BoxDecoration(
                    color: watchedSet.contains(n)
                        ? NimitColors.aubergine
                        : NimitColors.gold,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(n,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            color: watchedSet.contains(n)
                                ? NimitColors.onDark
                                : NimitColors.aubergineDeep,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          )),
                      const SizedBox(width: 8),
                      Icon(watchedSet.contains(n) ? Icons.check : Icons.add,
                          size: 18,
                          color: watchedSet.contains(n)
                              ? NimitColors.gold
                              : NimitColors.aubergineDeep),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const DisclaimerText(
          'แตะเพื่อเก็บไว้ดูตอนหวยออก — เลขที่ตามอยู่ไม่ใช่สลาก '
          'ถึงเลขจะออกก็ต้องมีสลากตัวจริงจึงจะขึ้นเงินได้',
        ),
      ],
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({required this.reading});

  final SymbolReading reading;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SourceBadge(reading.tier, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reading.workTh,
                        style: textTheme.titleSmall!
                            .copyWith(fontWeight: FontWeight.w700)),
                    if (reading.locatorTh != null)
                      Text(reading.locatorTh!,
                          style: textTheme.bodySmall!
                              .copyWith(color: NimitColors.inkSoft)),
                  ],
                ),
              ),
            ],
          ),
          if (reading.plainTh != null) ...[
            const SizedBox(height: 10),
            Text(reading.plainTh!,
                style: textTheme.bodyMedium!.copyWith(height: 1.5)),
          ],
          if (reading.bodyTh != null && reading.bodyTh != reading.plainTh) ...[
            const SizedBox(height: 8),
            Text(reading.bodyTh!,
                style: textTheme.bodySmall!
                    .copyWith(color: NimitColors.inkSoft, height: 1.5)),
          ],
          // Verbatim source text, present only where the work is free. This is
          // the whole proposition made visible: the reader sees what the ตำรา
          // actually says, not only our summary of it.
          if (reading.quoteTh != null && reading.quoteTh!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NimitColors.creamDeep,
                borderRadius: BorderRadius.circular(12),
                border: const Border(
                    left: BorderSide(color: NimitColors.gold, width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ข้อความต้นฉบับ',
                      style: textTheme.labelSmall!.copyWith(
                          color: NimitColors.inkSoft,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(reading.quoteTh!,
                      style: textTheme.bodySmall!
                          .copyWith(height: 1.7, color: NimitColors.ink)),
                ],
              ),
            ),
          ],
          if (reading.contextNoteTh != null) ...[
            const SizedBox(height: 10),
            Text(reading.contextNoteTh!,
                style: textTheme.bodySmall!
                    .copyWith(color: NimitColors.warnInk, height: 1.45)),
          ],
        ],
      ),
    );
  }
}

class _SymbolChips extends StatelessWidget {
  const _SymbolChips({required this.symbols});

  final List<RelatedSymbol> symbols;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final s in symbols)
          ActionChip(
            label: Text(s.nameTh),
            backgroundColor: NimitColors.surface,
            side: const BorderSide(color: NimitColors.border),
            onPressed: () => context.go('/trends/symbol/${s.slug}'),
          ),
      ],
    );
  }
}
