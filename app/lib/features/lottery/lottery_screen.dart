import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nimit_theme.dart';
import '../../core/utils/thai_date.dart';
import '../../core/widgets/section.dart';
import '../../data/lottery_checker.dart';
import '../../data/models/lottery.dart';
import '../../data/providers.dart';
import 'lottery_widgets.dart';

/// ตรวจหวยรัฐบาล — the draw-day screen.
///
/// Composition follows what a repeat player actually needs in the ten seconds
/// after results land, in order: what came out, did I win, how much. Statistics,
/// history and the full prize table live on sub-routes so they cannot push the
/// answer below the fold.
class LotteryScreen extends ConsumerStatefulWidget {
  const LotteryScreen({super.key});

  @override
  ConsumerState<LotteryScreen> createState() => _LotteryScreenState();
}

class _LotteryScreenState extends ConsumerState<LotteryScreen> {
  final _numberController = TextEditingController();
  int _quantity = 1;

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  String? _validNumber() {
    final number = _numberController.text.trim();
    if (number.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรอกเลขให้ครบ 6 หลักก่อน')),
      );
      return null;
    }
    return number;
  }

  /// Check WITHOUT saving.
  ///
  /// Previously one button did both, so checking a friend's ticket silently
  /// added it to the user's own list forever. Checking and keeping are
  /// different intentions and now have different buttons.
  Future<void> _checkOnly() async {
    final number = _validNumber();
    if (number == null) return;

    // The remote repository throws by policy rather than inventing a draw, and
    // this screen had no handler at all — a dropped connection surfaced as an
    // unhandled exception on the one screen that talks about money.
    try {
      final draw = await ref.read(latestDrawProvider.future);
      if (!mounted) return;
      final outcome = checkTicket(
          draw, SavedTicket(number: number, savedAt: DateTime.now()));
      await showDialog<void>(
        context: context,
        builder: (context) => _ResultDialog(draw: draw, outcome: outcome),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยังโหลดผลรางวัลไม่ได้ ลองใหม่อีกครั้ง')),
      );
    }
  }

  Future<void> _saveNumber() async {
    final number = _validNumber();
    if (number == null) return;
    await ref
        .read(savedTicketsProvider.notifier)
        .save(number, quantity: _quantity);
    _numberController.clear();
    if (!mounted) return;
    setState(() => _quantity = 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('บันทึกเลข $number ไว้แล้ว '
              '${_quantity > 1 ? '($_quantity ใบ)' : ''}'.trim())),
    );
  }

  Future<void> _editBudget() async {
    final budget = await ref.read(budgetProvider.future);
    if (!mounted) return;
    final limitController =
        TextEditingController(text: budget.limit.toString());
    final spendController = TextEditingController();
    ({int? limit, int? spend})? result;
    try {
      result = await showDialog<({int? limit, int? spend})>(
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
                decoration:
                    const InputDecoration(labelText: 'งบต่อเดือน (บาท)'),
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
    } finally {
      // Created per invocation, so they must die per invocation — otherwise
      // every dialog open leaks two ChangeNotifiers.
      limitController.dispose();
      spendController.dispose();
    }
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
    final info = ref.watch(currentDrawProvider);
    final latest = ref.watch(latestDrawProvider);
    final tickets = ref.watch(savedTicketsProvider);
    final outcome = ref.watch(checkOutcomeProvider);
    final budget = ref.watch(budgetProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text('ตรวจหวยรัฐบาล',
            style:
                textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),

        // 1 — the draw itself.
        latest.when(
          loading: () => const _BannerSkeleton(),
          error: (e, _) => _PendingBanner(info: info),
          data: (draw) => _ResultBanner(draw: draw),
        ),
        const SizedBox(height: 14),

        // 2 — did I win. Rendered above everything else, and only when the
        // draw is complete enough to be trusted.
        outcome.maybeWhen(
          data: (o) => o.verdictAvailable && o.hasWin
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _WinCard(outcome: o),
                )
              : const SizedBox.shrink(),
          orElse: () => const SizedBox.shrink(),
        ),

        // 3 — the hope figure, on an unannounced งวด.
        tickets.maybeWhen(
          data: (list) => _HopeLine(tickets: list, latest: latest),
          orElse: () => const SizedBox.shrink(),
        ),

        // Numbers carried over from dreams. Distinct from saved tickets, and
        // never shown with a baht figure — see _WatchedSection.
        ref.watch(watchedNumbersProvider).maybeWhen(
              data: (list) => list.isEmpty
                  ? const SizedBox.shrink()
                  : _WatchedSection(watched: list, latest: latest),
              orElse: () => const SizedBox.shrink(),
            ),

        const SectionHeader('ตรวจเลขของคุณ'),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: _numberController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.w800, letterSpacing: 4),
                decoration: const InputDecoration(
                  hintText: 'เลข 6 หลัก',
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(width: 12),
            _QuantityStepper(
              value: _quantity,
              onChanged: (v) => setState(() => _quantity = v),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: _checkOnly,
                child: const Text('ตรวจรางวัล'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  side: const BorderSide(color: NimitColors.border),
                  foregroundColor: NimitColors.ink,
                ),
                onPressed: _saveNumber,
                child: const Text('บันทึกเลขนี้'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // 4 — saved numbers, with real computed status.
        outcome.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => tickets.maybeWhen(
            data: (list) => _SavedListBasic(tickets: list, ref: ref),
            orElse: () => const SizedBox.shrink(),
          ),
          data: (o) => o.tickets.isEmpty
              ? const _EmptyTickets()
              : _SavedList(outcome: o, ref: ref),
        ),
        const SizedBox(height: 18),

        // 5 — the other surfaces, kept off this screen.
        _NavRow(
          icon: Icons.bar_chart_rounded,
          titleTh: 'สถิติเลขย้อนหลัง',
          captionTh: 'เลขท้าย 2 ตัว ออกบ่อยแค่ไหนในงวดที่ผ่านมา',
          onTap: () => context.go('/lottery/stats'),
        ),
        _NavRow(
          icon: Icons.person_outline,
          titleTh: 'สถิติของฉัน',
          captionTh: 'เลขที่บันทึกไว้ เคยออกไหม ใช้ไปเท่าไร',
          onTap: () => context.go('/lottery/me'),
        ),
        _NavRow(
          icon: Icons.history,
          titleTh: 'ผลย้อนหลัง',
          captionTh: 'ดูผลรางวัลครบทุกรางวัลของงวดก่อน ๆ',
          onTap: () => context.go('/lottery/history'),
        ),
        _NavRow(
          icon: Icons.emoji_events_outlined,
          titleTh: 'เงินรางวัลแต่ละรางวัล',
          captionTh: 'รางวัลที่ 1 ถึงเลขท้าย 2 ตัว ได้เท่าไร',
          onTap: () => context.go('/lottery/prizes'),
        ),
        const SizedBox(height: 12),

        // 6 — responsible use. Stays on the main screen deliberately: on a งวด
        // that has not been drawn yet it is the most useful thing here.
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
                Text(
                    'ใช้แล้ว ${formatBaht(b.spent)} จาก ${formatBaht(b.limit)}',
                    style: textTheme.bodySmall!
                        .copyWith(color: NimitColors.successInk)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: b.ratio,
                    minHeight: 10,
                    backgroundColor: NimitColors.surface,
                    valueColor:
                        const AlwaysStoppedAnimation(NimitColors.successInk),
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

// ---------------------------------------------------------------------------
// Banner
// ---------------------------------------------------------------------------

class _BannerSkeleton extends StatelessWidget {
  const _BannerSkeleton();

  @override
  Widget build(BuildContext context) => const DarkCard(
        child: SizedBox(
          height: 96,
          child: Center(
            child: CircularProgressIndicator(color: NimitColors.gold),
          ),
        ),
      );
}

/// Shown when no announced result is reachable.
///
/// The wording matters: it says the app does not have the result, never that
/// the user did not win. Those are different statements and only one of them is
/// something we know.
class _PendingBanner extends StatelessWidget {
  const _PendingBanner({required this.info});

  final AsyncValue<DrawInfo> info;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            info.maybeWhen(
              data: (i) => 'งวดวันที่ ${formatThaiDate(i.drawDate)}'
                  '${i.estimated ? ' (โดยประมาณ)' : ''}',
              orElse: () => 'งวดถัดไป',
            ),
            style: textTheme.labelMedium!.copyWith(color: NimitColors.gold),
          ),
          const SizedBox(height: 8),
          Text('ยังไม่มีผลรางวัลในแอป',
              style: textTheme.titleMedium!.copyWith(
                  color: NimitColors.onDark, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const DisclaimerText(
            'ถ้าประกาศผลแล้วแต่ยังไม่ขึ้นที่นี่ ให้ลองใหม่อีกครั้ง '
            'และตรวจกับประกาศทางการเสมอ',
            color: NimitColors.onDarkSoft,
          ),
        ],
      ),
    );
  }
}

/// The two numbers this audience memorises, at the largest size on the screen.
class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.draw});

  final DrawResult draw;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final first = draw.tier('first');
    final last2 = draw.tier('last2');
    final front3 = draw.tier('front3');
    final last3 = draw.tier('last3');

    return DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(draw.periodLabelTh,
                    style: textTheme.labelMedium!
                        .copyWith(color: NimitColors.gold)),
              ),
              if (draw.status == DrawStatus.partial)
                const TicketStatePill(
                    state: TicketState.pending, labelTh: 'ผลยังไม่ครบ'),
            ],
          ),
          const SizedBox(height: 14),
          Text('รางวัลที่ 1',
              style: textTheme.bodySmall!
                  .copyWith(color: NimitColors.onDarkSoft)),
          const SizedBox(height: 2),
          BigNumber(first?.numbers.firstOrNull ?? '——————'),
          const SizedBox(height: 14),
          const Divider(
              height: 1, thickness: 1, color: Color(0x22F8F2E7)),
          const SizedBox(height: 6),
          PrizeRow(
            labelTh: 'เลขท้าย 2 ตัว',
            numbers: last2?.numbers ?? const [],
            onDark: true,
            emphasis: true,
          ),
          PrizeRow(
            labelTh: 'เลขหน้า 3 ตัว',
            numbers: front3?.numbers ?? const [],
            onDark: true,
          ),
          PrizeRow(
            labelTh: 'เลขท้าย 3 ตัว',
            numbers: last3?.numbers ?? const [],
            onDark: true,
          ),
          const SizedBox(height: 10),
          // Attribution renders from the source row the data hangs off, so the
          // credit shown can never drift from the source actually used.
          DisclaimerText('ที่มา: ${draw.sourceCustodianTh}',
              color: NimitColors.onDarkSoft),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Win card
