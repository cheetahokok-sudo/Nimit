// Generates every app icon Nimit ships, from one painted drawing.
//
// Run it deliberately, never in CI:
//
//     flutter test tool/generate_app_icons.dart
//
// It lives outside `test/` so a bare `flutter test` cannot trip over it and
// rewrite committed binaries mid-suite. The PNGs it produces ARE committed —
// this file is how they are reproduced, not a build step.
//
// PAINTED, NOT SOURCED. Same argument as CelestialOrb: a drawing costs nothing
// to regenerate at any size, is pinned to the palette tokens rather than to a
// designer's export, and a 20 px icon is a redraw here instead of a resample of
// a 1024 px raster, which is where crescents go to die.
//
// THE ALPHA CHANNEL IS THE POINT. `Image.toByteData(format: png)` always writes
// RGBA, and App Store Connect rejects a marketing icon that carries an alpha
// channel — ERROR ITMS-90717, thrown by the upload, long before a human reviews
// anything. So this file rasterises to raw pixels, drops the alpha byte, and
// writes the PNG itself: colour type 2, truecolour, no alpha, anywhere. The
// drawing fills its square edge to edge, so nothing is lost by dropping it.
// `test/app_icon_test.dart` holds that guarantee to the committed files.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimit/core/brand/nimit_mark.dart';
import 'package:nimit/core/theme/nimit_theme.dart';

/// iOS filenames come from the asset catalog's Contents.json, which Xcode owns.
/// Renaming anything here without editing that file produces a build that
/// looks fine and ships a missing icon.
const _iosIcons = <String, int>{
  'Icon-App-20x20@1x.png': 20,
  'Icon-App-20x20@2x.png': 40,
  'Icon-App-20x20@3x.png': 60,
  'Icon-App-29x29@1x.png': 29,
  'Icon-App-29x29@2x.png': 58,
  'Icon-App-29x29@3x.png': 87,
  'Icon-App-40x40@1x.png': 40,
  'Icon-App-40x40@2x.png': 80,
  'Icon-App-40x40@3x.png': 120,
  'Icon-App-60x60@2x.png': 120,
  'Icon-App-60x60@3x.png': 180,
  'Icon-App-76x76@1x.png': 76,
  'Icon-App-76x76@2x.png': 152,
  'Icon-App-83.5x83.5@2x.png': 167,
  'Icon-App-1024x1024@1x.png': 1024,
};

const _androidIcons = <String, int>{
  'mipmap-mdpi': 48,
  'mipmap-hdpi': 72,
  'mipmap-xhdpi': 96,
  'mipmap-xxhdpi': 144,
  'mipmap-xxxhdpi': 192,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('paint every icon Nimit ships', () async {
    const iosDir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
    for (final entry in _iosIcons.entries) {
      await _write('$iosDir/${entry.key}', entry.value);
    }

    for (final entry in _androidIcons.entries) {
      await _write(
          'android/app/src/main/res/${entry.key}/ic_launcher.png', entry.value);
    }

    await _write('web/icons/Icon-192.png', 192);
    await _write('web/icons/Icon-512.png', 512);
    await _write('web/favicon.png', 32);

    // Maskable icons are cropped to a circle by the launcher, so the motif is
    // pulled inside the 80 % safe zone. Same drawing, more margin.
    await _write('web/icons/Icon-maskable-192.png', 192, motifScale: 0.72);
    await _write('web/icons/Icon-maskable-512.png', 512, motifScale: 0.72);
  });
}

Future<void> _write(String path, int size, {double motifScale = 1.0}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  _NimitIcon(motifScale: motifScale)
      .paint(canvas, Size(size.toDouble(), size.toDouble()));
  final image = await recorder.endRecording().toImage(size, size);
  final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(_encodeOpaquePng(rgba!.buffer.asUint8List(), size));
  // ignore: avoid_print
  print('wrote $path ($size×$size)');
}

/// The mark, on aubergine, filling the tile.
///
/// The drawing itself lives in lib/core/brand/nimit_mark.dart — see that file for
/// why. This class is now only the icon-specific part: the aubergine field, and
/// motifScale for the maskable web variants.
class _NimitIcon {
  const _NimitIcon({this.motifScale = 1.0});

  /// Shrinks the motif toward the centre without touching the background, for
  /// maskable icons that get cropped to a circle. Composes with the mark's own
  /// fill rather than replacing it.
  final double motifScale;

  void paint(Canvas canvas, Size size) {
    final s = size.width;

    // Edge to edge and fully opaque: this is what lets the encoder drop alpha.
    canvas.drawRect(
        Rect.fromLTWH(0, 0, s, s), Paint()..color = NimitColors.aubergine);

    canvas.save();
    canvas.translate(s * 0.5, s * 0.5);
    canvas.scale(motifScale);
    canvas.translate(s * -0.5, s * -0.5);
    paintNimitMark(canvas, s);
    canvas.restore();
  }
}

// ---------------------------------------------------------------------------
// A PNG encoder that cannot produce an alpha channel
// ---------------------------------------------------------------------------

/// Encodes premultiplied RGBA pixels as a truecolour PNG with no alpha channel.
///
/// Colour type 2, bit depth 8, filter 0 on every scanline. Deliberately the
/// dullest PNG that exists: `test/app_icon_test.dart` parses these files back,
/// and adaptive filtering would buy a few kilobytes at the cost of that test.
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
