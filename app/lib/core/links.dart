/// The two URLs App Store Connect will not accept a submission without.
///
/// They live here, as constants, because the alternative is two string
/// literals buried in a widget — and these change when the pages move, which
/// they will. One file, one edit, and `test/store_links_test.dart` checks the
/// result before a build can ship.
///
/// THEY ARE NOT DECORATION. Reviewers open the privacy link from inside the
/// app; a dead one is a rejection, and a build that carries a dead one to
/// TestFlight has already shown it to real testers. So the test refuses to
/// pass while either is still the placeholder below. That is deliberate: the
/// suite going red is the reminder, and Codemagic runs the suite.
///
/// Both were published on Google Sites 2026-07-29. The words on them are kept
/// in `docs/store/privacy.md` and `docs/store/support.md` — edit those, then
/// re-paste from the matching `-page.html`, so the published page and the
/// repository cannot quietly disagree about what the app promises.
abstract final class NimitLinks {
  /// นโยบายความเป็นส่วนตัว.
  static const privacy = 'https://sites.google.com/view/nimitluck/privacy';

  /// ติดต่อ / ช่วยเหลือ.
  static const support = 'https://sites.google.com/view/nimitluck/support';

  /// Sentinel. Any URL equal to this fails the suite by design.
  static const _unpublished = 'https://example.invalid/not-published-yet';

  static bool get isPublished =>
      privacy != _unpublished && support != _unpublished;
}