// ---------------------------------------------------------------------------

class _WinCard extends StatelessWidget {
  const _WinCard({required this.outcome});

  final CheckOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final winners = outcome.tickets.where((t) => t.isWin).toList();

    return SectionCard(
      color: NimitColors.successBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.celebration,
                  color: NimitColors.successInk, size: 22),
              const SizedBox(width: 8),
              Text('ถูกรางวัล!',
                  style: textTheme.titleMedium!.copyWith(
                      color: NimitColors.successInk,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatBaht(outcome.totalThb),
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: NimitColors.successInk,
              height: 1.1,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 10),
          for (final t in winners)
            for (final h in t.hits)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${t.number} · ${h.nameTh} · ${formatBaht(h.amountThb)}'
                  '${t.quantity > 1 ? ' × ${t.quantity} ใบ = ${formatBaht(h.amountThb * t.quantity)}' : ''}',
                  style: textTheme.bodyMedium!
                      .copyWith(color: NimitColors.successInk),
                ),
              ),
          const Divider(height: 22, color: NimitColors.successInk, thickness: 0.2),
          Text('ขึ้นเงินรางวัล',
              style: textTheme.titleSmall!.copyWith(
                  color: NimitColors.successInk, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          // The stamp duty appears HERE, as guidance, and never inside a
          // computed figure. Prize amounts are shown gross by product decision;
          // saying nothing at all about the deduction would leave a winner
          // surprised at the counter.
          ...[
            'ต้องมีสลากตัวจริงและบัตรประชาชน',
            'รางวัลไม่เกิน ฿20,000 ขึ้นเงินได้ที่ตัวแทนจำหน่าย รางวัลใหญ่ที่สำนักงานสลากฯ',
            'มีอากรแสตมป์หัก 0.5% ตอนขึ้นเงิน ยอดด้านบนเป็นยอดเต็มก่อนหัก',
            'ตรวจกับประกาศทางการอีกครั้งเสมอ',
          ].map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('• $line',
                    style: textTheme.bodySmall!
                        .copyWith(color: NimitColors.successInk)),
              )),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The hope line
