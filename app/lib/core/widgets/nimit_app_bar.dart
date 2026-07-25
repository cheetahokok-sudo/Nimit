import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/nimit_theme.dart';

/// Brand app bar: moon mark + "นิมิต · ฝัน • ดวง • ความเชื่อ".
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
                Text('ฝัน • ดวง • ความเชื่อ',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall!
                        .copyWith(color: NimitColors.inkSoft)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'แหล่งอ้างอิง',
          onPressed: () => context.push('/sources'),
          icon: const Icon(Icons.menu_book_outlined, color: NimitColors.ink),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
