import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nimit_theme.dart';
import '../../core/utils/thai_date.dart';
import '../../core/widgets/section.dart';
import '../../data/models/fortune.dart';
import '../../data/providers.dart';

/// ดวงของฉัน — birth month, held on this device, and nothing else.
///
/// WHAT THIS REPLACED. The previous screen displayed a ลัคนา ("ลัคนาเมษ"), a
/// gold badge reading "ข้อมูลเกิดครบแล้ว", four "เลขประจำดวงเดือนนี้", and a
/// line of financial advice. Every one of those was a constant in
/// `MockFortuneRepository`. The app had never asked for a birth date, let alone
/// the time and place a ลัคนา needs, so the chart was asserted rather than
/// computed and the badge told users their birth data was on file when no such
/// data existed. The numbers were the third invented-numbers surface in the
/// product, after เลขนิมิตวันนี้ and the trends mentions.
///
/// The scope is now a month, because a month is what the app can hold honestly:
/// not identifying under PDPA, never transmitted, and cheap for App Store
/// review to verify — there is no network call on this screen at all.
///
/// The screen deliberately renders an empty reading state rather than filling
/// the space. No ตำรา in the library keys on เดือนเกิด yet, and the whole point
/// of removing the old screen was to stop showing readings that nothing backs.
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
        Text('บอกแค่เดือนเกิดพอ ข้อมูลอยู่ในเครื่องของคุณเท่านั้น',
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
          // an unset picker, which would look like the user's saved month had
          // been silently thrown away.
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
        SectionHeader(
          'เดือนเกิดของคุณ',
          caption: profile.isSet
              ? 'แตะเดือนอื่นเพื่อเปลี่ยน'
              : 'แตะเลือกเดือนที่คุณเกิด',
        ),
        const SizedBox(height: 12),
        _MonthGrid(
          selected: profile.month,
          onSelect: (m) => ref.read(birthProfileProvider.notifier).setMonth(m),
        ),
        const SizedBox(height: 20),
        if (profile.isSet) ...[
          _ReadingState(month: profile.month!),
          const SizedBox(height: 14),
          Center(
            child: TextButton.icon(
              onPressed: () => ref.read(birthProfileProvider.notifier).clear(),
              icon: const Icon(Icons.delete_outline, size: 20),
              label: const Text('ลบเดือนเกิดออกจากเครื่อง'),
              style: TextButton.styleFrom(
                foregroundColor: NimitColors.inkSoft,
                // 48 dp of height: this audience skews older and often taps
                // outdoors, and a control that needs a second try is worse
                // than one that is easy to hit.
                minimumSize: const Size(0, 48),
              ),
            ),
          ),
        ] else
          const SectionCard(
            color: NimitColors.pastelCream,
            child: DisclaimerText(
                'ยังไม่ได้เลือกเดือนเกิด แอปใช้งานส่วนอื่นได้ตามปกติ '
                'จะเลือกหรือไม่เลือกก็ได้'),
          ),
        const SizedBox(height: 22),
        const _SourceFooter(),
      ],
    );
  }
}

/// What is stored, stated before anything is asked for.
///
/// This sits above the picker on purpose. A privacy note underneath the input
/// is read after the decision has already been made.
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
          const _PrivacyLine(yes: true, text: 'เก็บ: เดือนเกิด อย่างเดียว'),
          const _PrivacyLine(
              yes: false, text: 'ไม่เก็บ: วันที่เกิด เวลาเกิด สถานที่เกิด ชื่อ'),
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
          // Icon as well as colour: the ✓/✕ distinction has to survive a
          // sun-washed screen and colour-blind eyes.
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

/// Twelve months, three to a row.
///
/// A dropdown would be tidier and worse: a 12-item picker behind a tap is a
/// hidden control for a user who is not sure the screen wants anything from
/// them, and each cell here clears the 48 dp tap target on its own.
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.selected, required this.onSelect});

  final int? selected;
  final ValueChanged<int> onSelect;

  static const _columns = 3;
  static const _gap = 10.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = (constraints.maxWidth - _gap * (_columns - 1)) / _columns;
        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (var m = 1; m <= 12; m++)
              SizedBox(
                width: cell,
                child: _MonthCell(
                  label: thaiMonths[m - 1],
                  selected: m == selected,
                  onTap: () => onSelect(m),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? NimitColors.gold : NimitColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 52,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? NimitColors.goldDeep : NimitColors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: FittedBox(
              // พฤศจิกายน and กุมภาพันธ์ are the long ones. Scaling down keeps
              // every month fully readable at the same cell width; an ellipsis
              // would leave two months truncated on a 360 px phone.
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: textTheme.bodyLarge!.copyWith(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? NimitColors.aubergineDeep : NimitColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The honest empty state.
///
/// Nothing in the library keys on เดือนเกิด yet, so this says so in plain Thai
/// instead of generating a reading. It also explains the one thing a user will
/// expect and not get — ราศี — because a month alone cannot give it: Thai ราศี
/// boundaries fall in the middle of a Gregorian month (someone born 5 เมษายน is
/// มีน, someone born 20 เมษายน is เมษ), so deriving it here would be wrong for
/// roughly half of every month's users.
class _ReadingState extends StatelessWidget {
  const _ReadingState({required this.month});

  final int month;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          color: NimitColors.pastelLavender,
          child: Row(
            children: [
              const Icon(Icons.event_outlined, color: NimitColors.ink),
              const SizedBox(width: 12),
              Expanded(
                child: Text('เดือนเกิด: ${thaiMonths[month - 1]}',
                    style: textTheme.titleMedium!
                        .copyWith(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const SectionHeader('คำทำนายตามเดือนเกิด'),
        const SizedBox(height: 10),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ยังไม่มีในคลังตำรา',
                  style: textTheme.titleSmall!
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                  'ตำราที่นิมิตเก็บไว้ตอนนี้ทำนายจาก "ฝัน" กับ "เลข" '
                  'ยังไม่มีเล่มไหนที่ทำนายจากเดือนเกิดโดยตรง '
                  'เมื่อไหร่ที่ได้ตำราที่อ้างอิงได้ หน้านี้จะขึ้นให้อ่านทันที',
                  style: textTheme.bodyMedium!.copyWith(height: 1.6)),
              const SizedBox(height: 12),
              const Divider(color: NimitColors.border, height: 1),
              const SizedBox(height: 12),
              Text('ทำไมไม่บอกราศี',
                  style: textTheme.titleSmall!
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                  'ราศีไม่ได้แบ่งตามเดือนแบบตรง ๆ รอยต่อของราศีอยู่กลางเดือน '
                  'คนเกิดต้นเดือนเมษายนกับปลายเดือนเมษายนอยู่คนละราศีกัน '
                  'ถ้าเดาจากเดือนอย่างเดียวจะผิดประมาณครึ่งหนึ่ง นิมิตเลยไม่เดา',
                  style: textTheme.bodyMedium!.copyWith(height: 1.6)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          color: NimitColors.pastelBlue,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_stories_outlined,
                  color: NimitColors.ink, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                    'ระหว่างนี้ ลองบันทึกความฝันไว้ที่แท็บ "ฝัน" '
                    'คำทำนายทุกข้อในแอปบอกได้ว่ามาจากตำราเล่มไหน หน้าไหน',
                    style: textTheme.bodyMedium!
                        .copyWith(color: NimitColors.ink, height: 1.55)),
              ),
            ],
          ),
        ),
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
