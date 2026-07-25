import 'package:flutter/material.dart';

import '../theme/nimit_theme.dart';

/// Gold pill showing a symbolic number (เลขเชิงสัญลักษณ์).
class NumberPill extends StatelessWidget {
  const NumberPill(this.number, {super.key, this.large = false});

  final String number;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 22 : 18,
        vertical: large ? 12 : 9,
      ),
      decoration: BoxDecoration(
        color: NimitColors.gold,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        number,
        style: TextStyle(
          fontSize: large ? 22 : 17,
          fontWeight: FontWeight.w800,
          color: NimitColors.aubergineDeep,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

/// Wrap-row of number pills.
class NumberPillRow extends StatelessWidget {
  const NumberPillRow(this.numbers, {super.key, this.large = false});

  final List<String> numbers;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [for (final n in numbers) NumberPill(n, large: large)],
    );
  }
}
