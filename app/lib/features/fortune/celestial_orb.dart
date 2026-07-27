import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/nimit_theme.dart';

/// The orbit motif on the ดวงของฉัน card.
///
/// PAINTED, NOT SHIPPED. An illustration this simple — rings, a lit sphere,
/// three satellites, a dust of stars — costs nothing to draw and a great deal
/// to ship: a raster wide enough for a 3x phone is hundreds of kilobytes in a
/// web bundle that a ชาวบ้าน audience downloads over 4G, and it would be pinned
/// to one palette while the card's colours come from tokens. Drawn, it is
/// resolution-free, themed from [NimitColors], and animation-ready later
/// without redrawing art.
///
/// DETERMINISTIC BY CONSTRUCTION. The star field uses a seeded generator, so
/// the same card renders identically on every build and in every screenshot
/// test. `Random()` here would make golden tests flap forever.
///
/// It is decoration and says nothing. Everything the user must actually read
/// lives in text beside it — a picture that carried meaning would be a claim
/// without a citation.
class CelestialOrb extends StatelessWidget {
  const CelestialOrb({super.key, this.size = 150});

  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _CelestialPainter()),
      ),
    );
  }
}

class _CelestialPainter extends CustomPainter {
  /// Orbits as (radius fraction, tilt, satellite angle, satellite radius,
  /// whether the satellite is gold). Hand-placed rather than evenly spaced:
  /// three satellites at regular intervals read as a diagram, and the point of
  /// this is atmosphere.
  static const _orbits = <List<double>>[
    [0.94, -0.32, 5.55, 5.0, 1],
    [0.74, -0.18, 3.05, 6.5, 1],
    [0.54, 0.10, 1.62, 4.0, 0],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    _paintHalo(canvas, c, r);
    _paintStars(canvas, size);

    for (final o in _orbits) {
      _paintOrbit(canvas, c, r * o[0], o[1], o[2], o[3], o[4] == 1);
    }

    _paintCore(canvas, c, r * 0.30);
  }

  /// A soft aubergine bloom, so the rings sit in depth rather than on a flat
  /// panel. Drawn first and kept faint: the card is already dark, and a strong
  /// halo turns into a grey smear on a cheap LCD in daylight.
  void _paintHalo(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            NimitColors.gold.withValues(alpha: 0.13),
            NimitColors.aubergineDeep.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.78],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  void _paintOrbit(Canvas canvas, Offset c, double radius, double tilt,
      double satelliteAngle, double satelliteRadius, bool gold) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(tilt);

    // Ellipse, not circle: a tilted ring reads as an orbit seen at an angle,
    // where a plain circle reads as a target.
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: radius * 2,
      height: radius * 2 * 0.82,
    );

    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = NimitColors.gold.withValues(alpha: 0.42),
    );

    // The satellite rides the ellipse it belongs to, so it can never drift off
    // its own ring when the size changes.
    final p = Offset(
      math.cos(satelliteAngle) * rect.width / 2,
      math.sin(satelliteAngle) * rect.height / 2,
    );

    final colour = gold ? NimitColors.gold : NimitColors.onDark;
    canvas.drawCircle(
        p, satelliteRadius + 2.5, Paint()..color = colour.withValues(alpha: 0.18));
    canvas.drawCircle(p, satelliteRadius, Paint()..color = colour);

    canvas.restore();
  }

  /// The lit body. A linear gradient across the sphere gives it a light source;
  /// a flat disc reads as a hole punched in the card.
  void _paintCore(Canvas canvas, Offset c, double radius) {
    final rect = Rect.fromCircle(center: c, radius: radius);

    canvas.drawCircle(
        c, radius * 1.45, Paint()..color = NimitColors.gold.withValues(alpha: 0.14));

    canvas.drawCircle(
      c,
      radius,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [NimitColors.gold, NimitColors.goldDeep],
        ).createShader(rect),
    );
  }

  /// Seeded so the field never changes between builds.
  void _paintStars(Canvas canvas, Size size) {
    final rnd = math.Random(20690729);
    final paint = Paint();
    for (var i = 0; i < 34; i++) {
      final p = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      // Keep the field off the core, where dots would read as dirt on a lens.
      if ((p - size.center(Offset.zero)).distance < size.shortestSide * 0.22) {
        continue;
      }
      paint.color = NimitColors.onDark
          .withValues(alpha: 0.10 + rnd.nextDouble() * 0.30);
      canvas.drawCircle(p, 0.7 + rnd.nextDouble() * 1.0, paint);
    }
  }

  // Nothing here varies at runtime, so a repaint is never needed.
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
