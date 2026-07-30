// codemagic.yaml, held to the things that break a release AFTER you tag.
//
// A CI config has the worst feedback loop in the repository: it is only exercised
// by pushing a tag, a tag is a deliberate release, and a typo in it costs a build
// and a version number rather than a red suite. The iOS workflow cost six builds
// to a problem that was never in this file at all — the least this suite can do is
// catch the ones that ARE.
//
// So these tests assert structure and the specific mistakes that are easy to make
// and expensive to discover:
//
//   * a workflow that would build without the backend guard, i.e. ship a fixture
//     draw on a money screen;
//   * an Android release with no keystore, which builds for ten minutes and then
//     produces something Play refuses;
//   * tag patterns that overlap, so releasing to one store releases to both.
//
// NOT ASSERTED: anything about the Codemagic account. Variable groups, keystores
// and signing identities live in their UI, and nothing here can see them. This
// file checks that the config ASKS for them correctly.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  final yaml = loadYaml(File('../codemagic.yaml').readAsStringSync()) as Map;
  final workflows = yaml['workflows'] as Map;

  test('codemagic.yaml parses and defines both store workflows', () {
    expect(workflows.keys, containsAll(['ios-testflight', 'android-play']));
  });

  group('every workflow', () {
    for (final name in ['ios-testflight', 'android-play']) {
      final wf = workflows[name] as Map;
      final scripts = (wf['scripts'] as List).cast<Map>();
      final names = scripts.map((s) => s['name'] as String).toList();
      final bodies = scripts.map((s) => s['script'] as String).join('\n');

      test('$name refuses a mock-data binary before it builds', () {
        // The one non-negotiable in the file. Without it a release can ship
        // MockLotteryRepository — a fixture draw, labelled (ตัวอย่าง), on a
        // screen people check for money.
        expect(names.any((n) => n.contains('refuse a mock-data store binary')),
            isTrue,
            reason: '$name has no backend guard step');
        expect(bodies, contains(r'$NIMIT_REMOTE'));
        expect(bodies, contains(r'SUPABASE_ANON_KEY'));

        // The guard must come before the build, or it guards nothing.
        final guard =
            names.indexWhere((n) => n.contains('refuse a mock-data'));
        final build = names.indexWhere((n) => n.startsWith('Build'));
        expect(build, greaterThan(guard),
            reason: 'in $name the build runs before the guard');
      });

      test('$name gates the build on analyze and test', () {
        final gate = names.indexWhere((n) => n == 'Analyze and test');
        final build = names.indexWhere((n) => n.startsWith('Build'));
        expect(gate, isNot(-1), reason: '$name never runs the suite');
        expect(build, greaterThan(gate),
            reason: 'in $name the build runs before the suite');
        expect(bodies, contains('flutter analyze'));
        expect(bodies, contains('flutter test'));
      });

      test('$name passes the backend through to the binary', () {
        // Guarding that the variables EXIST is useless if the build then
        // forgets to compile them in: the app would pass the guard and still
        // fall back to mocks at runtime.
        for (final define in const [
          '--dart-define=NIMIT_REMOTE=',
          '--dart-define=SUPABASE_URL=',
          '--dart-define=SUPABASE_ANON_KEY=',
        ]) {
          expect(bodies, contains(define),
              reason: '$name builds without $define, so the shipped binary '
                  'uses mock repositories no matter what the guard checked');
        }
      });

      test('$name asks for the backend variable group', () {
        expect((wf['environment'] as Map)['groups'], contains('nimit_backend'));
      });

      test('$name pins Flutter rather than tracking a channel', () {
        // A floating `stable` silently changes the toolchain under a release.
        expect((wf['environment'] as Map)['flutter'], '3.44.2');
      });
    }
  });

  test('the two workflows cannot be triggered by the same tag', () {
    // ios-v* and android-v* are separate namespaces on purpose. If both ever
    // matched a shared prefix, one `git tag` would spend a build on each store
    // and burn two version numbers.
    List<String> patternsOf(String name) => (((workflows[name] as Map)
                ['triggering'] as Map)['tag_patterns'] as List)
        .cast<Map>()
        .map((p) => p['pattern'] as String)
        .toList();

    final ios = patternsOf('ios-testflight');
    final android = patternsOf('android-play');

    expect(ios, ['ios-v*']);
    expect(android, ['android-v*']);

    // Cheap overlap check against a real tag from each namespace.
    bool matches(String pattern, String tag) =>
        RegExp('^${RegExp.escape(pattern).replaceAll(r'\*', '.*')}\$')
            .hasMatch(tag);

    expect(android.any((p) => matches(p, 'ios-v1.0.0')), isFalse);
    expect(ios.any((p) => matches(p, 'android-v1.0.0')), isFalse);
  });

  group('android-play', () {
    final wf = workflows['android-play'] as Map;
    final env = wf['environment'] as Map;
    final scripts = (wf['scripts'] as List).cast<Map>();
    final names = scripts.map((s) => s['name'] as String).toList();
    final bodies = scripts.map((s) => s['script'] as String).join('\n');

    test('refuses to start a release it cannot sign', () {
      // The template signed release builds with the DEBUG keystore. Play refuses
      // those on upload — after a full build. This guard turns a ten-minute
      // failure into an immediate one.
      expect(names.any((n) => n.contains('refuse an unsignable release')),
          isTrue);
      expect(bodies, contains(r'$CM_KEYSTORE_PATH'));
      expect(env['android_signing'], contains('nimit-upload-keystore'));
    });

    test('writes key.properties where Gradle actually reads it', () {
      // rootProject for the Flutter Android build is app/android, so
      // rootProject.file("key.properties") resolves to app/android/key.properties
      // and nowhere else. A path typo here fails as a null storeFile.
      expect(bodies, contains('app/android/key.properties'));
      for (final key in const [
        'storeFile=',
        'storePassword=',
        'keyAlias=',
        'keyPassword=',
      ]) {
        expect(bodies, contains(key));
      }

      // Written after the suite passes, so a red build never touches signing
      // material.
      final gate = names.indexWhere((n) => n == 'Analyze and test');
      final write = names.indexWhere((n) => n.contains('key.properties'));
      expect(write, greaterThan(gate));
    });

    test('builds an app bundle, not a universal APK', () {
      // Play requires an AAB for new apps, and a universal APK would ship every
      // ABI and density to every phone — real cost on metered data and 32 GB
      // devices, which is this app's audience.
      expect(bodies, contains('flutter build appbundle --release'));
      expect(bodies, isNot(contains('flutter build apk')));
      expect((wf['artifacts'] as List).join(' '), contains('.aab'));
    });

    test('keeps the symbols needed to read a release crash', () {
      final artifacts = (wf['artifacts'] as List).join(' ');
      expect(artifacts, contains('mapping.txt'),
          reason: 'without mapping.txt a Play Console crash report from a '
              'release build is unreadable addresses');
      expect(artifacts, contains('.so'));
    });

    test('does not publish to Play automatically', () {
      // Deliberate, not unfinished: a new listing's first release goes through
      // the Console, and a personal account created after Nov 2023 must run a
      // 12-tester closed test for 14 days before production access exists. An
      // enabled publishing block would just fail every build.
      expect(wf.containsKey('publishing'), isFalse);
    });

    test('runs on Linux, because an Android build needs no Apple toolchain', () {
      expect(wf['instance_type'], startsWith('linux'));
    });
  });
}
