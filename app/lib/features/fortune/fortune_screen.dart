import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thai_lunar/thai_lunar.dart' show isWanPhra;

import '../../core/calendar/thai_lunar_birth.dart';
import '../../core/theme/nimit_theme.dart';
import '../../core/utils/thai_date.dart';
import '../../core/widgets/section.dart';
import '../../data/models/fortune.dart';
import '../../data/providers.dart';
import 'celestial_orb.dart';

/// Diameter of the orbit motif, as a fraction of the card width.
///
/// RESPONSIVE, because a fixed size does not survive a 320 px phone. At that
/// width a 168 px orb leaves under 110 px for the headline, and the first fix
/// papered over it with a 150 px minimum — which simply forced the text back
/// under the graphic. The overlap test caught that immediately. Scaling the
/// motif instead keeps the same composition at every width.
double _orbSizeFor(double cardWidth) => (cardWidth * 0.42).clamp(112.0, 168.0);

/// How much of the orb runs past the right edge of the card. Named so the
/// layout and the graphic cannot disagree about it.
const double _orbBleed = 0.16;

/// ดวงของฉัน.
///
/// WHAT THIS SCREEN ONCE DID. It showed a ลัคนา, a badge claiming the user's
/// birth data was on file, four "เลขประจำดวง" and a line of money advice —
/// every one a constant in a mock, none backed by anything entered. All of it
/// was removed.
///
/// WHAT CAME BACK, AND WHY THAT IS FINE. The removal took the LOOK down with
/// the lies, and the look was good: a dark card with one large reverent line is
/// the right shape for a screen about ดวง. The card is back. What fills it is
/// now true — today's lunar date, written the way a ตำรา writes one, and a gold
/// pill that says ข้อมูลเกิดครบแล้ว only when the birth date genuinely is on
/// file. That sentence used to be false for everyone; now it is a fact about
/// storage the user can verify by deleting it.
///
/// THE ONE LINE NOT RESTORED. "เดือนนี้: เริ่มสิ่งใหม่อย่างมีแผน" was invented
/// advice with no ตำรา behind it. The slot survives, because a single personal
/// line under the headline is exactly right — but it carries the user's ทักษา
/// birth-day reading once that is published, and today's lunar standing
/// (วันพระ, ปีอธิกมาส) until then. Same rhythm, nothing made up.
class FortuneScreen extends ConsumerWidget {
  const FortuneScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(birthProfileProvider);

    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text('ดวงของฉัน',
            style:
                textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        profile.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 64),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => const SectionCard(
            child: DisclaimerText(
                'ยังอ่านข้อมูลในเครื่องไม่ได้ ลองเปิดหน้านี้ใหม่อีกครั้ง'),
          ),
          data: (p) => _Body(profile: p),
        ),
      ],
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.profile});

  final BirthProfile profile;

  Future<void> _openPicker(BuildContext context, WidgetRef ref) async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: NimitColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _BirthDateSheet(initial: profile.date),
    );
    if (picked != null) {
      await ref.read(birthProfileProvider.notifier).setDate(picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final birth = profile.isComplete
        ? _tryConvert(profile.date!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroCard(
          birth: birth,
          isSet: profile.isComplete,
          onTap: () => _openPicker(context, ref),
        ),
        const SizedBox(height: 18),

        if (birth != null) ...[
          _TaksaSection(weekday: birth.effectiveCivilDate.weekday),
          const SizedBox(height: 18),
          _BirthFacts(birth: birth),
        ] else ...[
          if (profile.needsUpgrade)
            SectionCard(
              color: NimitColors.pastelCream,
              child: DisclaimerText(
                  'เดิมคุณบอกไว้แค่เดือน ${thaiMonths[profile.legacyMonth! - 1]} '
                  'ขอวันและปีเกิดเพิ่ม เพราะเดือนทางจันทรคติคำนวณจากวันเดือนปีพร้อมกัน'),
            ),
        ],

        const SizedBox(height: 22),
        _PrivacyNote(canDelete: profile.isComplete),
        const SizedBox(height: 8),
        const _SourceFooter(),
      ],
    );
  }
}

/// Conversion can refuse (out of supported range). The screen must not render a
/// guessed month, so a refusal simply yields no card content.
ThaiLunarBirth? _tryConvert(DateTime date) {
  try {
    return const ThaiLunarBirthService().convert(date);
  } on RangeError {
    return null;
  }
}

/// The card the screen is built around.
///
/// Tappable throughout: entering a birth date is the one action here, and a
/// user who has not set one should not have to hunt for a control.
class _HeroCard extends ConsumerWidget {
  const _HeroCard({
    required this.birth,
    required this.isSet,
    required this.onTap,
  });

