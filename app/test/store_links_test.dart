// The privacy and support URLs, held to being real before anything ships.
//
// This test is EXPECTED TO FAIL until both pages are published and their URLs
// are pasted into lib/core/links.dart. That is its job. Codemagic runs
// `flutter test` before it builds the IPA, so a red result here stops a binary
// with dead policy links from ever reaching TestFlight — the same shape of
// guard as the mock-data refusal in codemagic.yaml, for the same reason: the
// broken build must not be producible by accident, only refusable on purpose.
//
// App Store Connect will not accept a submission without a Privacy Policy URL,
// and a reviewer who taps the in-app link and lands on nothing does not file a
// question, they file a rejection.

import 'package:flutter_test/flutter_test.dart';
import 'package:nimit/core/links.dart';

void main() {
  test('the policy pages are published', () {
    expect(
      NimitLinks.isPublished,
      isTrue,
      reason: 'Publish the privacy and support pages (copy is ready in '
          'docs/store/), then paste their URLs into lib/core/links.dart. '
          'Until then this app cannot be submitted, so it does not build.',
    );
  });

  test('both links are absolute https URLs', () {
    for (final url in [NimitLinks.privacy, NimitLinks.support]) {
      final uri = Uri.tryParse(url);
      expect(uri, isNotNull, reason: '$url is not a URL');
      // https only: iOS blocks cleartext http by default, so an http link
      // would fail on the device and nowhere else.
      expect(uri!.scheme, 'https', reason: '$url must be https');
      expect(uri.host, isNotEmpty, reason: '$url has no host');
    }
  });
}
