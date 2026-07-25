import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/nimit_theme.dart';
import '../../core/widgets/section.dart';
import '../../data/models/trends.dart';
import '../../data/providers.dart';

class TrendsScreen extends ConsumerWidget {
  const TrendsScreen({super.key});

  static const _regions = ['ทั่วประเทศไทย', 'กรุงเทพฯ', 'เหนือ', 'อีสาน'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final region = ref.watch(trendsRegionProvider);
    final trends = ref.watch(trendsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text('กระแสวันนี้',
            style: textTheme.headlineSmall!
                .copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final r in _regions) ...[
                ChoiceChip(
                  label: Text(r),
                  selected: region == r,
                  selectedColor: NimitColors.aubergine,
                  labelStyle: TextStyle(
                    color: region == r ? NimitColors.onDark : NimitColors.ink,
                  ),
                  onSelected: (_) =>
                      ref.read(trendsRegionProvider.notifier).select(r),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        trends.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => const DisclaimerText('โหลดข้อมูลไม่สำเร็จ'),
          data: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DarkCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('สัญลักษณ์มาแรง',
                        style: textTheme.labelMedium!
                            .copyWith(color: NimitColors.onDarkSoft)),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data.hotSymbol.nameTh,
                                  style: textTheme.headlineSmall!.copyWith(
                                      color: NimitColors.onDark,
                                      fontWeight: FontWeight.w800)),
                              Text(
                                  'การพูดถึงเพิ่มขึ้น ${data.hotSymbol.changePercent}% วันนี้',
                                  style: textTheme.bodySmall!.copyWith(
                                      color: NimitColors.onDarkSoft)),
                            ],
                          ),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: NimitColors.gold,
                            foregroundColor: NimitColors.aubergineDeep,
                            minimumSize: const Size(0, 40),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 18),
                          ),
                          onPressed: () {},
                          child: const Text('ดูเรื่องราว'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(data.hotSymbol.noteTh,
                        style: textTheme.labelSmall!
                            .copyWith(color: NimitColors.onDarkSoft)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const SectionHeader('เลขที่ถูกพูดถึง'),
              const SizedBox(height: 12),
              _MentionBars(mentions: data.mentions),
              const SizedBox(height: 20),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader('เรื่องราวจากชุมชน'),
                    const SizedBox(height: 8),
                    Text(data.story.quoteTh, style: textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SectionCard(
                color: NimitColors.pastelLavender,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('สร้างโพสต์จากความฝันของคุณ',
                        style: textTheme.titleSmall!
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const DisclaimerText(
                        'ปลดล็อกธีมการ์ด ไม่เพิ่มความแม่นของเลข'),
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

/// Horizontal bar chart of number mentions — pure widgets, no chart library.
class _MentionBars extends StatelessWidget {
  const _MentionBars({required this.mentions});

  final List<NumberMention> mentions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final max = mentions.fold<int>(1, (m, e) => e.count > m ? e.count : m);
    return Column(
      children: [
        for (final m in mentions)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(m.number,
                      style: textTheme.titleSmall!
                          .copyWith(fontWeight: FontWeight.w800)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: m.count / max,
                      minHeight: 14,
                      backgroundColor: NimitColors.creamDeep,
                      valueColor: const AlwaysStoppedAnimation(
                          NimitColors.goldDeep),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 30,
                  child: Text('${m.count}',
                      textAlign: TextAlign.end,
                      style: textTheme.labelSmall!
                          .copyWith(color: NimitColors.inkSoft)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
