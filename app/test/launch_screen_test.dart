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
// The third test guards the artwork itself. All three LaunchImage*.png were
// Flutter's 68-byte 1x1 transparent placeholders until tool/generate_launch_images
// painted them, which is what build #8 reported as "Launch image is set to the
// default placeholder icon". A `flutter create` in the wrong directory restores
// those placeholders silently, and nothing else in the suite would notice.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nimit/core/theme/nimit_theme.dart';

const _storyboard = 'ios/Runner/Base.lproj/LaunchScreen.storyboard';
const _launchImageDir = 'ios/Runner/Assets.xcassets/LaunchImage.imageset';
const _androidRes = 'android/app/src/main/res';

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
    // launch image is far larger, so size alone separates them — no need to
    // decode anything to catch the regression this is actually about.
    for (final name in const [
      'LaunchImage.png',
      'LaunchImage@2x.png',
      'LaunchImage@3x.png',
    ]) {
      final bytes = File('$_launchImageDir/$name').lengthSync();
      expect(bytes, greaterThan(1000),
          reason: '$name is $bytes bytes — that is the 68-byte Flutter '
              'placeholder. Apple reports it as "Launch image is set to the '
              'default placeholder icon". Repaint with: '
              'flutter test tool/generate_launch_images.dart');
    }
  });

  test('the launch mark is opaque, and its field is cream', () {
    // The storyboard centres this image on cream with contentMode="center", so
    // the drawing's own field must be the SAME cream or the mark shows as a
    // rectangle with visible edges. Colour type 2 (no alpha) is what makes that
    // safe to rely on: a transparent field would composite instead of matching.
    final bytes = File('$_launchImageDir/LaunchImage@3x.png').readAsBytesSync();
    expect(bytes.sublist(0, 8),
        [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
        reason: 'not a PNG');
    expect(latin1.decode(bytes.sublist(12, 16)), 'IHDR');
    expect(bytes[25], 2,
        reason: 'launch image must be truecolour with NO alpha (type 2), so its '
            'cream field matches the storyboard exactly rather than blending');

    final data = ByteData.sublistView(bytes);
    expect(data.getUint32(16), 720, reason: '@3x width');
    expect(data.getUint32(20), 720, reason: '@3x height');
  });

  // ── Android ───────────────────────────────────────────────────────────────
  //
  // The iOS fix above shipped while Android still cold-started on Flutter's
  // template: white in light mode, BLACK in dark mode, then cream on the first
  // frame. The same defect, on the platform this app's audience actually uses.
  // These tests exist because nothing else in the suite reads Android resource
  // XML, and `flutter create` restores every one of these files silently.

  test('the Android launch background is cream, in both light and dark', () {
    // BOTH files. drawable-v21/ is the one that wins at minSdk 24, so a fix
    // applied only to drawable/ would look right in the diff and change nothing
    // on any real device.
    for (final path in const [
      '$_androidRes/drawable/launch_background.xml',
      '$_androidRes/drawable-v21/launch_background.xml',
    ]) {
      // Comments stripped first. These files explain in prose what the template
      // got wrong, which means they legitimately CONTAIN the strings this test
      // forbids — assert against the markup, not the commentary.
      final xml = File(path)
          .readAsStringSync()
          .replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');

      expect(xml, contains('@color/nimit_cream'),
          reason: '$path must paint the cream field. The template used '
              '@android:color/white here and the system window colour in the '
              'v21 variant — the latter resolves to BLACK in dark mode.');
      expect(xml, isNot(contains('?android:colorBackground')),
          reason: '$path must not defer to the system window colour: it is '
              'white in light mode and black in dark, and neither is cream');
      expect(xml, isNot(contains('@android:color/white')),
          reason: '$path must not paint white — that is the flash this fixes');

      // The mark has to be uncommented. The template ships it inside <!-- -->,
      // which is a file that reads as done and renders as a bare colour.
      expect(RegExp(r'<bitmap\s').hasMatch(xml), isTrue,
          reason: '$path has no live <bitmap> — if the mark is still inside the '
              'template comment block, the splash is a plain cream rectangle');
      expect(xml, contains('@drawable/launch_image'));
    }
  });

  test('the Android cream matches NimitColors.cream exactly', () {
    // colors.xml duplicates the palette because resource XML cannot import Dart.
    // Duplicated values drift; this is the test that makes the drift loud.
    final xml = File('$_androidRes/values/colors.xml').readAsStringSync();
    final match =
        RegExp(r'name="nimit_cream">#([0-9A-Fa-f]{8})<').firstMatch(xml);
    expect(match, isNotNull,
        reason: 'nimit_cream missing from values/colors.xml, or no longer '
            'written as #AARRGGBB');

    final argb = int.parse(match!.group(1)!, radix: 16);
    expect(argb, NimitColors.cream.toARGB32(),
        reason: 'Android cream must equal NimitColors.cream (0xFFF6F0E4)');
  });

  test('the launcher name is นิมิต, not the project slug', () {
    // android:label was "nimit" — lowercase Latin, straight from `flutter
    // create`. On a Thai phone that is the one word the user cannot read, in the
    // one place they always see it.
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:label="@string/app_name"'));
    expect(manifest, isNot(contains('android:label="nimit"')));

    final strings =
        File('$_androidRes/values/strings.xml').readAsStringSync();
    expect(strings, contains('<string name="app_name">นิมิต</string>'),
        reason: 'the default app_name must be Thai — a values/ default of '
            '"Nimit" would show Latin on any device set to another language');
  });

  test('the release manifest declares INTERNET', () {
    // THE ONE THAT SHIPS A BROKEN APP. Flutter declares INTERNET only in
    // src/debug/, for hot reload. Release builds do not merge it, so every
    // Supabase call fails in the AAB while `flutter run` works perfectly.
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest,
        contains('<uses-permission android:name="android.permission.INTERNET"/>'),
        reason: 'without INTERNET in the MAIN manifest the Play build has no '
            'network: คลังตำรา search, symbol stories and ตรวจหวย results all '
            'fail silently, with no crash to point at the cause');
  });

  test('every Android density bucket has a real launch image', () {
    // A missing bucket is not an error — Android upscales the next one down,
    // which shows as a soft mark on exactly the cheap hardware this app targets.
    const buckets = <String, int>{
      'drawable-mdpi': 240,
      'drawable-hdpi': 360,
      'drawable-xhdpi': 480,
      'drawable-xxhdpi': 720,
      'drawable-xxxhdpi': 960,
    };

    buckets.forEach((dir, size) {
      final file = File('$_androidRes/$dir/launch_image.png');
      expect(file.existsSync(), isTrue,
          reason: '$dir/launch_image.png is missing — regenerate with: '
              'flutter test tool/generate_launch_images.dart');

      final bytes = file.readAsBytesSync();
      expect(bytes.sublist(0, 8),
          [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
          reason: '$dir/launch_image.png is not a PNG');
      expect(bytes[25], 2,
          reason: '$dir/launch_image.png must be truecolour with no alpha, so '
              'its cream field matches @color/nimit_cream exactly');

      // Painted at this density, not resampled from another one.
      final data = ByteData.sublistView(bytes);
      expect(data.getUint32(16), size, reason: '$dir width');
      expect(data.getUint32(20), size, reason: '$dir height');
    });
  });
}
