import 'package:flutter/material.dart';

import '../theme/nimit_theme.dart';

/// Brand app bar: moon mark + "นิมิต · คลังตำราอ้างอิงไทย".
///
/// The subtitle read "ฝัน • ดวง • ความเชื่อ" until App Store review rejected
/// 1.0.0 (10) under guideline 4.3(b). Three words, two of which named a
/// saturated category, on every screen in the app — it described นิมิต as the
/// genre rather than as the thing it actually is, which is a cited corpus.
///
/// The แหล่งอ้างอิง action is gone from here too: it is a tab now, and an icon
/// duplicating a destination in the bottom bar is a second door to one room.
class NimitAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NimitAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppBar(
      toolbarHeight: 64,
      titleSpacing: 20,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: NimitColors.aubergine,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.nightlight_round,
                color: NimitColors.gold, size: 20),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('นิมิต',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium!
                        .copyWith(fontWeight: FontWeight.w800)),
                Text('คลังตำราอ้างอิงไทย',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall!
                        .copyWith(color: NimitColors.inkSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
