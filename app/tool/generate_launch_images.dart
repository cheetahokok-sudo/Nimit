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
import 'package:nimit/core/brand/nimit_mark.dart';
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

/// The mark, on cream, at launch-screen proportions.
///
/// The drawing lives in lib/core/brand/nimit_mark.dart. This class is only the
/// launch-specific part: the cream field, and a gentler fill than the icon uses
/// because a launch screen has room the 60 px icon does not.
class _LaunchMark {
  const _LaunchMark();

  /// 1.25 rather than the icon's 1.28 — marginally more air, deliberately short
  /// of the edges. A launch mark that touches the border reads as a cropped
  /// screenshot rather than a logo.
  static const _fill = 1.25;

  void paint(Canvas canvas, Size size) {
    // The cream field is passed to the mark so it fills the square edge to edge:
    // that is what lets the encoder drop alpha, and what makes the image
    // invisible against LaunchScreen.storyboard's identical cream.
    paintNimitMark(canvas, size.width,
        field: NimitColors.cream, fill: _fill);
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
