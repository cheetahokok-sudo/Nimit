// จันทร์เสี้ยวเหนือเมฆ — the นิมิต mark, in one place.
//
// WHY THIS EXISTS IN lib/. It was drawn twice before this file: once in
// tool/generate_app_icons.dart and once in tool/generate_launch_images.dart, with
// a comment in each admitting the cost — "if a puff moves in one file the two
// marks diverge in silence". The share card then needed the same mark as a
// widget, which would have made three copies, so the geometry moved here and both
// generators now call it. One set of numbers, three consumers.
//
// The counter-argument in the icon generator was that a lib/ file only tooling
// imports is not worth having. That stopped being true the moment the app itself
// needed to draw the mark.
//
// EVERY MEASUREMENT IS A FRACTION of the square side, so 18 px in a share-card
// footer and 1024 px in the App Store listing are the same drawing rather than a
// resample. The crescent is a filled disc with a second disc punched out of it: a
// stroked arc thins to nothing at 29 px, where this shape still reads.

import 'package:flutter/material.dart';

import '../theme/nimit_theme.dart';

/// Vertical centre of the composition as drawn — the crescent's top edge at 0.155
/// (0.335 − 0.180) and the cloud's underside at 0.698 (0.578 + 0.120). Not 0.5,
/// so [paintNimitMark] recentres rather than every coordinate being re-tuned.
const _markCentreY = 0.4265;

/// Paints the mark into a [size]×[size] square at the canvas origin.
///
/// [field] fills the square behind the mark; pass null for transparency, which is
/// what a widget wants and what the alpha-stripping PNG encoders must NOT get.
///
/// [fill] is how much of the square the motif spans. 1.0 covers 0.700 and leaves
/// 15 % dead on each side, which reads as a small mark on a big square; the icon
/// uses 1.28 because filling the tile is what made it legible at 60 px.
///
/// [star] drops the four-pointed star, for variants that want two shapes.
void paintNimitMark(
  Canvas canvas,
  double size, {
  Color? field,
  double fill = 1.28,
  bool star = true,
}) {
  final s = size;

  if (field != null) {
    canvas.drawRect(Rect.fromLTWH(0, 0, s, s), Paint()..color = field);
  }

  canvas.save();
  canvas.translate(s * 0.5, s * 0.5);
  canvas.scale(fill);
  canvas.translate(s * -0.5, s * -_markCentreY);

  _cloud(canvas, s);

  // saveLayer so dstOut punches the cut disc out of the crescent only, and not
  // out of whatever is behind it.
  canvas.saveLayer(Rect.fromLTWH(0, 0, s, s), Paint());
  canvas.drawCircle(
      Offset(s * 0.470, s * 0.335), s * 0.180, Paint()..color = NimitColors.gold);
  canvas.drawCircle(Offset(s * 0.560, s * 0.268), s * 0.157,
      Paint()..blendMode = BlendMode.dstOut);
  canvas.restore();

  if (star) {
    _star(canvas, Offset(s * 0.700, s * 0.300), s * 0.052, s * 0.017);
  }

  canvas.restore();
}

/// A bank of puffs on a long sweeping base, filled peach → pink → lavender.
///
/// Overlapping ovals with the default non-zero fill merge into one silhouette, so
/// each puff is three legible numbers rather than four bezier control points.
///
/// The base slab's top edge is 0.578, not 0.600. At 0.600 the two puffs either
/// side of centre only grazed each other about a pixel above the slab, leaving a
/// sliver of the background showing through the middle of the cloud — a speck,
/// visible at 720 px and impossible to explain.
void _cloud(Canvas canvas, double s) {
  final bounds = Rect.fromLTWH(s * 0.150, s * 0.470, s * 0.700, s * 0.260);

  final body = Path()..fillType = PathFillType.nonZero;
  body.addRRect(RRect.fromRectAndRadius(
    Rect.fromLTWH(bounds.left, s * 0.578, bounds.width, s * 0.120),
    Radius.circular(s * 0.060),
  ));
  const puffs = <List<double>>[
    [0.300, 0.560, 0.082],
    [0.395, 0.535, 0.070],
    [0.500, 0.560, 0.076],
    [0.610, 0.575, 0.062],
    [0.690, 0.560, 0.072],
  ];
  for (final p in puffs) {
    body.addOval(
        Rect.fromCircle(center: Offset(s * p[0], s * p[1]), radius: s * p[2]));
  }

  canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            NimitColors.pastelPeach,
            NimitColors.pastelPink,
            NimitColors.pastelLavender,
          ],
        ).createShader(bounds));
}

/// A four-pointed star with concave sides — the shape Thai temple art uses for a
/// light, and unmistakably not the five-pointed flag star.
void _star(Canvas canvas, Offset c, double outer, double inner) {
  final path = Path()
    ..moveTo(c.dx, c.dy - outer)
    ..quadraticBezierTo(c.dx + inner, c.dy - inner, c.dx + outer, c.dy)
    ..quadraticBezierTo(c.dx + inner, c.dy + inner, c.dx, c.dy + outer)
    ..quadraticBezierTo(c.dx - inner, c.dy + inner, c.dx - outer, c.dy)
    ..quadraticBezierTo(c.dx - inner, c.dy - inner, c.dx, c.dy - outer)
    ..close();
  canvas.drawPath(path, Paint()..color = NimitColors.gold);
}

/// The mark as a widget. Square; [size] is the side.
///
/// Used on the share card as the header emblem, as a faint wash behind the card,
/// and beside the wordmark in the footer — three sizes of one drawing.
class NimitMark extends StatelessWidget {
  const NimitMark({super.key, required this.size, this.field, this.star = true});

  final double size;
  final Color? field;
  final bool star;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _MarkPainter(field: field, star: star)),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({this.field, this.star = true});

  final Color? field;
  final bool star;

  @override
  void paint(Canvas canvas, Size size) =>
      paintNimitMark(canvas, size.width, field: field, star: star);

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.field != field || old.star != star;
}
