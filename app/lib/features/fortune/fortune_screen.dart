import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/calendar/thai_lunar_birth.dart';
import '../../core/theme/nimit_theme.dart';
import '../../core/utils/thai_date.dart';
import '../../core/widgets/section.dart';
import '../../data/models/fortune.dart';
import '../../data/providers.dart';

/// ดวงของฉัน — a birth date, held on this device, converted to the Thai lunar
/// calendar.
///
/// WHAT THIS SCREEN USED TO DO. It displayed a ลัคนา, a gold badge claiming the
/// user's birth data was on file, four "เลขประจำดวง" and a line of financial
/// advice — every one of them a constant in a mock, none backed by anything the
/// user had entered. All of it is gone.
///
/// WHAT IT DOES NOW. It asks for a birth date and shows the Thai lunar date it
/// falls on: ขึ้น/แรม, ค่ำ, เดือนอ้าย … เดือนสิบสอง, and whether the year was
/// อธิกมาส or อธิกวาร. That is a calendar conversion, not a prediction — it is
/// as checkable as a currency conversion, and the arithmetic is held to
/// published sources in test/thai_lunar_package_conformance_test.dart.
///
/// WHAT IT STILL WILL NOT DO. There is no reading, because no ตำรา in the
/// library keys on เดือนเกิด yet. The screen says so rather than filling the
/// space, which was the entire point of removing the old one.
///
/// The date is asked for in พ.ศ. with Thai month names, not through the stock
/// date picker: this audience knows its birth year as ๒๕๓๖, and a wheel
/// offering 1993 is a small daily insult to people the app is supposed to be
/// for.
class FortuneScreen extends ConsumerWidget {
  const FortuneScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final profile = ref.watch(birthProfileProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text('ดวงของฉัน',
            style:
                textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('บอกวันเดือนปีเกิด แล้วดูว่าตรงกับเดือนไทยเดือนไหน',
            style: textTheme.bodySmall!.copyWith(color: NimitColors.inkSoft)),
        const SizedBox(height: 16),
        const _PrivacyCard(),
        const SizedBox(height: 20),
        profile.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          ),
          // Storage failed rather than being empty. Say so instead of showing
          // an unset picker, which would look like the saved date had been
          // silently thrown away.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (profile.needsUpgrade) ...[
          SectionCard(
            color: NimitColors.pastelCream,
            child: DisclaimerText(
                'เดิมคุณบอกไว้แค่เดือน ${thaiMonths[profile.legacyMonth! - 1]} '
                'ตอนนี้ขอวันและปีเกิดเพิ่ม เพราะเดือนไทยตามตำราคำนวณจากวันเดือนปีพร้อมกัน'),
          ),
          const SizedBox(height: 16),
        ],
        SectionHeader(
          'วันเดือนปีเกิด',
          caption: profile.isComplete ? 'แก้ไขได้ตลอด' : 'เลือกให้ครบทั้งสามช่อง',
        ),
        const SizedBox(height: 12),
        _BirthDatePicker(
          initial: profile.date,
          onPicked: (d) => ref.read(birthProfileProvider.notifier).setDate(d),
        ),
        const SizedBox(height: 20),
        if (profile.isComplete) ...[
          _LunarResult(date: profile.date!),
          const SizedBox(height: 14),
          Center(
            child: TextButton.icon(
              onPressed: () => ref.read(birthProfileProvider.notifier).clear(),
              icon: const Icon(Icons.delete_outline, size: 20),
              label: const Text('ลบวันเกิดออกจากเครื่อง'),
              style: TextButton.styleFrom(
                foregroundColor: NimitColors.inkSoft,
                minimumSize: const Size(0, 48),
              ),
            ),
          ),
        ] else if (!profile.needsUpgrade)
          const SectionCard(
            color: NimitColors.pastelCream,
            child: DisclaimerText(
                'ยังไม่ได้บอกวันเกิด แอปใช้งานส่วนอื่นได้ตามปกติ '
                'จะบอกหรือไม่บอกก็ได้'),
          ),
        const SizedBox(height: 22),
        const _SourceFooter(),
      ],
    );
  }
}

/// What is stored, stated before anything is asked for.
class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline, color: NimitColors.gold, size: 20),
              const SizedBox(width: 8),
              Text('เก็บไว้ในเครื่องนี้เท่านั้น',
                  style: textTheme.titleSmall!.copyWith(
                      color: NimitColors.onDark, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          // Names the field exactly. A date of birth is more identifying than
          // a month, so the card has to say "วันเดือนปีเกิด" and not soften it.
          const _PrivacyLine(yes: true, text: 'เก็บ: วันเดือนปีเกิด'),
          const _PrivacyLine(
              yes: false, text: 'ไม่เก็บ: เวลาเกิด สถานที่เกิด ชื่อ เลขบัตร'),
          const _PrivacyLine(
              yes: false, text: 'ไม่ส่งออกจากเครื่อง ไม่มีบัญชีผู้ใช้'),
          const _PrivacyLine(yes: true, text: 'ลบได้ตลอดเวลา ลบแล้วหายทันที'),
        ],
      ),
    );
  }
}

class _PrivacyLine extends StatelessWidget {
  const _PrivacyLine({required this.yes, required this.text});

  final bool yes;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon as well as colour: the distinction has to survive a sun-washed
          // screen and colour-blind eyes.
          Icon(yes ? Icons.check : Icons.close,
              size: 17, color: yes ? NimitColors.gold : NimitColors.onDarkSoft),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(color: NimitColors.onDark, height: 1.45)),
          ),
        ],
      ),
    );
  }
}

