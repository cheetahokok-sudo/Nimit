// The share card, held to the property that was broken and is easy to re-break.
//
// The card is captured with RenderRepaintBoundary.toImage(), which returns exactly
// the boundary child's bounding box. When that child was DarkCard — a rectangle
// with borderRadius 24 — the PNG's four corners came out TRANSPARENT, with
// antialiased half-pixels along each curve. A chat bubble composites that as white
// wedges with a halo, and the card sat flush to all four edges besides.
//
// The fix is an opaque field inside the boundary. These tests assert the field is
// there, because the failure is invisible in the app: on screen the card looks
// identical either way, and only the shared image is wrong. Nobody would notice
// the regression until it was in someone's LINE chat.
//
// NOT ASSERTED: the rendered pixels. RenderRepaintBoundary.toImage() hangs inside
// testWidgets — tried, killed after 300 s — so the capture cannot be rasterised
// here. These check the widget tree that feeds it instead.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nimit/core/brand/nimit_mark.dart';
import 'package:nimit/core/router/app_router.dart';
import 'package:nimit/core/theme/nimit_theme.dart';
import 'package:nimit/core/widgets/section.dart' show DarkCard;
import 'package:nimit/data/providers.dart';
import 'package:nimit/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpShareCard(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const NimitApp(),
    ));
    await tester.pumpAndSettle();
    appRouter.go('/dream/share');
    await tester.pumpAndSettle();
  }

  /// The boundary the share code captures — found the same way, by type, so this
  /// tracks the real widget rather than a copy of its layout.
  Finder cardBoundary() => find
      .ancestor(
        of: find.byType(DarkCard),
        matching: find.byType(RepaintBoundary),
      )
      .first;

  testWidgets('the captured area is opaque, so corners cannot be transparent',
      (tester) async {
    await pumpShareCard(tester);

    // Inside the boundary there must be a Container painting an opaque colour.
    // Without it the capture is the rounded card alone and the corners are holes.
    final field = tester.widget<Container>(find
        .descendant(of: cardBoundary(), matching: find.byType(Container))
        .first);

    expect(field.color, isNotNull,
        reason: 'the boundary child must paint a field colour; a null colour '
            'means the capture is transparent wherever the card is not');
    expect(field.color!.a, 1.0,
        reason: 'the field must be fully opaque — a translucent one still lets '
            'the chat background through the corners');
    expect(field.color, NimitColors.cream,
        reason: 'the field is the app page colour, so the card reads as sitting '
            'on นิมิต paper rather than on an arbitrary swatch');
  });

  testWidgets('the card is inset from the captured edges', (tester) async {
    await pumpShareCard(tester);

    // Flush to the edge reads as a cropped screenshot. The margin is the other
    // half of the fix and is just as easy to delete by accident.
    final boundaryRect = tester.getRect(cardBoundary());
    final cardRect = tester.getRect(find.byType(DarkCard).first);

    expect(cardRect.left - boundaryRect.left, greaterThan(8));
    expect(boundaryRect.right - cardRect.right, greaterThan(8));
    expect(cardRect.top - boundaryRect.top, greaterThan(8));
    expect(boundaryRect.bottom - cardRect.bottom, greaterThan(8));
  });

  testWidgets('the card carries the นิมิต mark, not a Material icon',
      (tester) async {
    await pumpShareCard(tester);

    // Three marks: the header emblem, the wash behind the card, and the footer
    // wordmark. A borrowed nightlight_round on a card people reshare is the one
    // place this app would look like a template.
    expect(
      find.descendant(of: cardBoundary(), matching: find.byType(NimitMark)),
      findsNWidgets(3),
    );

    // Scoped to the card on purpose. NimitAppBar still uses
    // Icons.nightlight_round as its brand glyph, which is a separate call — this
    // test is about what leaves the app inside a shared image.
    expect(
      find.descendant(
          of: cardBoundary(), matching: find.byIcon(Icons.nightlight_round)),
      findsNothing,
    );
  });

  testWidgets('the watermark never covers the dream text or the numbers',
      (tester) async {
    await pumpShareCard(tester);

    // The wash is the largest mark and sits behind the opaque card. If it ever
    // moves in front, the card stops being legible in a screenshot — which is
    // the only thing it is for.
    final marks = tester.widgetList<NimitMark>(
        find.descendant(of: cardBoundary(), matching: find.byType(NimitMark)));
    final wash = marks.reduce((a, b) => a.size > b.size ? a : b);

    expect(wash.size, greaterThan(100), reason: 'the wash is the big one');

    // Painted before the card in the Stack, so the card covers it.
    final stack = tester.widget<Stack>(
        find.descendant(of: cardBoundary(), matching: find.byType(Stack)).first);
    expect(stack.children.first, isA<Positioned>(),
        reason: 'the wash must be the first child, i.e. underneath the card');
    expect(stack.clipBehavior, Clip.hardEdge,
        reason: 'the wash bleeds off the corner and must be clipped to the '
            'captured area, not spill outside it');
  });
}
