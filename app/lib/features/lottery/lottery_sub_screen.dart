import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nimit_theme.dart';

/// Shared frame for the ตรวจหวย sub-routes.
///
/// These render INSIDE the shell (nested under the `/lottery` branch), so the
/// bottom navigation and app bar persist and each screen is a bare scroll view
/// with its own back affordance — the same arrangement `/dream/result` uses.
class LotterySubScreen extends StatelessWidget {
  const LotterySubScreen({
    super.key,
    required this.titleTh,
    required this.child,
  });

  final String titleTh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'ย้อนกลับ',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: () => context.go('/lottery'),
              icon: const Icon(Icons.arrow_back, color: NimitColors.ink),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(titleTh,
                  style: textTheme.titleLarge!
                      .copyWith(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}
