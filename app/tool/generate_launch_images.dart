// Generates the iOS launch images from one painted drawing.
//
// Run it deliberately, never in CI:
//
//     flutter test tool/generate_launch_images.dart
//
// Same contract as generate_app_icons.dart, and for the same reasons: it lives
// outside test/ so a bare `flutter test` cannot rewrite committed binaries
// mid-suite, the PNGs it produces ARE committed, and every measurement is a
// fraction of the canvas so 240 px and 720 px are one drawing rather than a
// resample.
//
// ── WHAT THIS IS AND IS NOT A DRAWING OF ───────────────────────────────────
//
// Three shapes: a gold crescent, a four-pointed star, a cloud. That is the
// whole mark, and the restraint is the design rather than a limitation of it.
//
// An earlier version of this file also drew the นิมิต artwork's gold underline
// and its two spiral scrolls. Both are gone, and the reason is worth keeping:
// the scrolls rendered as white rings that read unmistakably as googly eyes, and
// redrawing them as stroked spirals only made them legible, not good. Canvas
// paths are the right tool for geometry — two circles make the crescent, four
// quadratics make the star — and the wrong tool for illustration. When the
// illustrative parts came out, what was left was better than what it replaced.
//
// So: this is the artwork's COMPOSITION, deliberately reduced. If the exported
// illustration is ever preferred, drop the PNGs over the committed ones and
// delete this file — test/launch_screen_test.dart checks the bytes, not the
// provenance.
//
// ── OPAQUE, AND THAT IS WHAT MAKES IT SEAMLESS ─────────────────────────────
//
// The drawing fills its rectangle with NimitColors.cream, and
// LaunchScreen.storyboard paints the same cream behind it with
// contentMode="center". So the image's edges are invisible: no alpha is needed,
// and the encoder below cannot produce any.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimit/core/theme/nimit_theme.dart';

/// Filenames are fixed by LaunchImage.imageset/Contents.json, which Xcode owns.
/// The 1x size is in POINTS: the storyboard centres the image at its natural
/// size, so 240 here means a 240 pt mark on every device, drawn at 1x/2x/3x.
const _launchImages = <String, int>{
  'LaunchImage.png': 240,
  'LaunchImage@2x.png': 480,
  'LaunchImage@3x.png': 720,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('paint the launch images', () async {
    const dir = 'ios/Runner/Assets.xcassets/LaunchImage.imageset';
    for (final entry in _launchImages.entries) {
      await _write('$dir/${entry.key}', entry.value);
    }
  });
}

Future<void> _write(String path, int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const _LaunchMark().paint(canvas, Size(size.toDouble(), size.toDouble()));
  final image = await recorder.endRecording().toImage(size, size);
  final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(_encodeOpaquePng(rgba!.buffer.asUint8List(), size));
  // ignore: avoid_print
  print('wrote $path ($size×$size)');
}

/// จันทร์เสี้ยวเหนือเมฆ — the crescent and star of the app icon, over a cloud,
/// on cream.
///
/// The crescent and star keep the icon's geometry, so the launch screen and the
/// home-screen icon are recognisably one brand; only the field colour and the
/// cloud differ.
class _LaunchMark {
  const _LaunchMark();

  /// Vertical centre of the composition as drawn, measured from its own
  /// extremes: the crescent's top edge at 0.155 (0.335 − 0.180) and the cloud's
  /// underside at 0.698 (0.578 + 0.120).
  ///
  /// It is NOT 0.5, and that was a visible flaw: the mark had 0.155 of space
  /// above it and 0.302 below, so it floated high on the launch screen. Rather
  /// than re-tune fourteen coordinates and re-derive this every time one moves,
  /// the drawing keeps its own numbers and the transform below recentres it.
  static const _markCentreY = 0.4265;

  /// How much of the square the mark spans once recentred. At 1.0 it drew 0.700
  /// wide, leaving 15 % dead on each side; 1.25 takes it to 0.875 with a 6 %
  /// margin, and the vertical extent to 0.679 — still short of the edges, which
  /// is deliberate. A launch mark that touches the border reads as a cropped
  /// screenshot rather than a logo.
  static const _fill = 1.25;