// ---------------------------------------------------------------------------

/// "ถือไว้ 5 ใบ · ถ้าถูกรางวัลที่ 1 ได้ ฿30,000,000"
///
/// Computed from tickets the user ALREADY HOLDS. Deliberately not a
/// "ถ้าซื้อกี่ใบ" slider — a control that escalates a payout as you add
/// imaginary tickets is an inducement to spend, and it would sit inches above
/// the responsible-use budget card.
///
/// Shown only while the งวด is undecided. Once results are in, the real
/// outcome is the story and a hypothetical would be noise.
class _HopeLine extends ConsumerWidget {
  const _HopeLine({required this.tickets, required this.latest});

  final List<SavedTicket> tickets;
  final AsyncValue<DrawResult> latest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tickets.isEmpty) return const SizedBox.shrink();

    final draw = latest.value;
    if (draw == null) return const SizedBox.shrink();

    final outcome = ref.watch(checkOutcomeProvider).value;
    if (outcome != null && outcome.verdictAvailable) {
      return const SizedBox.shrink();
    }

    final held = tickets.fold<int>(0, (s, t) => s + t.quantity);
    final amount = hopeAmountThb(draw, tickets);
    if (amount <= 0) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SectionCard(
        color: NimitColors.pastelCream,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ถือไว้ $held ใบ · ถ้าถูกรางวัลที่ 1 งวดนี้',
                style: textTheme.bodyMedium!
                    .copyWith(color: NimitColors.ink, height: 1.3)),
            const SizedBox(height: 4),
            Text(
              formatBaht(amount),
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: NimitColors.aubergine,
                height: 1.1,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            const DisclaimerText('ยอดเต็มก่อนหักอากรแสตมป์ 0.5%'),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Saved numbers
// ---------------------------------------------------------------------------

class _EmptyTickets extends StatelessWidget {
  const _EmptyTickets();

  @override
  Widget build(BuildContext context) => const SectionCard(
        child: DisclaimerText(
          'ยังไม่ได้บันทึกเลขไว้ — พิมพ์เลขด้านบนแล้วกด "บันทึกเลขนี้" '
          'ระบบจะตรวจให้อัตโนมัติทุกงวด',
        ),
      );
}

class _SavedList extends StatelessWidget {
  const _SavedList({required this.outcome, required this.ref});

  final CheckOutcome outcome;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('เลขที่บันทึกไว้'),
        const SizedBox(height: 10),
        for (final t in outcome.tickets) ...[
          SectionCard(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.number,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 3,
                                color: NimitColors.ink,
                                fontFeatures: [FontFeature.tabularFigures()],
                              )),
                          if (t.quantity > 1)
                            Text('${t.quantity} ใบ',
                                style: textTheme.bodySmall!
                                    .copyWith(color: NimitColors.inkSoft)),
                        ],
                      ),
                    ),
                    TicketStatePill(
                      state: ticketStateOf(outcome, t),
                      labelTh: ticketLabelOf(outcome, t),
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
                // Show the arithmetic when a set is held, so the total is
                // checkable rather than something the app just asserts.
                if (t.isWin && t.quantity > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${formatBaht(t.unitAmountThb)} × ${t.quantity} ใบ '
                      '= ${formatBaht(t.totalAmountThb)}',
                      style: textTheme.bodyMedium!.copyWith(
                          color: NimitColors.successInk,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// Fallback when the draw could not be loaded: numbers are still listed and
/// still removable, every status simply reads "ยังไม่ประกาศ".
class _SavedListBasic extends StatelessWidget {
  const _SavedListBasic({required this.tickets, required this.ref});

  final List<SavedTicket> tickets;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) return const _EmptyTickets();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('เลขที่บันทึกไว้'),
        const SizedBox(height: 10),
        for (final t in tickets) ...[
          SectionCard(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(t.number,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                        color: NimitColors.ink,
                        fontFeatures: [FontFeature.tabularFigures()],
                      )),
                ),
                const TicketStatePill(
                    state: TicketState.pending, labelTh: 'ยังไม่ประกาศ'),
                IconButton(
                  tooltip: 'ลบ',
                  onPressed: () =>
                      ref.read(savedTicketsProvider.notifier).remove(t.number),
                  icon: const Icon(Icons.close,
                      size: 18, color: NimitColors.inkSoft),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Small pieces
// ---------------------------------------------------------------------------

/// ซื้อเป็นชุด: how many physical tickets bear this number.
class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NimitColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NimitColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'ลดจำนวนใบ',
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove, size: 18),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$value',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const Text('ใบ',
                  style: TextStyle(fontSize: 11, color: NimitColors.inkSoft)),
            ],
          ),
          IconButton(
            tooltip: 'เพิ่มจำนวนใบ',
            onPressed: value < 99 ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add, size: 18),
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.titleTh,
    required this.captionTh,
    required this.onTap,
  });

  final IconData icon;
  final String titleTh;
  final String captionTh;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SectionCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: NimitColors.aubergine),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titleTh,
                      style: textTheme.titleSmall!
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(captionTh,
                      style: textTheme.bodySmall!
                          .copyWith(color: NimitColors.inkSoft)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: NimitColors.inkSoft),
          ],
        ),
      ),
    );
  }
}

