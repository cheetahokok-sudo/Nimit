import 'package:flutter/material.dart';

import '../theme/nimit_theme.dart';

/// Section heading with optional soft caption underneath.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.caption});

  final String title;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
                textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w800)),
        if (caption != null) ...[
          const SizedBox(height: 2),
          Text(caption!,
              style:
                  textTheme.bodySmall!.copyWith(color: NimitColors.inkSoft)),
        ],
      ],
    );
  }
}

/// Light card container used throughout the board.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.color = NimitColors.surface,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: NimitColors.border),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: card,
    );
  }
}

/// Dark aubergine hero card (dream card, draw banner, ลัคนา card...).
class DarkCard extends StatelessWidget {
  const DarkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: NimitColors.aubergine,
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }
}

/// Recurring compliance line, e.g. "ไม่ใช่คำทำนายผล".
class DisclaimerText extends StatelessWidget {
  const DisclaimerText(this.text, {super.key, this.center = false});

  final String text;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: Theme.of(context)
          .textTheme
          .bodySmall!
          .copyWith(color: NimitColors.inkSoft),
    );
  }
}
