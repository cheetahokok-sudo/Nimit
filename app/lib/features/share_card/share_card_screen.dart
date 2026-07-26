import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nimit_theme.dart';
import '../../core/widgets/section.dart';
import '../../data/providers.dart';

class ShareCardScreen extends ConsumerStatefulWidget {
  const ShareCardScreen({super.key});

  @override
  ConsumerState<ShareCardScreen> createState() => _ShareCardScreenState();
}

class _ShareCardScreenState extends ConsumerState<ShareCardScreen> {
  bool _hideName = true;
  bool _hideBirthTime = true;
  bool _showSources = false;

  void _stubShare(String channel) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('การแชร์ไป $channel ยังไม่เปิดในเวอร์ชันทดลอง')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // The session provider survives tab switches, unlike router `extra` —
    // reaching this screen from the home teaser used to silently show the
    // sample card instead of the user's own dream. Without a session (e.g.
    // the home "ดูตัวอย่าง" teaser before any dream), fall back to a sample
    // card — a white bird, not a snake, since samples are shown to everyone.
    final analysis = ref.watch(dreamSessionProvider)?.analysis;
    final headline = analysis?.headlineTh ?? 'นกสีขาว';
    final subline = analysis == null ? 'หน้าบ้านในคืนฝนตก' : analysis.themeTh;
    final numbers = analysis?.numbers ?? const ['16', '61', '269'];
    final sourceCount = analysis?.sourceCount ?? 3;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text('สร้างการ์ดแชร์',
            style: textTheme.headlineSmall!
                .copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        DarkCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('นิมิตเมื่อคืน',
                        style: textTheme.labelMedium!
                            .copyWith(color: NimitColors.gold)),
                  ),
                  const Icon(Icons.nightlight_round,
                      color: NimitColors.gold, size: 22),
                ],
              ),
              const SizedBox(height: 16),
              Text(headline,
                  style: textTheme.headlineSmall!.copyWith(
                      color: NimitColors.onDark, fontWeight: FontWeight.w800)),
              Text(subline,
                  style: textTheme.bodySmall!
                      .copyWith(color: NimitColors.onDarkSoft)),
              const SizedBox(height: 20),
              Text('เลขเชิงสัญลักษณ์',
                  style: textTheme.labelSmall!
                      .copyWith(color: NimitColors.onDarkSoft)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  for (final n in numbers)
                    Text(
                      n,
                      style: TextStyle(
                        fontSize: n.length > 2 ? 44 : 34,
                        fontWeight: FontWeight.w800,
                        color: n.length > 2
                            ? NimitColors.gold
                            : NimitColors.onDark,
                        height: 1.0,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: NimitColors.aubergineDeep, height: 1),
              const SizedBox(height: 12),
              Text('อ้างอิง $sourceCount แหล่ง • ความเชื่อส่วนบุคคล',
                  style: textTheme.labelSmall!
                      .copyWith(color: NimitColors.onDarkSoft)),
              Text('nimit.app/d/8Q2F',
                  style: textTheme.labelSmall!
                      .copyWith(color: NimitColors.gold)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionHeader('เลือกข้อมูลที่จะแสดง'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('ไม่แสดงชื่อ'),
              selected: _hideName,
              selectedColor: NimitColors.pastelGreen,
              onSelected: (v) => setState(() => _hideName = v),
            ),
            FilterChip(
              label: const Text('ซ่อนเวลาเกิด'),
              selected: _hideBirthTime,
              selectedColor: NimitColors.pastelGreen,
              onSelected: (v) => setState(() => _hideBirthTime = v),
            ),
            FilterChip(
              label: const Text('แสดงแหล่งที่มา'),
              selected: _showSources,
              selectedColor: NimitColors.pastelGreen,
              onSelected: (v) => setState(() => _showSources = v),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const SectionHeader('แชร์ไปยัง'),
        const SizedBox(height: 10),
        Row(
          children: [
            _ShareTarget(
                label: 'LINE',
                color: NimitColors.pastelGreen,
                onTap: () => _stubShare('LINE')),
            const SizedBox(width: 10),
            _ShareTarget(
                label: 'TikTok',
                color: NimitColors.pastelPink,
                onTap: () => _stubShare('TikTok')),
            const SizedBox(width: 10),
            _ShareTarget(
                label: 'Facebook',
                color: NimitColors.pastelBlue,
                onTap: () => _stubShare('Facebook')),
            const SizedBox(width: 10),
            _ShareTarget(
                label: 'บันทึก',
                color: NimitColors.pastelCream,
                onTap: () => _stubShare('คลังรูปภาพ')),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => context.go('/dream'),
            child: const Text('กลับไปเล่าความฝันใหม่'),
          ),
        ),
      ],
    );
  }
}

class _ShareTarget extends StatelessWidget {
  const _ShareTarget(
      {required this.label, required this.color, required this.onTap});

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium!
                  .copyWith(fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
