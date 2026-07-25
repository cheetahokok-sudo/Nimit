import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nimit_theme.dart';
import '../../core/widgets/section.dart';
import '../../data/providers.dart';

class DreamEntryScreen extends ConsumerStatefulWidget {
  const DreamEntryScreen({super.key});

  @override
  ConsumerState<DreamEntryScreen> createState() => _DreamEntryScreenState();
}

class _DreamEntryScreenState extends ConsumerState<DreamEntryScreen> {
  final _controller = TextEditingController();
  String? _feeling;
  String? _timeOfNight;
  bool _analyzing = false;

  static const _feelings = ['สงบ', 'กลัว', 'ดีใจ', 'ประหลาดใจ'];
  static const _times = ['ก่อนเที่ยงคืน', 'กลางคืน', 'รุ่งเช้า', 'ไม่แน่ใจ'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เล่าความฝันของคุณก่อนเริ่มวิเคราะห์')),
      );
      return;
    }
    setState(() => _analyzing = true);
    try {
      final analysis = await ref.read(dreamRepositoryProvider).analyze(
            text,
            feelingTh: _feeling,
            timeOfNightTh: _timeOfNight,
          );
      if (mounted) context.go('/dream/result', extra: analysis);
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text('เล่าความฝัน',
            style: textTheme.headlineSmall!
                .copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const DisclaimerText(
            'ยิ่งเล่ารายละเอียดมาก ยิ่งแยกสัญลักษณ์ได้ชัดขึ้น'),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ความฝันของคุณ',
                  style: textTheme.titleSmall!
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              TextField(
                controller: _controller,
                maxLines: 5,
                maxLength: 400,
                decoration: const InputDecoration(
                  hintText:
                      'เช่น ฝันเห็นงูสีขาวอยู่หน้าบ้าน แล้วมีฝนตกเบา ๆ แต่ฉันไม่กลัว',
                  suffixIcon: Icon(Icons.mic_none, color: NimitColors.inkSoft),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const SectionHeader('คุณรู้สึกอย่างไรในฝัน?'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final f in _feelings)
              ChoiceChip(
                label: Text(f),
                selected: _feeling == f,
                selectedColor: NimitColors.pastelGreen,
                onSelected: (_) => setState(() => _feeling = f),
              ),
          ],
        ),
        const SizedBox(height: 18),
        const SectionHeader('จำได้ว่าเกิดช่วงไหน?'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in _times)
              ChoiceChip(
                label: Text(t),
                selected: _timeOfNight == t,
                selectedColor: NimitColors.pastelPink,
                onSelected: (_) => setState(() => _timeOfNight = t),
              ),
          ],
        ),
        const SizedBox(height: 18),
        SectionCard(
          color: NimitColors.pastelLavender,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ระบบจะใช้ข้อมูลนี้อย่างไร',
                  style: textTheme.labelLarge!
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                'แยกสัญลักษณ์ • เปรียบเทียบตำรา • สร้างเลขเชิงสัญลักษณ์',
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _analyzing ? null : _analyze,
          child: _analyzing
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: NimitColors.onDark),
                )
              : const Text('วิเคราะห์ความฝัน'),
        ),
      ],
    );
  }
}
