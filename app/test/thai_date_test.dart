import 'package:flutter_test/flutter_test.dart';
import 'package:nimit/core/utils/thai_date.dart';

/// These pin behaviour that previously had NO coverage at all, in a file whose
/// output is a date shown to users next to money.
void main() {
  group('formatThaiDate', () {
    test('renders the Buddhist era year', () {
      expect(formatThaiDate(DateTime(2026, 8, 1)), '1 สิงหาคม 2569');
      expect(formatThaiDate(DateTime(2024, 12, 16)), '16 ธันวาคม 2567');
    });

    test('every month maps to the right Thai name', () {
      const expected = [
        'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
        'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
      ];
      for (var m = 1; m <= 12; m++) {
        expect(formatThaiDate(DateTime(2026, m, 5)), '5 ${expected[m - 1]} 2569');
      }
    });

    test('a leap day formats', () {
      expect(formatThaiDate(DateTime(2028, 2, 29)), '29 กุมภาพันธ์ 2571');
    });
  });

  group('nextDrawDate (an ESTIMATE — see the doc comment)', () {
    test('before the 16th it points at the 16th', () {
      expect(nextDrawDate(DateTime(2026, 7, 2)), DateTime(2026, 7, 16));
      expect(nextDrawDate(DateTime(2026, 7, 15)), DateTime(2026, 7, 16));
    });

    test('on the 1st and 16th it returns TODAY, not the following draw', () {
      // Intentional for "the งวด in play", but a caller wanting "the next one
      // after this" will be off by one. Pinned so the distinction is explicit.
      expect(nextDrawDate(DateTime(2026, 7, 1)), DateTime(2026, 7, 1));
      expect(nextDrawDate(DateTime(2026, 7, 16)), DateTime(2026, 7, 16));
    });

    test('after the 16th it rolls to the 1st of next month', () {
      expect(nextDrawDate(DateTime(2026, 7, 17)), DateTime(2026, 8, 1));
      expect(nextDrawDate(DateTime(2026, 7, 31)), DateTime(2026, 8, 1));
    });

    test('December rolls into January of the next year', () {
      // DateTime(y, 13, 1) normalises to January of y+1. Correct, and pinned
      // so nobody "fixes" it into a bug.
      expect(nextDrawDate(DateTime(2026, 12, 20)), DateTime(2027, 1, 1));
    });

    test('February in a leap year rolls correctly', () {
      expect(nextDrawDate(DateTime(2028, 2, 20)), DateTime(2028, 3, 1));
    });
  });

  group('nowInBangkok', () {
    test('is exactly seven hours ahead of UTC', () {
      final diff = nowInBangkok().difference(DateTime.now().toUtc());
      expect(diff.inMinutes, closeTo(7 * 60, 1));
    });
  });
}
