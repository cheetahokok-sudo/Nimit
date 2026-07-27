import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/nimit_theme.dart';
import '../../data/lottery_checker.dart';
import '../../data/models/lottery.dart';

/// Shared presentation for the ตรวจหวย screens.
///
/// The audience shapes every choice here: people who buy every งวด, often over
/// 50, frequently reading outdoors in bright sun on an inexpensive phone. So —
///
///  * money always carries separators and a ฿. A bare `6000000` cannot be read
///    at a glance, and this screen exists to be read at a glance;
///  * winning numbers are set large, bold and letter-spaced, because the
///    numbers ARE the content and prose is not;
///  * no state is signalled by colour alone. Every one carries an icon and a
///    word too, for colour-blind users and for sunlight that washes out a tint.

final _baht = NumberFormat.decimalPattern('th');

/// e.g. `฿6,000,000`
String formatBaht(int amount) => '฿${_baht.format(amount)}';

/// The three states a saved number can be in against a draw.
///
/// A loss is deliberately NEUTRAL, not warn-red. Someone who buys every งวด
/// will see this state roughly 23 times a year; painting it as an alarm is
/// unkind and, worse, spends the warn tokens on the one state that does not
/// need attention. Red is reserved for "we cannot tell you yet".
enum TicketState { won, lost, pending }

class TicketStatePill extends StatelessWidget {
  const TicketStatePill({
    super.key,
    required this.state,
    required this.labelTh,
  });

  final TicketState state;
  final String labelTh;

  @override
  Widget build(BuildContext context) {
    final (bg, ink, icon) = switch (state) {
      TicketState.won => (
          NimitColors.successBg,
          NimitColors.successInk,
          Icons.check_circle
        ),
      TicketState.lost => (
          NimitColors.creamDeep,
          NimitColors.inkSoft,
          Icons.remove_circle_outline
        ),
      TicketState.pending => (
          NimitColors.warnBg,
          NimitColors.warnInk,
          Icons.schedule
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: ink),
          const SizedBox(width: 6),
          Text(
            labelTh,
            // 15sp semibold rather than labelSmall: warnBg on warnInk is about
            // 4.2:1, which clears AA only at larger sizes. The old pill used
            // labelSmall and did not.
            style: TextStyle(
              color: ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// A winning number, sized to be read at arm's length.
class BigNumber extends StatelessWidget {
  const BigNumber(this.number, {super.key, this.size = 40, this.color});

  final String number;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      number,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: size * 0.12,
        height: 1.1,
        color: color ?? NimitColors.gold,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// One secondary prize tier: label on the left, numbers on the right.
///
/// A ROW, not a column in a three-across grid, and the reason is a real bug:
/// side-by-side columns gave each tier about a third of the width, so on a
/// 400px phone "เลขหน้า 3 ตัว 683 709" and "เลขท้าย 3 ตัว 427 746" ran into
/// each other and rendered as "709427". Two numbers that belong to different
/// prizes reading as one number is the worst possible failure on this screen.
///
/// Rows also read better for the audience: the eye goes down a list of labels
/// rather than across three cramped headings, and each number gets the full
/// remaining width no matter how many the tier holds.
class PrizeRow extends StatelessWidget {
  const PrizeRow({
    super.key,
    required this.labelTh,
    required this.numbers,
    this.onDark = false,
    this.emphasis = false,
  });

  final String labelTh;
  final List<String> numbers;
  final bool onDark;

  /// เลขท้าย 2 ตัว is the number this audience plays most, so it is set larger
  /// than its siblings rather than being one of three equals.
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final labelColor = onDark ? NimitColors.onDarkSoft : NimitColors.inkSoft;
    final valueColor = onDark ? NimitColors.onDark : NimitColors.ink;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 104,
            child: Text(labelTh,
                style: TextStyle(
                    fontSize: 13,
                    height: 1.25,
                    color: labelColor,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              // Wide gap between numbers: at a glance "683 709" must never be
              // mistaken for one six-digit number.
              numbers.isEmpty ? '—' : numbers.join('     '),
              style: TextStyle(
                fontSize: emphasis ? 30 : 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.5,
                height: 1.1,
                color: emphasis ? NimitColors.gold : valueColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Classify a checked ticket for display.
TicketState ticketStateOf(CheckOutcome outcome, TicketOutcome t) {
  if (t.isWin) return TicketState.won;
  // The gate: without a complete, announced, fully-understood draw the app may
  // not say a ticket lost. Saying "not yet" when we do not know is recoverable;
  // saying "you lost" when we do not know is not.
  if (!outcome.verdictAvailable) return TicketState.pending;
  if (t.invalid) return TicketState.pending;
  return TicketState.lost;
}

String ticketLabelOf(CheckOutcome outcome, TicketOutcome t) {
  if (t.isWin) return 'ถูกรางวัล ${formatBaht(t.totalAmountThb)}';
  if (t.invalid) return 'เลขไม่ครบ 6 หลัก';
  if (!outcome.verdictAvailable) {
    return outcome.draw.status == DrawStatus.partial
        ? 'ผลยังไม่ครบ'
        : 'ยังไม่ประกาศ';
  }
  return 'ไม่ถูกรางวัล';
}
