import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

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
  bool _busy = false;

  /// Wraps the card so it can be rasterised exactly as it appears.
  final _cardKey = GlobalKey();

  /// Anchors the iPad share popover. See _shareCard.
  final _shareButtonKey = GlobalKey();

  /// Renders the card to PNG and hands it to the system share sheet.
  ///
  /// ONE ACTION, NOT FOUR. The screen used to show LINE, TikTok, Facebook and
  /// บันทึก as separate buttons, each raising a snackbar saying the feature was
  /// not enabled. Four dead buttons is precisely what App Store review rejects
  /// under App Completeness, and building four real integrations would be worse
  /// engineering for the same result:
  ///
  ///   * TikTok has no URL scheme for handing over an image; it needs their SDK
  ///     and a registered app key.
  ///   * Facebook's web sharer takes a URL, not a local file, so it cannot
  ///     carry a card that exists only on the device.
  ///   * LINE's scheme can carry text but not an image.
  ///   * Saving to Photos needs a gallery plugin and a photo-library permission
  ///     — an extra permission prompt and a privacy-manifest entry for
  ///     something the share sheet already does.
  ///
  /// The system sheet offers all four destinations and any others the user has
  /// installed, needs no per-app keys, and is the path Apple expects. So the
  /// four buttons become one that works, and the caption names where it leads.
  Future<void> _shareCard() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('card not laid out');

      // 3x so the card stays crisp when a messaging app re-compresses it.
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) throw StateError('card produced no image');

      // XFile.fromData keeps the bytes in memory rather than writing a temp
      // file, so this needs no path_provider and leaves nothing on disk. The
      // card can contain the user's own dream text; it should not outlive the
      // share.
      final file = XFile.fromData(
        data.buffer.asUint8List(),
        mimeType: 'image/png',
        name: 'nimit-card.png',
      );
      // sharePositionOrigin is not optional on iPad. UIActivityViewController
      // is presented as a popover there and UIKit raises if it has nothing to
      // point at — an outright crash, on the device Apple reviews with. The
      // button's own rect is the natural anchor; iPhone and Android ignore it.
      final button =
          _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
      final origin = button == null
          ? null
          : button.localToGlobal(Offset.zero) & button.size;

      await SharePlus.instance.share(
        ShareParams(
          files: [file],
          subject: 'นิมิตเมื่อคืน',
          sharePositionOrigin: origin,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Says what failed. The old snackbar announced a missing feature; this
      // one only appears when a real attempt did not complete.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยังแชร์การ์ดไม่ได้ ลองใหม่อีกครั้ง')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
        Text(
          'สร้างการ์ดแชร์',
          style: textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        // Only the card itself is inside the boundary — the toggles and buttons
        // below must not appear in the shared image.
        RepaintBoundary(
          key: _cardKey,
          child: DarkCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'นิมิตเมื่อคืน',
                        style: textTheme.labelMedium!.copyWith(
                          color: NimitColors.gold,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.nightlight_round,
                      color: NimitColors.gold,
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  headline,
                  style: textTheme.headlineSmall!.copyWith(
                    color: NimitColors.onDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subline,
                  style: textTheme.bodySmall!.copyWith(
                    color: NimitColors.onDarkSoft,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'เลขเชิงสัญลักษณ์',
                  style: textTheme.labelSmall!.copyWith(
                    color: NimitColors.onDarkSoft,
                  ),
                ),
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
                Text(
                  'อ้างอิง $sourceCount แหล่ง • ความเชื่อส่วนบุคคล',
                  style: textTheme.labelSmall!.copyWith(
                    color: NimitColors.onDarkSoft,
                  ),
                ),
                Text(
                  'nimit.app/d/8Q2F',
                  style: textTheme.labelSmall!.copyWith(
                    color: NimitColors.gold,
                  ),
                ),
              ],
            ),
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
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: _shareButtonKey,
            onPressed: _busy ? null : _shareCard,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share),
            label: Text(_busy ? 'กำลังสร้างรูป…' : 'แชร์การ์ดนี้'),
          ),
        ),
        const SizedBox(height: 8),
        const DisclaimerText(
          'เลือก LINE · TikTok · Facebook หรือบันทึกลงคลังรูปภาพ '
          'ได้จากหน้าต่างแชร์ของเครื่อง',
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
