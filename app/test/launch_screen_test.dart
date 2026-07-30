// The iOS launch screen, held to the one thing it can get wrong silently.
//
// LaunchScreen.storyboard is XML that Xcode compiles; it cannot import
// NimitColors, so its background is three hand-written floats. Nothing else in
// the suite reads that file. Left alone it was pure white while the first
// Flutter frame paints cream — a white flash on every cold start, visible on
// every device, and invisible to every test.
//
// Matching them is the fix. Asserting they still match is this file, because the
// next person to open the storyboard in Xcode will be offered "White" as a
// helpful default.
//
// NOT ASSERTED HERE YET: that LaunchImage*.png are real artwork. All three are
// currently Flutter's 68-byte 1x1 transparent placeholders, which is why the
// build log carries "Launch image is set to the default placeholder icon".
// Adding that guard now would fail the suite and block the release, so it lands
// with the artwork it is meant to protect — see the pending test at the bottom,
// which names the requirement without pretending it is met.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nimit/core/theme/nimit_theme.dart';

const _storyboard = 'ios/Runner/Base.lproj/LaunchScreen.storyboard';
const _launchImageDir = 'ios/Runner/Assets.xcassets/LaunchImage.imageset';

void main() {
  test('the launch screen background is NimitColors.cream', () {
    final xml = File(_storyboard).readAsStringSync();

    final match = RegExp(
      r'<color key="backgroundColor" red="([\d.]+)" green="([\d.]+)" '
      r'blue="([\d.]+)"',
    ).firstMatch(xml);
    expect(match, isNotNull,
        reason: 'could not find the view backgroundColor in $_storyboard — '
            'if Xcode rewrote it as a named or system colour, this test needs '
            'to learn the new shape rather than be deleted');

    // Storyboard floats are 0..1; the palette is 0..255. Compare at the byte
    // the compiler will actually produce, not at float equality.
    int toByte(String s) => (double.parse(s) * 255).round();
    final actual = [
      toByte(match!.group(1)!),
      toByte(match.group(2)!),
      toByte(match.group(3)!),
    ];

    expect(actual, [
      (NimitColors.cream.r * 255).round(),
      (NimitColors.cream.g * 255).round(),
      (NimitColors.cream.b * 255).round(),
    ], reason: 'launch screen background must equal NimitColors.cream '
        '(0xFFF6F0E4), or a cold start flashes a different colour before the '
        'first Flutter frame');
  });

  test('the launch image asset set still has its three scales', () {
    // Cheap structural guard: the storyboard references "LaunchImage" by name,
    // and a missing scale is a runtime miss rather than a build error.
    for (final name in const [
      'LaunchImage.png',
      'LaunchImage@2x.png',
      'LaunchImage@3x.png',
    ]) {
      expect(File('$_launchImageDir/$name').existsSync(), isTrue,
          reason: '$name is referenced by LaunchScreen.storyboard');
    }
  });

  test('launch images are real artwork, not the Flutter placeholder', () {
    // Flutter's template ships three 68-byte 1x1 transparent PNGs. Any real
    // launch image is far larger, so size alone separates them.
    for (final name in const [
      'LaunchImage.png',
      'LaunchImage@2x.png',
      'LaunchImage@3x.png',
    ]) {
      final bytes = File('$_launchImageDir/$name').lengthSync();
      expect(bytes, greaterThan(1000),
          reason: '$name is $bytes bytes — still the 68-byte placeholder. '
              'Apple reports this as "Launch image is set to the default '
              'placeholder icon".');
    }
  }, skip: 'Pending the นิมิต logo artwork — remove skip when it lands.');
}
