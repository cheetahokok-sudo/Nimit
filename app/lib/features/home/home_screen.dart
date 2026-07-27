import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nimit_theme.dart';
import '../../core/widgets/number_pill.dart';
import '../../core/widgets/section.dart';
import '../../data/providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _dreamController = TextEditingController();
  bool _analyzing = false;

  @override
  void dispose() {
    _dreamController.dispose();
    super.dispose();
  }

  /// Quick entry from home: typed text analyzes immediately; an empty field
  /// falls through to the full entry form (feeling/time chips live there).
  /// The card used to be a decoration that merely LOOKED like an input —
  /// anything that looks typeable must be typeable.
  Future<void> _quickAnalyze() async {
    final text = _dreamController.text.trim();
    if (text.isEmpty) {
      context.go('/dream');
      return;
    }
    setState(() => _analyzing = true);
    try {
      final analysis =
          await ref.read(dreamRepositoryProvider).analyze(text);
      ref.read(dreamSessionProvider.notifier).start(
            DreamSession(text: text, analysis: analysis),
          );
      if (mounted) {
        _dreamController.clear();
        context.go('/dream/result');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('วิเคราะห์ไม่สำเร็จ ลองใหม่อีกครั้ง')),
        );
      }
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              // Example deliberately avoids snakes: many users dislike or
              // fear them, and the sample text is fed to everyone constantly.
              Text('พิมพ์หรือพูด เช่น “ฝันเห็นนกสีขาวหน้าบ้าน”',
                  style: textTheme.bodySmall!
                      .copyWith(color: NimitColors.onDarkSoft)),
              const SizedBox(height: 14),
              TextField(
                controller: _dreamController,
                maxLines: 2,
                minLines: 1,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _quickAnalyze(),
                style: textTheme.bodyMedium!
                    .copyWith(color: NimitColors.onDark),
                cursorColor: NimitColors.gold,
                decoration: InputDecoration(
                  hintText: 'เมื่อคืนฉันฝันว่า...',
                  hintStyle: textTheme.bodyMedium!
                      .copyWith(color: NimitColors.onDarkSoft),
                  filled: true,
                  fillColor: NimitColors.aubergineDeep,
                  suffixIcon: const Icon(Icons.mic_none,
                      color: NimitColors.onDarkSoft, size: 20),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: NimitColors.gold, width: 1.4),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: NimitColors.gold,
                  foregroundColor: NimitColors.aubergineDeep,
                  minimumSize: const Size.fromHeight(44),
                ),
                onPressed: _analyzing ? null : _quickAnalyze,
                child: _analyzing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: NimitColors.aubergineDeep),
                      )
                    : const Text('เริ่มวิเคราะห์'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const SectionHeader('เลขนิมิตจากความฝันของคุณ',
            caption: 'จากความฝันที่คุณบันทึกไว้ใน 7 วัน ไม่ใช่คำทำนายผล'),
        const SizedBox(height: 10),
        numbers.when(
          // Empty is a real and common state — a new user has recorded no
          // dreams. It must read as empty. This section previously rendered
          // four invented constants here, under a caption claiming they came
          // from the user's own symbols.
          data: (list) => list.isEmpty
              ? const SectionCard(
                  child: DisclaimerText(
                      'ยังไม่มีเลขจากความฝันของคุณ — เล่าความฝันแล้วเก็บ'
                      'เลขเชิงสัญลักษณ์ไว้ดูตอนหวยออกได้'),
                )
              : NumberPillRow(list),
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
                  _TrendChip('นกขาว', NimitColors.pastelGreen),
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
