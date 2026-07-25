import 'package:flutter/material.dart';

import '../../data/models/source.dart';
import '../theme/nimit_theme.dart';

/// Round trust-tier badge (A1/A2/B1/B2/C/D) from the source-labeling system.
class SourceBadge extends StatelessWidget {
  const SourceBadge(this.tier, {super.key, this.size = 36});

  final SourceTier tier;
  final double size;

  static const _bg = {
    SourceTier.a1: NimitColors.pastelBlue,
    SourceTier.a2: NimitColors.pastelBlue,
    SourceTier.b1: NimitColors.pastelLavender,
    SourceTier.b2: NimitColors.pastelLavender,
    SourceTier.c: NimitColors.pastelPink,
    SourceTier.d: NimitColors.gold,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: _bg[tier], shape: BoxShape.circle),
      child: Text(
        tier.code,
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w800,
          color: NimitColors.ink,
        ),
      ),
    );
  }
}
