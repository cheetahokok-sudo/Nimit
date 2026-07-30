import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nimit_theme.dart';
import '../../core/widgets/section.dart';
import '../../data/providers.dart';

/// คลังตำรา — search the published library by Thai term.
///
/// The screen the "เปิดคลังตำรา" button promises: type a word, get the
/// symbols the ตำรา actually cover, follow one to its story with citations
/// and original text. Search returns names and teasers only; every reading
/// arrives on the story screen with its tier badge and source attached.
///
/// Results the server matched fuzzily are labelled as near-misses rather than
/// presented as hits, and a word the library does not hold says so honestly —
/// the gap is an editorial queue, not something to paper over.
class LibrarySearchScreen extends ConsumerStatefulWidget {
  const LibrarySearchScreen({super.key});

  @override
  ConsumerState<LibrarySearchScreen> createState() =>
      _LibrarySearchScreenState();
}

class _LibrarySearchScreenState extends ConsumerState<LibrarySearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  /// The query actually in flight — set after the debounce, not per keystroke,
  /// so half-typed words never reach the network.
  String _query = '';

  // Real published symbols, and deliberately no snake: sample text is shown
  // to everyone, and the example rule is นกสีขาว, not งู.
  static const _suggestions = ['นก', 'ช้าง', 'น้ำ', 'ทอง'];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _commit(text));
    // Rebuild now for the clear button; the query itself waits for the
    // debounce so half-typed words never reach the network.
    setState(() {});
  }

  void _commit(String text) {
    _debounce?.cancel();
    if (!mounted) return;
    setState(() => _query = text.trim());
  }

  void _useSuggestion(String word) {
    _controller.text = word;
    _commit(word);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // No Scaffold and no AppBar: คลังตำรา is a tab now, so AppShell supplies
    // both. It used to be pushed from an app-bar icon and carried its own.
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text('คลังตำรา',
            style:
                textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const DisclaimerText(
            'ค้นสัญลักษณ์จากคลังที่ทุกคำแปลมีที่มาตรวจสอบได้'),
        const SizedBox(height: 14),
        TextField(
          controller: _controller,
          onChanged: _onChanged,
          onSubmitted: _commit,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'เช่น นก ช้าง น้ำ',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'ล้างคำค้น',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _controller.clear();
                      _commit('');
                    },
                  ),
          ),
        ),
        const SizedBox(height: 16),
        ..._buildBody(textTheme),
      ],
    );
  }

  List<Widget> _buildBody(TextTheme textTheme) {
    if (_query.isEmpty) {
      return [
        const SectionHeader('ลองค้นดู'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final word in _suggestions)
              ActionChip(
                label: Text(word),
                backgroundColor: NimitColors.surface,
                side: const BorderSide(color: NimitColors.border),
                onPressed: () => _useSuggestion(word),
              ),
          ],
        ),
      ];
    }

    // The server rejects queries under two characters; guarding here turns
    // that rule into guidance instead of a failed round trip.
    if (_query.length < 2) {
      return const [
        SectionCard(
          child: DisclaimerText('พิมพ์อย่างน้อยสองตัวอักษรเพื่อค้นหา'),
        ),
      ];
    }

    final results = ref.watch(librarySearchProvider(_query));
    return [
      results.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => const SectionCard(
          child: DisclaimerText('ค้นหาไม่สำเร็จ ลองใหม่อีกครั้ง'),
        ),
        data: (list) => list.isEmpty
            ? SectionCard(
                color: NimitColors.pastelLavender,
                child: DisclaimerText(
                    'ยังไม่พบ "$_query" ในคลัง — คลังตำรายังเติบโตอยู่ '
                    'และนิมิตจะไม่แต่งความหมายขึ้นเองโดยไม่มีตำรารองรับ'),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (list.first.isFuzzy) ...[
                    const DisclaimerText(
                        'ไม่พบคำนี้ตรงตัว — นี่คือสัญลักษณ์ที่ใกล้เคียงที่สุด'),
                    const SizedBox(height: 10),
                  ],
                  for (final r in list) ...[
                    SectionCard(
                      onTap: () => context.go('/library/symbol/${r.slug}'),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.nameTh,
                                    style: textTheme.titleSmall!.copyWith(
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(r.category,
                                    style: textTheme.labelSmall!.copyWith(
                                        color: NimitColors.inkSoft)),
                                if (r.teaserTh.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(r.teaserTh,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.bodySmall!.copyWith(
                                          color: NimitColors.inkSoft)),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.chevron_right,
                              size: 20, color: NimitColors.inkSoft),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
      ),
    ];
  }
}
