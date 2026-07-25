import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/nimit_theme.dart';
import '../../core/utils/thai_date.dart';
import '../../core/widgets/section.dart';
import '../../data/providers.dart';

class LotteryScreen extends ConsumerStatefulWidget {
  const LotteryScreen({super.key});

  @override
  ConsumerState<LotteryScreen> createState() => _LotteryScreenState();
}

class _LotteryScreenState extends ConsumerState<LotteryScreen> {
  final _numberController = TextEditingController();

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final number = _numberController.text.trim();
    if (number.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรอกเลขให้ครบ 6 หลักก่อนตรวจ')),
      );
      return;
    }
    final message = await ref.read(lotteryRepositoryProvider).check(number);
    await ref.read(savedTicketsProvider.notifier).save(number);
    _numberController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _editBudget() async {
    final budget = await ref.read(budgetProvider.future);
    if (!mounted) return;
    final limitController =
        TextEditingController(text: budget.limit.toString());
    final spendController = TextEditingController();
    final result = await showDialog<({int? limit, int? spend})>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('งบความบันเทิงเดือนนี้'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: limitController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'งบต่อเดือน (บาท)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: spendController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                  labelText: 'บันทึกรายจ่ายเพิ่ม (บาท)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(context, (
              limit: int.tryParse(limitController.text),
              spend: int.tryParse(spendController.text),
            )),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
    if (result == null) return;
    final notifier = ref.read(budgetProvider.notifier);
    if (result.limit != null && result.limit! > 0) {
      await notifier.setLimit(result.limit!);
    }
    if (result.spend != null && result.spend! > 0) {
      await notifier.addSpend(result.spend!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final draw = ref.watch(currentDrawProvider);
    final tickets = ref.watch(savedTicketsProvider);
    final budget = ref.watch(budgetProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text('ตรวจหวยรัฐบาล',
            style: textTheme.headlineSmall!
                .copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        draw.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => const DisclaimerText('โหลดข้อมูลไม่สำเร็จ'),
          data: (info) => DarkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('งวดวันที่ ${formatThaiDate(info.drawDate)}',
                    style: textTheme.labelMedium!
                        .copyWith(color: NimitColors.gold)),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              info.isAnnounced
                                  ? 'ประกาศผลแล้ว'
                                  : 'ผลอย่างเป็นทางการ',
                              style: textTheme.titleMedium!.copyWith(
                                  color: NimitColors.onDark,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(info.statusTh,
                              style: textTheme.bodySmall!
                                  .copyWith(color: NimitColors.onDarkSoft)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: NimitColors.gold,
                        foregroundColor: NimitColors.aubergineDeep,
                        minimumSize: const Size(0, 38),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'การแจ้งเตือนยังไม่เปิดในเวอร์ชันทดลอง')),
                        );
                      },
                      child: const Text('ตั้งเตือน'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const SectionHeader('ตรวจเลขของคุณ'),
        const SizedBox(height: 10),
        TextField(
          controller: _numberController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w700, letterSpacing: 4),
          decoration: const InputDecoration(
            hintText: 'กรอกเลข 6 หลัก',
            counterText: '',
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: _check, child: const Text('ตรวจรางวัล')),
        const SizedBox(height: 20),
        tickets.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => const SizedBox.shrink(),
          data: (list) => list.isEmpty
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader('ตัวที่บันทึกไว้'),
                    const SizedBox(height: 10),
                    for (final t in list) ...[
                      SectionCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(t.number,
                                  style: textTheme.titleLarge!.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 3)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: NimitColors.warnBg,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text('ยังไม่ประกาศ',
                                  style: textTheme.labelSmall!.copyWith(
                                      color: NimitColors.warnInk,
                                      fontWeight: FontWeight.w700)),
                            ),
                            IconButton(
                              tooltip: 'ลบ',
                              onPressed: () => ref
                                  .read(savedTicketsProvider.notifier)
                                  .remove(t.number),
                              icon: const Icon(Icons.close,
                                  size: 18, color: NimitColors.inkSoft),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 10),
        budget.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => const SizedBox.shrink(),
          data: (b) => SectionCard(
            color: NimitColors.successBg,
            onTap: _editBudget,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('งบความบันเทิงเดือนนี้',
                          style: textTheme.titleSmall!.copyWith(
                              color: NimitColors.successInk,
                              fontWeight: FontWeight.w700)),
                    ),
                    const Icon(Icons.edit_outlined,
                        size: 16, color: NimitColors.successInk),
                  ],
                ),
                const SizedBox(height: 6),
                Text('ใช้แล้ว ฿${b.spent} จาก ฿${b.limit}',
                    style: textTheme.bodySmall!
                        .copyWith(color: NimitColors.successInk)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: b.ratio,
                    minHeight: 10,
                    backgroundColor: NimitColors.surface,
                    valueColor: const AlwaysStoppedAnimation(
                        NimitColors.successInk),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Center(
          child: DisclaimerText('เลขจากความฝันไม่เพิ่มโอกาสของผลสุ่ม',
              center: true),
        ),
      ],
    );
  }
}