  final ThaiLunarBirth? birth;
  final bool isSet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    // Today, not the birth date: the headline is the standing of the day the
    // user is reading on, which is what a ตำรา-minded reader looks for first.
    final today = DateTime.now();
    final todayLunar = _tryConvert(DateTime(today.year, today.month, today.day));

    final phaseDay = todayLunar == null
        ? ''
        : '${todayLunar.phaseTh} ${thaiDigits(todayLunar.lunar.day)} ค่ำ';
    final monthName = todayLunar?.monthNameTh ?? 'วันนี้';

    return Material(
      color: NimitColors.aubergine,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        // Clipped so the orb can bleed off the right edge. A motif that stops
        // short of the border reads as a sticker; one that runs past it reads
        // as a window onto something larger.
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: LayoutBuilder(builder: (context, constraints) {
            // The text column is sized EXPLICITLY rather than left to fill the
            // Stack. A previous version of a card on this screen shipped with
            // colliding text, and "it looked fine on my device" is how that
            // happens: the orb occupies the right, so the words are told how
            // much room they actually have and wrap inside it.
            // Available text width, computed against what the orb ACTUALLY
            // occupies. The first version subtracted the orb from maxWidth and
            // forgot this padding, so the column ran ~25 px under the graphic —
            // and the 320 px test passed anyway, because it only checked for
            // overflow and overlapping text does not overflow. There is now a
            // geometry test that compares the two rectangles directly.
            const leftPad = 22.0;
            const gap = 10.0;
            final orbSize = _orbSizeFor(constraints.maxWidth);
            final orbVisible = orbSize * (1 - _orbBleed);
            final textWidth = math.max(
                140.0, constraints.maxWidth - leftPad - orbVisible - gap);

            return Stack(
              children: [
                Positioned(
                  right: -orbSize * _orbBleed,
                  top: -orbSize * 0.12,
                  child: CelestialOrb(size: orbSize),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(leftPad, 22, 22, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Headline and eyebrow sit level with the orb, so they are
                      // the parts that must stay narrow.
                      SizedBox(
                        width: textWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('วันนี้ทางจันทรคติ',
                                style: textTheme.labelMedium!.copyWith(
                                    color: NimitColors.gold,
                                    letterSpacing: 0.6)),
                            const SizedBox(height: 10),
                            // Split deliberately rather than left to wrap. The
                            // longest month name is เดือนแปดหลัง, which pushed
                            // "หลัง" onto a line of its own and looked like a
                            // mistake. Breaking after ค่ำ is also how a calendar
                            // sets it, and it makes the MONTH the hero — which
                            // is what the screen is about.
                            Text(phaseDay,
                                style: textTheme.titleMedium!.copyWith(
                                    color: NimitColors.onDarkSoft,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(monthName,
                                // Keyed for tests: the content is
                                // DateTime.now()'s lunar month, so any test
                                // that found this by TEXT would break the day
                                // the month turns.
                                key: const ValueKey('hero-month'),
                                style: textTheme.headlineSmall!.copyWith(
                                  color: NimitColors.onDark,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Below the orb's mass, so these may use the full width.
                      _HeroSubtitle(birth: birth, todayLunar: todayLunar),
                      const SizedBox(height: 16),
                      _HeroPill(isSet: isSet),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

/// The single personal line under the headline.
///
/// Precedence: a published ทักษา reading for the user's birth weekday, else
/// today's standing. Never a forecast — the slot that used to hold
/// "เริ่มสิ่งใหม่อย่างมีแผน" now holds something that is either cited or
/// checkable against a calendar.
class _HeroSubtitle extends ConsumerWidget {
  const _HeroSubtitle({required this.birth, required this.todayLunar});

  final ThaiLunarBirth? birth;
  final ThaiLunarBirth? todayLunar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    String line;
    if (birth != null) {
      final taksa = ref.watch(taksaProvider(birth!.effectiveCivilDate.weekday));
      final reading = taksa.asData?.value;
      line = (reading != null && reading.hasReading)
          ? reading.readings.first.summaryTh
          : _standingTh(birth!);
    } else {
      line = 'แตะเพื่อบอกวันเดือนปีเกิด แล้วดูว่าตรงกับวันทางจันทรคติวันใด';
    }

    return Text(line,
        style: textTheme.bodyMedium!
            .copyWith(color: NimitColors.onDarkSoft, height: 1.55));
  }

  /// What can be said truthfully before any ตำรา is published.
  String _standingTh(ThaiLunarBirth birth) {
    final today = DateTime.now();
    if (isWanPhra(DateTime(today.year, today.month, today.day))) {
      return 'วันนี้เป็นวันพระ · ท่านเกิด${birth.weekdayTh} ปี${birth.zodiacYearTh}';
    }
    return 'ท่านเกิด${birth.weekdayTh} ปี${birth.zodiacYearTh} '
        '${birth.lunarDateArchaicTh}';
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.isSet});

  final bool isSet;

  @override
  Widget build(BuildContext context) {
    // "ข้อมูลเกิดครบแล้ว" is back, and this time it is true: it renders only
    // when a date is actually stored, and the delete control below makes the
    // claim falsifiable in one tap.
    final label = isSet ? 'ข้อมูลเกิดครบแล้ว' : 'แตะเพื่อบอกวันเกิด';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: NimitColors.gold,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSet ? Icons.check_circle_outline : Icons.edit_calendar_outlined,
              size: 17, color: NimitColors.aubergineDeep),
          const SizedBox(width: 7),
          Text(label,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: NimitColors.aubergineDeep,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

/// วัน / เดือน / ปี พ.ศ. in a bottom sheet.
///
/// A modal rather than three permanent dropdowns: the birth date is set once
/// and then rarely touched, so leaving the form open forever gave the screen
/// the character of a data-entry job rather than something you consult.
class _BirthDateSheet extends StatefulWidget {
  const _BirthDateSheet({required this.initial});

  final DateTime? initial;

  @override
  State<_BirthDateSheet> createState() => _BirthDateSheetState();
}

class _BirthDateSheetState extends State<_BirthDateSheet> {
  static const _minCe = 1900;
  static const _maxCe = 2050;

  int? _day;
  int? _month;
  int? _yearBe;

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    if (d != null) {
      _day = d.day;
      _month = d.month;
      _yearBe = d.year + 543;
    }
  }

  int get _daysInMonth {
    final m = _month, y = _yearBe;
    if (m == null || y == null) return 31;
    return DateTime(y - 543, m + 1, 0).day;
  }

  bool get _complete => _day != null && _month != null && _yearBe != null;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 18, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: NimitColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('วันเดือนปีเกิด',
              style:
                  textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('ใช้คำนวณวันทางจันทรคติ เก็บไว้ในเครื่องนี้เท่านั้น',
              style: textTheme.bodySmall!.copyWith(color: NimitColors.inkSoft)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _Field<int>(
                  label: 'วัน',
                  value: _day,
                  items: [
                    for (var i = 1; i <= _daysInMonth; i++)
                      DropdownMenuItem(value: i, child: Text('$i'))
                  ],
                  onChanged: (v) => setState(() => _day = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: _Field<int>(
                  label: 'เดือน',
                  value: _month,
                  items: [
                    for (var i = 1; i <= 12; i++)
                      DropdownMenuItem(value: i, child: Text(thaiMonths[i - 1]))
                  ],
                  onChanged: (v) => setState(() {
                    _month = v;
                    // A day left over from a longer month is clamped, not
                    // rejected: the user changed the month, they did not ask
                    // to lose their day.
                    if (_day != null && _day! > _daysInMonth) {
                      _day = _daysInMonth;
                    }
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: _Field<int>(
                  label: 'ปี พ.ศ.',
                  value: _yearBe,
                  items: [
                    for (var y = _maxCe + 543; y >= _minCe + 543; y--)
                      DropdownMenuItem(value: y, child: Text('$y'))
                  ],
                  onChanged: (v) => setState(() => _yearBe = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              // Disabled until all three are set: a partial date cannot be
              // converted, and saving one would leave the screen in a state it
              // has no honest rendering for.
              onPressed: _complete
                  ? () => Navigator.of(context)
                      .pop(DateTime(_yearBe! - 543, _month!, _day!))
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: NimitColors.aubergine,
                foregroundColor: NimitColors.onDark,
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('บันทึก'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field<T> extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: textTheme.bodySmall!.copyWith(color: NimitColors.inkSoft)),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: NimitColors.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: NimitColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: NimitColors.border),
            ),
          ),
        ),
      ],
    );
  }
}

/// The ทักษา reading for the user's birth weekday, or an honest account of why
/// there is none. Only the weekday is sent; the birth date stays on the device.
class _TaksaSection extends ConsumerWidget {
  const _TaksaSection({required this.weekday});

  final int weekday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final taksa = ref.watch(taksaProvider(weekday));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('คำทำนายตามตำรา'),
        const SizedBox(height: 10),
        taksa.when(
          loading: () => const SectionCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          // A fetch failure is not the same as "no reading exists", and must
          // not be dressed up as one.
          error: (e, _) => const SectionCard(
            child: DisclaimerText('ยังโหลดคำทำนายไม่ได้ ลองใหม่อีกครั้ง'),
          ),
          data: (t) => t.hasReading
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final r in t.readings) ...[
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.summaryTh,
                                style: textTheme.titleSmall!.copyWith(
                                    fontWeight: FontWeight.w700, height: 1.5)),
                            const SizedBox(height: 10),
                            Text(r.bodyTh,
                                style:
                                    textTheme.bodyMedium!.copyWith(height: 1.6)),
                            const SizedBox(height: 12),
                            const Divider(color: NimitColors.border, height: 1),
                            const SizedBox(height: 10),
                            // Assembled in the model, so a reading cannot reach
                            // the screen without its source.
                            Text('ที่มา: ${r.sourceTh}',
                                style: textTheme.bodySmall!.copyWith(
                                    color: NimitColors.inkSoft, height: 1.45)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                )
              : SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ยังไม่มีตำราในคลังที่ทำนายจากวันเกิด',
                          style: textTheme.titleSmall!
                              .copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(
                          'วันทางจันทรคติข้างบนคำนวณได้จริง ตรวจสอบกับปฏิทินได้ '
                          'ส่วนคำทำนายต้องมีตำราที่อ้างอิงได้ก่อน นิมิตจะไม่แต่งขึ้นเอง',
                          style: textTheme.bodyMedium!.copyWith(height: 1.6)),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// The computed keys, demoted below the reading — reference, not headline.
class _BirthFacts extends StatelessWidget {
  const _BirthFacts({required this.birth});

  final ThaiLunarBirth birth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('คำนวณจากวันเกิดของท่าน',
            caption: 'เป็นการเทียบปฏิทิน ไม่ใช่คำทำนาย'),
        const SizedBox(height: 10),
        _FactRow(label: 'วันเกิด', value: birth.weekdayTh),
        _FactRow(label: 'วันทางจันทรคติ', value: birth.lunarDateArchaicTh),
        _FactRow(
          label: 'ปีนักษัตร',
          value: 'ปี${birth.zodiacYearTh}',
          note: birth.zodiacIsBoundarySensitive ? birth.zodiacNoteTh : null,
        ),
        _FactRow(label: 'ชนิดของปี', value: birth.yearTypeTh),
        if (birth.isIntercalaryMonth ||
            birth.monthOccurrence == ThaiLunarMonthOccurrence.firstEighth) ...[
          const SizedBox(height: 2),
          SectionCard(
            color: NimitColors.pastelBlue,
            child: Text(birth.intercalationNoteTh,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(color: NimitColors.ink, height: 1.5)),
          ),
        ],
      ],
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.label, required this.value, this.note});

  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SectionCard(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(label,
                      style: textTheme.bodyMedium!
                          .copyWith(color: NimitColors.inkSoft)),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(value,
                      textAlign: TextAlign.end,
                      style: textTheme.titleSmall!
                          .copyWith(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            if (note != null) ...[
              const SizedBox(height: 6),
              Text(note!,
                  style: textTheme.bodySmall!
                      .copyWith(color: NimitColors.inkSoft, height: 1.45)),
            ],
          ],
        ),
      ),
    );
  }
}

/// One quiet line, not a wall of warnings.
///
/// The previous version was a four-line checklist in a dark card at the top of
/// the screen, which made a page about ดวง open like a consent form. The facts
/// have not changed — birth date only, on this device, deletable — but they
/// belong in a footnote, next to the control that acts on them.
class _PrivacyNote extends ConsumerWidget {
  const _PrivacyNote({required this.canDelete});

  final bool canDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_outline, size: 15, color: NimitColors.inkSoft),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
              'เก็บวันเดือนปีเกิดไว้ในเครื่องนี้เท่านั้น ไม่ส่งออกจากเครื่อง',
              style: textTheme.bodySmall!
                  .copyWith(color: NimitColors.inkSoft, height: 1.45)),
        ),
        if (canDelete) ...[
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => ref.read(birthProfileProvider.notifier).clear(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 36),
              foregroundColor: NimitColors.inkSoft,
            ),
            child: const Text('ลบ'),
          ),
        ],
      ],
    );
  }
}

class _SourceFooter extends StatelessWidget {
  const _SourceFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DisclaimerText(
            'นิมิตเป็นแอปความเชื่อและวัฒนธรรม ไม่ใช่คำแนะนำทางการเงิน '
            'การลงทุน หรือทางการแพทย์'),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => context.push('/sources'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 44),
              foregroundColor: NimitColors.ink,
            ),
            child: const Text('ดูที่มาของตำราทั้งหมด'),
          ),
        ),
      ],
    );
  }
}
