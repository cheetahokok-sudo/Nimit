// The committed app icons, held to the two things Apple checks first.
//
// ITMS-90717 is an upload rejection, not a review comment: App Store Connect
// refuses a marketing icon carrying an alpha channel, and the build never
// reaches a human. Flutter's own `toByteData(format: png)` always writes RGBA,
// so any future regeneration that reaches for the obvious API reintroduces the
// bug. This test fails first, on a laptop, in a second.
//
// The second check is that the icon is OURS. A `flutter create` in the wrong
// directory quietly restores the blue Flutter logo, which reviewers reject as
// placeholder art — and which nothing else in the suite would notice.
//
// Regenerate the files with: flutter test tool/generate_app_icons.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nimit/core/theme/nimit_theme.dart';

const _appIconDir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
const _marketingIcon = '$_appIconDir/Icon-App-1024x1024@1x.png';

void main() {
  test('no iOS app icon carries an alpha channel', () {
    final icons = Directory(_appIconDir)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.png'))
        .toList();

    expect(icons, hasLength(15), reason: 'Contents.json declares 15 icons');

    for (final icon in icons) {
      final header = _readIhdr(icon.readAsBytesSync());
      expect(header.bitDepth, 8, reason: '${icon.path} bit depth');
      expect(
        header.colourType,
        2,
        reason: '${icon.path} must be truecolour with NO alpha (type 2). '
            'Type 6 is RGBA and App Store Connect rejects it: ITMS-90717.',
      );
    }
  });

  test('the marketing icon is 1024 square and painted in นิมิต aubergine', () {
    final bytes = File(_marketingIcon).readAsBytesSync();
    final header = _readIhdr(bytes);

    expect(header.width, 1024);
    expect(header.height, 1024);

    // Top-left pixel: the field colour, edge to edge. The Flutter placeholder
    // has a white corner, so this is also the placeholder check.
    final corner = _topLeftPixel(bytes, header);
    expect(corner, [
      (NimitColors.aubergine.r * 255).round(),
      (NimitColors.aubergine.g * 255).round(),
      (NimitColors.aubergine.b * 255).round(),
    ]);
  });
}

class _Ihdr {
  const _Ihdr(this.width, this.height, this.bitDepth, this.colourType);
  final int width;
  final int height;
  final int bitDepth;
  final int colourType;
}

/// IHDR is always the first chunk, at a fixed offset after the 8-byte
/// signature: 4 length + 4 type, then width, height, depth, colour type.
_Ihdr _readIhdr(Uint8List png) {
  expect(png.sublist(0, 8), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
      reason: 'not a PNG');
  final data = ByteData.sublistView(png);
  expect(latin1.decode(png.sublist(12, 16)), 'IHDR');
  return _Ihdr(
      data.getUint32(16), data.getUint32(20), png[24], png[25]);
}

/// Inflates the image data and returns the first pixel as [r, g, b].
///
/// Only valid because our encoder writes filter 0 on every scanline; that is a
/// deliberate property of `tool/generate_app_icons.dart`, asserted here so it
/// cannot drift.
List<int> _topLeftPixel(Uint8List png, _Ihdr header) {
  final idat = BytesBuilder();
  var offset = 8;
  while (offset < png.length) {
    final length = ByteData.sublistView(png).getUint32(offset);
    final type = latin1.decode(png.sublist(offset + 4, offset + 8));
    if (type == 'IDAT') {
      idat.add(png.sublist(offset + 8, offset + 8 + length));
    }
    offset += 12 + length; // length + type + data + crc
  }

  final raw = zlib.decode(idat.toBytes());
  expect(raw[0], 0, reason: 'scanline filter must be none');
  return [raw[1], raw[2], raw[3]];
}
