import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/links.dart';
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
            // A statement, not a button. It used to be a control that opened
            // nothing and apologised in a snackbar — a promise the app could
            // not keep, on the one screen whose whole subject is keeping them.
            if (count != null) ...[
              const SizedBox(height: 4),
              DisclaimerText('ขณะนี้คลังอ้างอิงมี $count รายการ'),
            ],
            const SizedBox(height: 24),
            const SectionHeader('เกี่ยวกับแอป'),
            const SizedBox(height: 12),
            _LinkCard(
              title: 'นโยบายความเป็นส่วนตัว',
              caption: 'ข้อมูลของคุณอยู่ในเครื่อง ไม่ถูกส่งออก',
              url: NimitLinks.privacy,
            ),
            const SizedBox(height: 12),
            _LinkCard(
              title: 'ติดต่อ / ช่วยเหลือ',
              caption: 'ถามปัญหา แจ้งข้อผิดพลาด หรือทักท้วงที่มา',
              url: NimitLinks.support,
            ),
          ],
        ),
      ),
    );
  }
}

/// A row that leaves the app.
///
/// Both destinations are web pages, so they open in the browser rather than in
/// a view inside the app: a privacy policy the user cannot check the address
/// bar of is worth less than one they can.
class _LinkCard extends StatelessWidget {
  const _LinkCard({
    required this.title,
    required this.caption,
    required this.url,
  });

  final String title;
  final String caption;
  final String url;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SectionCard(
      onTap: () => _open(context),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: textTheme.titleSmall!
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                DisclaimerText(caption),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.open_in_new, size: 20, color: NimitColors.inkSoft),
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    var opened = false;
    try {
      opened = await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('เปิดลิงก์ไม่สำเร็จ')),
      );
    }
  }
}
