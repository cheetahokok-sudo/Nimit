import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/nimit_theme.dart';
import '../../core/widgets/section.dart';
import '../../core/widgets/source_badge.dart';
import '../../data/providers.dart';

class SourcesScreen extends ConsumerWidget {
  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final tiers = ref.watch(sourceTiersProvider);
    // Null while loading or on error: the button then omits the number
    // entirely rather than claiming "0 รายการ" — never display a made-up
    // count in a product about verifiable sourcing.
    final count = ref.watch(sourceLibraryCountProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text('แหล่งอ้างอิง',
            style:
                textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w800)),
      ),
      body: tiers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            const Center(child: DisclaimerText('โหลดข้อมูลไม่สำเร็จ')),
        data: (list) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            const DisclaimerText('ทุกคำแปลควรมีที่มา'),
            const SizedBox(height: 14),
            for (final tier in list) ...[
              SectionCard(
                child: Row(
                  children: [
                    SourceBadge(tier),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tier.titleTh,
                              style: textTheme.titleSmall!
                                  .copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(tier.descriptionTh,
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
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('คลังตำรายังไม่เปิดในเวอร์ชันทดลอง')),
                );
              },
              child: Text(count == null
                  ? 'เปิดคลังตำรา'
                  : 'เปิดคลังตำรา $count รายการ'),
            ),
          ],
        ),
      ),
    );
  }
}
