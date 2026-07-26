/// Prize matching, on-device.
///
/// WHY THIS IS NOT A SERVER CALL. A draw is 173 numbers — small enough to send
/// to the phone. Matching here means the user's ticket numbers never touch the
/// network, which keeps this feature at the same zero-PDPA exposure as the
/// local dream journal, and it means checking works offline and instantly.
///
/// STANDING CONSTRAINT: no RPC parameter may ever carry a user's lottery
/// number. Moving matching server-side would need the consent work first.
///
/// TWO INVARIANTS IN THIS FILE, both one character away from being wrong:
///
///   1. No `int.parse`. Everything is String. '000123' must stay six
///      characters and '03' must compare as '03'. Converting a lottery number
///      to an integer is always a bug.
///   2. `dutyRate` is never read here. Displayed prize figures are gross by
///      product decision; the 0.5% is surfaced as claim guidance in the UI.
///      There is a test asserting the total is gross specifically so that this
///      fails loudly if someone later "helpfully" nets it.
library;

import 'models/lottery.dart';

/// One tier a ticket won, with the money for a single ticket.
class PrizeHit {
  const PrizeHit({
    required this.tierCode,
    required this.nameTh,
    required this.matchedNumber,
    required this.amountThb,
  });

  final String tierCode;
  final String nameTh;
  final String matchedNumber;
  final int amountThb;
}

/// The outcome for one saved number.
class TicketOutcome {
  const TicketOutcome({
    required this.number,
    required this.quantity,
    required this.hits,
    this.invalid = false,
  });

  final String number;
  final int quantity;
  final List<PrizeHit> hits;

  /// The stored number is not six digits. Deliberately distinct from "no
  /// hits": rendering a malformed number as ไม่ถูกรางวัล would be a false
  /// negative about money.
  final bool invalid;

  /// Gross, for one ticket.
  int get unitAmountThb =>
      hits.fold(0, (sum, h) => sum + h.amountThb);

  /// Gross, for every ticket held bearing this number (ซื้อเป็นชุด).
  int get totalAmountThb => unitAmountThb * quantity;

  bool get isWin => hits.isNotEmpty;
}

/// Every saved number checked against one draw.
class CheckOutcome {
  const CheckOutcome({required this.draw, required this.tickets});

  final DrawResult draw;
  final List<TicketOutcome> tickets;

  /// The single gate the UI consults before rendering ไม่ถูกรางวัล.
  bool get verdictAvailable => draw.verdictAvailable;

  int get totalThb =>
      tickets.fold(0, (sum, t) => sum + t.totalAmountThb);

  int get winningTicketCount => tickets.where((t) => t.isWin).length;

  bool get hasWin => tickets.any((t) => t.isWin);
}

final _sixDigits = RegExp(r'^[0-9]{6}$');

/// True when [ticket] satisfies [kind] against prize number [prize].
bool matches(String ticket, String prize, MatchKind kind) => switch (kind) {
      MatchKind.exact6 => ticket == prize,
      MatchKind.prefix3 => ticket.substring(0, 3) == prize,
      MatchKind.suffix3 => ticket.substring(3) == prize,
      MatchKind.suffix2 => ticket.substring(4) == prize,
    };

/// Check one saved ticket against a draw.
///
/// STACKING RULE. A ticket wins independently in EVERY tier whose rule it
/// satisfies, and the payouts add. Within a single tier it collects at most
/// once. รางวัลที่ 1 and รางวัลข้างเคียง are mutually exclusive by construction
/// — the side numbers are the first-prize number ±1, verified against the live
/// source (first 639214, near1 639213/639215) — so no six-digit string can
/// satisfy both, and the checker relies on that structurally rather than
/// special-casing it.
///
/// The theoretical maximum stack is รางวัลที่ 1 + เลขหน้า 3 ตัว + เลขท้าย 3 ตัว
/// + เลขท้าย 2 ตัว = 6,000,000 + 4,000 + 4,000 + 2,000 = ฿6,010,000. Rare, but
/// real, and must not be clamped.
TicketOutcome checkTicket(DrawResult draw, SavedTicket ticket) {
  final number = ticket.number.trim();
  if (!_sixDigits.hasMatch(number)) {
    return TicketOutcome(
      number: ticket.number,
      quantity: ticket.quantity,
      hits: const [],
      invalid: true,
    );
  }

  final hits = <PrizeHit>[];
  for (final tier in draw.prizes) {
    final kind = tier.matchKind;
    // An unreadable rule cannot be guessed either way; DrawResult already
    // reports hasUnreadableTier, which suppresses the verdict entirely.
    if (kind == null) continue;

    for (final prize in tier.numbers) {
      if (matches(number, prize, kind)) {
        hits.add(PrizeHit(
          tierCode: tier.code,
          nameTh: tier.nameTh,
          matchedNumber: prize,
          amountThb: tier.amountThb,
        ));
        break; // at most once per tier
      }
    }
  }

  return TicketOutcome(
    number: number,
    quantity: ticket.quantity,
    hits: hits,
  );
}

/// Check every saved ticket against one draw.
CheckOutcome checkAll(DrawResult draw, List<SavedTicket> tickets) =>
    CheckOutcome(
      draw: draw,
      tickets: [for (final t in tickets) checkTicket(draw, t)],
    );

/// What a set of held tickets would pay if they took the top prize.
///
/// This is the "ถ้าถูกงวดนี้ 5 ใบ ได้เท่าไร" figure, and it is deliberately
/// computed from tickets the user ALREADY HOLDS — never from a hypothetical
/// "what if you bought N more", which would be an inducement to spend on a
/// screen that also carries the responsible-use budget card.
///
/// Gross, by product decision. The 0.5% stamp duty is shown as claim guidance
/// beside the win, not deducted here.
int hopeAmountThb(DrawResult draw, List<SavedTicket> tickets) {
  final first = draw.tier('first');
  if (first == null) return 0;
  final held = tickets.fold<int>(0, (sum, t) => sum + t.quantity);
  return first.amountThb * held;
}