/// วัน / เดือน / ปี พ.ศ. as three fields.
///
/// Not the stock date picker, for two reasons: it offers Gregorian years to an
/// audience that thinks in พ.ศ., and its wheel is a poor target for the older
/// hands this app is built for. Three dropdowns are boring and legible, and
/// nothing is saved until all three are set.
class _BirthDatePicker extends StatefulWidget {
  const _BirthDatePicker({required this.initial, required this.onPicked});

  final DateTime? initial;
  final ValueChanged<DateTime> onPicked;

  @override
  State<_BirthDatePicker> createState() => _BirthDatePickerState();
}

class _BirthDatePickerState extends State<_BirthDatePicker> {
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

  /// Days in the currently chosen month, so 31 กุมภาพันธ์ cannot be picked.
  int get _daysInMonth {
    final m = _month, y = _yearBe;
    if (m == null || y == null) return 31;
    return DateTime(y - 543, m + 1, 0).day;
  }

  void _emit() {
    final d = _day, m = _month, y = _yearBe;
    if (d == null || m == null || y == null) return;
    // A day left over from a longer month is clamped rather than rejected —
    // the user changed the month, they did not ask to lose their day.
    final clamped = d > _daysInMonth ? _daysInMonth : d;
    if (clamped != d) setState(() => _day = clamped);
    widget.onPicked(DateTime(y - 543, m, clamped));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
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
            onChanged: (v) => setState(() {
              _day = v;
              _emit();
            }),
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
              _emit();
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
            onChanged: (v) => setState(() {
              _yearBe = v;
              _emit();
            }),
          ),
        ),
      ],
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

/// The converted lunar date. A fact, not a forecast.
class _LunarResult extends StatelessWidget {
  const _LunarResult({required this.date});

  final DateTime date;

  static const _service = ThaiLunarBirthService();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final ThaiLunarBirth birth;
    try {
      birth = _service.convert(date);
    } on RangeError {
      // The picker cannot currently produce an out-of-range date, but the
      // conversion refuses rather than guesses and the screen has to honour
      // that instead of rendering a wrong month.
      return const SectionCard(
        child: DisclaimerText('ปีเกิดนี้อยู่นอกช่วงที่แอปคำนวณได้อย่างมั่นใจ'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ตรงกับวันทางจันทรคติ',
                  style: textTheme.labelMedium!
                      .copyWith(color: NimitColors.gold)),
              const SizedBox(height: 8),
              // The headline, and only the headline. The year type lives in
              // the fact list below with the other lookup keys — printing it
              // in both places is the kind of duplication that drifts apart
              // the first time one of them is edited.
              Text(birth.lunarDateTh,
                  style: textTheme.headlineSmall!.copyWith(
                      color: NimitColors.onDark, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          color: NimitColors.pastelBlue,
          child: Text(birth.intercalationNoteTh,
              style: textTheme.bodyMedium!
                  .copyWith(color: NimitColors.ink, height: 1.55)),
        ),
        const SizedBox(height: 18),

        // The three keys a ตำรา reading is looked up by. All computed, none
        // invented — วันเกิด is arithmetic, เดือน comes from the conversion
        // above, and ปีนักษัตร carries its own reckoning note because the
        // conventions genuinely disagree for early-year births.
        const SectionHeader('สิ่งที่คำนวณได้จากวันเกิด',
            caption: 'เป็นการเทียบปฏิทิน ไม่ใช่คำทำนาย'),
        const SizedBox(height: 10),
        _FactRow(label: 'วันเกิด', value: birth.weekdayTh),
        _FactRow(label: 'เดือนทางจันทรคติ', value: birth.monthNameTh),
        _FactRow(
          label: 'ปีนักษัตร',
          value: 'ปี${birth.zodiacYearTh}',
          note: birth.zodiacIsBoundarySensitive ? birth.zodiacNoteTh : null,
        ),
        _FactRow(label: 'ชนิดของปี', value: birth.yearTypeTh),

        const SizedBox(height: 18),
        _TaksaSection(weekday: birth.effectiveCivilDate.weekday),
      ],
    );
  }
}

/// The ทักษา reading for the user’s birth weekday, or an honest account of
/// why there is none.
///
/// Only the weekday is sent. The birth date stays on the device, the same way
/// a lottery ticket number never travels.
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
                                style: textTheme.bodyMedium!
                                    .copyWith(height: 1.6)),
                            const SizedBox(height: 12),
                            const Divider(
                                color: NimitColors.border, height: 1),
                            const SizedBox(height: 10),
                            // Every reading carries its source. The citation is
                            // assembled in the model, so a reading cannot reach
                            // the screen without one.
                            Text('ที่มา: ${r.sourceTh}',
                                style: textTheme.bodySmall!.copyWith(
                                    color: NimitColors.inkSoft, height: 1.45)),
                            if (r.contextNoteTh.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(r.contextNoteTh,
                                  style: textTheme.bodySmall!.copyWith(
                                      color: NimitColors.inkSoft,
                                      height: 1.45)),
                            ],
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
                      Text('ยังไม่มีตำราในคลังที่ทำนายจากวันเดือนปีเกิด',
                          style: textTheme.titleSmall!
                              .copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(
                          'ข้างบนคือสิ่งที่คำนวณได้จริง ตรวจสอบกับปฏิทินได้ทุกบรรทัด '
                          'ส่วนคำทำนายต้องมีตำราที่อ้างอิงได้ก่อน นิมิตจะไม่แต่งขึ้นเอง '
                          'เมื่อได้ตำรามาแล้ว คำทำนายจะขึ้นตรงนี้พร้อมบอกว่ามาจากเล่มไหน หน้าไหน',
                          style: textTheme.bodyMedium!.copyWith(height: 1.6)),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// One computed fact: label, value, and an optional caveat underneath.
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
        const SizedBox(height: 10),
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