/// Result of a one-off check that was not saved.
class _ResultDialog extends StatelessWidget {
  const _ResultDialog({required this.draw, required this.outcome});

  final DrawResult draw;
  final TicketOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final canJudge = draw.verdictAvailable;

    return AlertDialog(
      title: Text(outcome.number,
          style: const TextStyle(
              fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 3)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(draw.periodLabelTh,
              style:
                  textTheme.bodySmall!.copyWith(color: NimitColors.inkSoft)),
          const SizedBox(height: 12),
          if (outcome.isWin) ...[
            Text('ถูกรางวัล',
                style: textTheme.titleMedium!.copyWith(
                    color: NimitColors.successInk,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(formatBaht(outcome.unitAmountThb),
                style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: NimitColors.successInk)),
            const SizedBox(height: 6),
            for (final h in outcome.hits)
              Text('• ${h.nameTh} · ${formatBaht(h.amountThb)}',
                  style: textTheme.bodySmall),
            const SizedBox(height: 8),
            const DisclaimerText('ยอดเต็มก่อนหักอากรแสตมป์ 0.5%'),
          ] else if (!canJudge) ...[
            Text(
                draw.status == DrawStatus.partial
                    ? 'งวดนี้ยังประกาศไม่ครบทุกรางวัล ยังบอกไม่ได้'
                    : 'ยังไม่มีผลรางวัลครบในแอป ยังบอกไม่ได้',
                style: textTheme.bodyMedium),
          ] else ...[
            Text('ไม่ถูกรางวัลงวดนี้', style: textTheme.titleMedium),
            const SizedBox(height: 6),
            const DisclaimerText('ตรวจกับประกาศทางการอีกครั้งเสมอ'),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ปิด'),
        ),
      ],
    );
  }
}

