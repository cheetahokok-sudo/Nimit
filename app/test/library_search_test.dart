import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nimit/core/router/app_router.dart';
import 'package:nimit/data/models/library.dart';
import 'package:nimit/data/providers.dart';
import 'package:nimit/data/repositories/repositories.dart';
import 'package:nimit/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// คลังตำรา search — the screen behind เปิดคลังตำรา.
///
/// The three things worth pinning down are the three places the screen could
/// quietly mislead: a query too short to be legal reaching the network anyway,
/// an empty library rendering as though nothing were wrong, and a fuzzy match
/// presented as a hit. Each has its own test.
void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  /// Records every query it is asked for, so a test can assert the ABSENCE of
  /// a round trip — the short-query guard is only worth having if it stops the
  /// request rather than merely hiding the result.
  Future<void> pumpSearch(WidgetTester tester, _RecordingLibrary library) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        // The same policy main() installs — a test that saw failures faster
        // than the app does would be testing a different app.
        retry: nimitRetry,
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          libraryRepositoryProvider.overrideWithValue(library),
        ],
        child: const NimitApp(),
      ),
    );
    await tester.pumpAndSettle();
    // appRouter is a process-global; start every test from a known place.
    appRouter.go('/library');
    await tester.pumpAndSettle();
  }

  /// Types [text] and lets the 350ms debounce fire, then drains the future.
  /// Deliberately not pumpAndSettle: the loading state is a
  /// CircularProgressIndicator, whose animation never settles.
  Future<void> typeAndSettle(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump(const Duration(milliseconds: 400));
    for (var i = 0; i < 4; i++) {
      await tester.pump();
    }
  }

  testWidgets('a one-character query is guided, not sent', (tester) async {
    final library = _RecordingLibrary();
    await pumpSearch(tester, library);

    await typeAndSettle(tester, 'น');

    expect(find.textContaining('พิมพ์อย่างน้อยสองตัวอักษร'), findsOneWidget);
    // The server rejects a one-character query with an exception. A guard that
    // let the request through would turn guidance into a failed round trip.
    expect(library.queries, isEmpty);
  });

  testWidgets('a word the library does not hold says so', (tester) async {
    final library = _RecordingLibrary(results: const []);
    await pumpSearch(tester, library);

    await typeAndSettle(tester, 'มังกร');

    expect(library.queries, ['มังกร']);
    expect(find.textContaining('ยังไม่พบ'), findsOneWidget);
    // The gap is an editorial queue, and the screen must not invent a meaning
    // to fill it.
    expect(find.textContaining('จะไม่แต่งความหมายขึ้นเอง'), findsOneWidget);
  });

  testWidgets('an exact hit renders without a near-miss notice',
      (tester) async {
    final library = _RecordingLibrary(results: const [
      SymbolSearchResult(
        slug: 'bird',
        nameTh: 'นก',
        category: 'สัญลักษณ์ในความฝัน',
        teaserTh: 'ตำราว่านกบินเข้าบ้านเป็นข่าวดี',
        matchKind: 'exact',
      ),
    ]);
    await pumpSearch(tester, library);

    await typeAndSettle(tester, 'นก');

    expect(find.text('นก'), findsWidgets);
    expect(find.textContaining('ตำราว่านกบินเข้าบ้าน'), findsOneWidget);
    expect(find.textContaining('ไม่พบคำนี้ตรงตัว'), findsNothing);
  });

  testWidgets('a fuzzy result is labelled a near-miss', (tester) async {
    final library = _RecordingLibrary(results: const [
      SymbolSearchResult(
        slug: 'bird',
        nameTh: 'นก',
        category: 'สัญลักษณ์ในความฝัน',
        teaserTh: 'ตำราว่านกบินเข้าบ้านเป็นข่าวดี',
        matchKind: 'fuzzy',
      ),
    ]);
    await pumpSearch(tester, library);

    await typeAndSettle(tester, 'นกก');

    // A near-miss presented as a match would be a small lie in an app whose
    // subject is not lying.
    expect(find.textContaining('ไม่พบคำนี้ตรงตัว'), findsOneWidget);
  });

  testWidgets('a failed search admits it instead of showing nothing',
      (tester) async {
    final library = _RecordingLibrary(fails: true);
    await pumpSearch(tester, library);

    await typeAndSettle(tester, 'นก');

    // The spinner is honest while nimitRetry is still retrying...
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // ...but the retries are bounded, and the screen must arrive at the truth.
    // Regression guard for Riverpod 3's default policy, under which this
    // branch stayed unreachable for about forty seconds.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    for (var i = 0; i < 4; i++) {
      await tester.pump();
    }

    // An error rendered as an empty library would tell the user the ตำรา do
    // not cover their word, which is a different and false statement.
    expect(find.textContaining('ค้นหาไม่สำเร็จ'), findsOneWidget);
    expect(find.textContaining('ยังไม่พบ'), findsNothing);
  });
}

class _RecordingLibrary implements LibraryRepository {
  _RecordingLibrary({this.results = const [], this.fails = false});

  final List<SymbolSearchResult> results;
  final bool fails;
  final List<String> queries = [];

  @override
  Future<List<SymbolSearchResult>> search(String query) async {
    queries.add(query);
    if (fails) throw Exception('search_symbols returned HTTP 500');
    return results;
  }

  @override
  Future<SymbolStory> story(String slug) =>
      throw UnimplementedError('not used by this test');

  @override
  Future<TaksaReading> taksa(int weekday) =>
      throw UnimplementedError('not used by this test');

  @override
  Future<AgeWheelReading> ageWheel(int age) =>
      throw UnimplementedError('not used by this test');

  @override
  Future<ZodiacYearReading> zodiacYear(int index, int? lunarMonth) =>
      throw UnimplementedError('not used by this test');
}
