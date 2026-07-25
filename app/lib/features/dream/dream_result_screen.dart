import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nimit_theme.dart';
import '../../core/widgets/number_pill.dart';
import '../../core/widgets/section.dart';
import '../../core/widgets/source_badge.dart';
import '../../data/models/dream.dart';
import '../../data/providers.dart';

class DreamResultScreen extends ConsumerStatefulWidget {
  const DreamResultScreen({super.key, this.analysis});

  final DreamAnalysis? analysis;

  @override
  ConsumerState<DreamResultScreen> createState() => _DreamResultScreenState();
}

class _DreamResultScreenState extends ConsumerState<DreamResultScreen> {
  bool _saved = false;

  Future<void> _saveToJournal(DreamAnalysis analysis) async {
    await ref.read(journalProvider.notifier).save(
          DreamEntry(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: analysis.headlineTh,
            createdAt: DateTime.now(),
            headlineTh: analysis.headlineTh,
            numbers: analysis.numbers,
          ),
        );
    if (mounted) setState(() => _saved = true);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final analysis = widget.analysis;

    if (analysis == null) {
      // Deep link without state — send back to entry.
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
                          onPressed: () => _saveToJournal(analysis),
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in analysis.symbols)
              Chip(label: Text('${s.nameTh}  •  ${s.count}')),
          ],
        ),
        const SizedBox(height: 16),
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
                      child: Text(interp.sourceNameTh,
                          style: textTheme.labelMedium!
                              .copyWith(color: NimitColors.inkSoft)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(interp.textTh, style: textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 6),
        const SectionHeader('เลขเชิงสัญลักษณ์',
            caption: 'สร้างจากสัญลักษณ์ในฝัน ไม่ใช่โอกาสถูกรางวัล'),
        const SizedBox(height: 10),
        NumberPillRow(analysis.numbers),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: FilledButton(
                onPressed: () => context.go('/dream/share', extra: analysis),
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