/// เลขที่ตามอยู่ — short numbers carried over from dreams.
///
/// THE RULE THIS SECTION EXISTS TO ENFORCE: no baht figure appears here, ever.
/// These are two- or three-digit เลขเชิงสัญลักษณ์, not tickets. Telling someone
/// their watched "71" won ฿2,000 would be telling them they won money on a
/// ticket they do not hold. ออก / ไม่ออก is the entire truth available, and it
/// is still the thing they open the app to find out.
///
/// Provenance is shown on every row. Without it this list is visually
/// indistinguishable from a เลขเด็ด tip sheet, which is precisely what the
/// product must not become.
class _WatchedSection extends ConsumerWidget {
  const _WatchedSection({required this.watched, required this.latest});

  final List<WatchedNumber> watched;
  final AsyncValue<DrawResult> latest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final draw = latest.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('เลขที่ตามอยู่',
            caption: 'เลขจากความฝันที่คุณเก็บไว้ — ดูว่าออกหรือไม่'),
        const SizedBox(height: 10),
        for (final w in watched) ...[
          Builder(builder: (context) {
            final outcome =
                draw == null ? null : checkWatched(draw, w);
            final drawn = outcome?.drawn ?? false;
            final judgeable = outcome?.judgeable ?? false;

            return SectionCard(
              color: drawn ? NimitColors.successBg : NimitColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  Text(w.number,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: drawn
                            ? NimitColors.successInk
                            : NimitColors.ink,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      )),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          !judgeable
                              ? 'ยังไม่ประกาศ'
                              : drawn
                                  ? 'เลขนี้ออก · ${outcome!.matchedTierTh}'
                                  : 'งวดนี้ไม่ออก',
                          style: textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w700,
                            color: drawn
                                ? NimitColors.successInk
                                : NimitColors.inkSoft,
                          ),
                        ),
                        if (w.sourceTh != null)
                          Text(w.sourceTh!,
                              style: textTheme.bodySmall!
                                  .copyWith(color: NimitColors.inkSoft)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'เลิกติดตาม',
                    onPressed: () => ref
                        .read(watchedNumbersProvider.notifier)
                        .remove(w.number),
                    icon: const Icon(Icons.close,
                        size: 18, color: NimitColors.inkSoft),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
        ],
        const DisclaimerText(
          'เลขที่ตามอยู่ไม่ใช่สลาก ถึงเลขจะออกก็ต้องมีสลากตัวจริงจึงจะขึ้นเงินได้',
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
