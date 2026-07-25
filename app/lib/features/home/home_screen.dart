import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nimit_theme.dart';
import '../../core/widgets/number_pill.dart';
import '../../core/widgets/section.dart';
import '../../data/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final numbers = ref.watch(todaysNumbersProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          'คืนนี้ความฝัน\nอาจกำลังบอกอะไรกับคุณ',
          style: textTheme.headlineSmall!
              .copyWith(fontWeight: FontWeight.w800, height: 1.25),
        ),
        const SizedBox(height: 4),
        const DisclaimerText(
            'แปลความหมายจากหลายตำรา พร้อมเลขเชิงสัญลักษณ์'),
        const SizedBox(height: 16),

        // เล่าความฝันเมื่อคืน — hero CTA
        DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('เล่าความฝันเมื่อคืน',
                  style: textTheme.titleMedium!.copyWith(
                      color: NimitColors.onDark,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('พิมพ์หรือพูด เช่น “ฝันเห็นงูสีขาวหน้าบ้าน”',
                  style: textTheme.bodySmall!
                      .copyWith(color: NimitColors.onDarkSoft)),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: NimitColors.aubergineDeep,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('เมื่อคืนฉันฝันว่า...',
                          style: textTheme.bodyMedium!
                              .copyWith(color: NimitColors.onDarkSoft)),
                    ),
                    const Icon(Icons.mic_none,
                        color: NimitColors.onDarkSoft, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: NimitColors.gold,
                  foregroundColor: NimitColors.aubergineDeep,
                  minimumSize: const Size.fromHeight(44),
                ),
                onPressed: () => context.go('/dream'),
                child: const Text('เริ่มวิเคราะห์'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const SectionHeader('เลขนิมิตวันนี้',
            caption: 'จากสัญลักษณ์ที่คุณบันทึกไว้ ไม่ใช่คำทำนายผล'),
        const SizedBox(height: 10),
        numbers.when(
          data: (list) => NumberPillRow(list),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => const DisclaimerText('โหลดข้อมูลไม่สำเร็จ'),
        ),
        const SizedBox(height: 20),

        SectionCard(
          onTap: () => context.go('/trends'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader('กำลังเป็นกระแสในไทย'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _TrendChip('งูขาว', NimitColors.pastelGreen),
                  _TrendChip('พระ', NimitColors.pastelCream),
                  _TrendChip('น้ำท่วม', NimitColors.pastelBlue),
                  _TrendChip('เด็ก', NimitColors.pastelLavender),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        SectionCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('การ์ดแชร์ยอดนิยม', style: textTheme.labelMedium),
                    const SizedBox(height: 2),
                    Text('“ฝันเห็นพญานาค”',
                        style: textTheme.titleMedium!
                            .copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    const DisclaimerText(
                        'แชร์เรื่องราว ไม่โชว์ข้อมูลเกิดหรือชื่อจริง'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                onPressed: () => context.go('/dream/share'),
                child: const Text('ดูตัวอย่าง'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrendChip extends StatelessWidget {
  const _TrendChip(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: Theme.of(context)
              .textTheme
              .labelMedium!
              .copyWith(fontWeight: FontWeight.w600)),
    );
  }
}