  void paint(Canvas canvas, Size size) {
    final s = size.width;

    // Edge to edge and fully opaque — this is what lets the encoder drop alpha,
    // and what makes the image invisible against the storyboard's cream. Painted
    // BEFORE the transform so it always fills the square, whatever _fill is.
    canvas.drawRect(
        Rect.fromLTWH(0, 0, s, s), Paint()..color = NimitColors.cream);

    // Map the composition's own centre onto the canvas centre, scaled. Reads
    // backwards, applies forwards: the last translate runs first.
    canvas.save();
    canvas.translate(s * 0.5, s * 0.5);
    canvas.scale(_fill);
    canvas.translate(s * -0.5, s * -_markCentreY);

    _cloud(canvas, s);

    // Crescent above the cloud, overlapping it as the artwork does. A filled
    // disc with a second disc punched out: a stroked arc thins to nothing at the
    // small end, where this shape still reads. saveLayer so dstOut cuts the
    // crescent only, not the cream behind it.
    canvas.saveLayer(Rect.fromLTWH(0, 0, s, s), Paint());
    canvas.drawCircle(Offset(s * 0.470, s * 0.335), s * 0.180,
        Paint()..color = NimitColors.gold);
    canvas.drawCircle(Offset(s * 0.560, s * 0.268), s * 0.157,
        Paint()..blendMode = BlendMode.dstOut);
    canvas.restore();

    _star(canvas, Offset(s * 0.700, s * 0.300), s * 0.052, s * 0.017);

    canvas.restore();
  }

  /// A four-pointed star with concave sides — the shape Thai temple art uses
  /// for a light, and unmistakably not the five-pointed flag star.
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

  /// A bank of puffs on a long sweeping base, filled peach → pink → lavender.
  ///
  /// Built as a union of ovals over a rounded slab rather than one hand-fitted
  /// bezier: overlapping ovals with the default non-zero fill merge into a single
  /// silhouette, and each puff is then three legible numbers instead of four
  /// control points nobody can adjust later.
  void _cloud(Canvas canvas, double s) {
    final bounds = Rect.fromLTWH(s * 0.150, s * 0.470, s * 0.700, s * 0.260);

    final body = Path()..fillType = PathFillType.nonZero;

    // The base slab, which ties every puff together and gives the cloud its flat
    // underside.
    //
    // Its top edge sits at 0.578, not 0.600. At 0.600 the two puffs either side
    // of centre only grazed each other about a pixel above the slab, leaving a
    // sliver of cream showing through the middle of the silhouette — a white
    // speck, visible at 720 px and impossible to explain. Raising the slab
    // overlaps both puffs properly; the underside is unchanged because the
    // height grew by the same amount.
    body.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(bounds.left, s * 0.578, bounds.width, s * 0.120),
      Radius.circular(s * 0.060),
    ));

    // Puffs: x, y, r as fractions. Tallest left of centre, stepping down to the
    // right, which is how the artwork stacks them.
    const puffs = <List<double>>[
      [0.300, 0.560, 0.082],
      [0.395, 0.535, 0.070],
      [0.500, 0.560, 0.076],
      [0.610, 0.575, 0.062],
      [0.690, 0.560, 0.072],
    ];
    for (final p in puffs) {
      body.addOval(Rect.fromCircle(
          center: Offset(s * p[0], s * p[1]), radius: s * p[2]));
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
}

// ---------------------------------------------------------------------------
// A PNG encoder that cannot produce an alpha channel
// ---------------------------------------------------------------------------

/// Encodes premultiplied RGBA pixels as a truecolour PNG with no alpha channel.
///
/// Deliberately identical to the one in generate_app_icons.dart. Sharing it would
/// mean a lib/ file that only tooling uses, or one tool importing another;
/// duplicating forty lines of the dullest PNG writer that exists is the cheapest
/// of the three, and test/launch_screen_test.dart parses the output.
Uint8List _encodeOpaquePng(Uint8List rgba, int size) {
  final raw = Uint8List(size * (1 + size * 3));
  var out = 0;
  for (var y = 0; y < size; y++) {
    raw[out++] = 0; // filter: none
    var i = y * size * 4;
    for (var x = 0; x < size; x++) {
      raw[out++] = rgba[i];
      raw[out++] = rgba[i + 1];
      raw[out++] = rgba[i + 2];
      i += 4; // the alpha byte goes nowhere
    }
  }

  final png = BytesBuilder()
    ..add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  _chunk(png, 'IHDR', <int>[
    ..._u32(size),
    ..._u32(size),
    8, // bit depth
    2, // colour type: truecolour, NO alpha
    0, 0, 0, // compression, filter, interlace
  ]);
  _chunk(png, 'IDAT', ZLibCodec(level: 9).encode(raw));
  _chunk(png, 'IEND', const <int>[]);
  return png.toBytes();
}

void _chunk(BytesBuilder png, String type, List<int> data) {
  final body = <int>[...ascii.encode(type), ...data];
  png
    ..add(_u32(data.length))
    ..add(body)
    ..add(_u32(_crc32(body)));
}

List<int> _u32(int v) =>
    [(v >> 24) & 0xFF, (v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF];

final List<int> _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) == 1 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return (c ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}
