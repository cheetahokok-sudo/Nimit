import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nimit/core/router/app_router.dart';
import 'package:nimit/data/models/lottery.dart';
import 'package:nimit/data/providers.dart';
import 'package:nimit/data/repositories/repositories.dart';
import 'package:nimit/features/lottery/lottery_widgets.dart';
import 'package:nimit/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    // No network in tests: fall back to bundled default fonts.
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  /// [lottery] lets a test supply a specific draw WITHOUT changing the defaults
  /// in providers.dart — those must stay on mocks so `flutter test` needs no
  /// network and the CI gate keeps its meaning.
  ///
  /// Typed as the repository rather than a list of overrides because riverpod's
  /// `Override` is not exported by flutter_riverpod, and adding a dependency to
  /// name a type in a test would be a poor trade.
  Future<void> pumpApp(WidgetTester tester,
      {LotteryRepository? lottery}) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          if (lottery != null)
            lotteryRepositoryProvider.overrideWithValue(lottery),
        ],
        child: const NimitApp(),
      ),
    );
    await tester.pumpAndSettle();
    // appRouter is a process-global, so navigation state LEAKS between tests:
    // a test that ends on /dream/result would silently start the next test
    // there. Every test begins at home, explicitly.
    appRouter.go('/home');
    await tester.pumpAndSettle();
  }

  testWidgets('app boots to home with 5-tab navigation', (tester) async {
    await pumpApp(tester);

    // Brand + home headline
    expect(find.text('นิมิต'), findsOneWidget);
    expect(find.textContaining('คืนนี้ความฝัน'), findsOneWidget);

    // 5 tabs from the UI board
    for (final label in ['หน้าแรก', 'ความฝัน', 'กระแส', 'ดวง', 'ตรวจหวย']) {
      expect(find.text(label), findsWidgets);
    }
  });

  testWidgets('renders without overflow at narrow phone width',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    expect(find.text('นิมิต'), findsOneWidget);
    // Any RenderFlex overflow would surface as a FlutterError here.
    expect(tester.takeException(), isNull);
  });

  testWidgets('saving a dream persists the REAL text and analysis snapshot',
      (tester) async {
    // Regression test for a data-loss bug: the journal used to store the
    // analysis headline as the "dream text" and drop the analysis snapshot,
    // feeling and time-of-night entirely — destroying the only user-generated
    // data the app collects, silently, at the moment of saving.
    //
    // Tall viewport so the whole entry form is on screen; the default 600px
    // surface puts the analyze button under the bottom nav where taps miss.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpApp(tester);

    await tester.tap(find.text('ความฝัน'));
    await tester.pumpAndSettle();

    const dreamText = 'ฝันเห็นแมวดำนั่งบนหลังคาบ้าน';
    await tester.enterText(find.byType(TextField).first, dreamText);
    await tester.ensureVisible(find.text('สงบ'));
    await tester.tap(find.text('สงบ'));
    await tester.pump();
    await tester.ensureVisible(find.text('วิเคราะห์ความฝัน'));
    await tester.tap(find.text('วิเคราะห์ความฝัน'));
    await tester.pumpAndSettle();

    expect(find.text('คำแปลความฝัน'), findsOneWidget);
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();
    expect(find.text('บันทึกแล้ว'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    final stored = jsonDecode(prefs.getString('nimit.journal.v1')!) as List;
    final entry = stored.single as Map<String, dynamic>;

    expect(entry['text'], dreamText,
        reason: 'the journal must hold the dream the user wrote, '
            'not the analysis headline');
    expect(entry['feelingTh'], 'สงบ');
    expect(entry['analysis'], isNotNull,
        reason: 'the snapshot of what the user was shown must be frozen');
    expect((entry['analysis'] as Map)['headlineTh'], isNotEmpty);
  });

  testWidgets('home quick-entry: typing and เริ่มวิเคราะห์ reaches results',
      (tester) async {
    // Regression: the home dream card used to be a decoration that looked
    // like an input; typing was impossible and the button only navigated.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpApp(tester);

    await tester.enterText(
        find.byType(TextField).first, 'ฝันเห็นนกสีขาวหน้าบ้าน');
    await tester.tap(find.text('เริ่มวิเคราะห์'));
    await tester.pumpAndSettle();

    expect(find.text('คำแปลความฝัน'), findsOneWidget);
    // ภาษาชาวบ้านก่อนตำรา: the plain-summary card renders before the
    // scholarly citations, because the audience reads two lines, not prose.
    expect(find.text('แปลง่าย ๆ ได้ใจความ'), findsOneWidget);
    expect(find.text('อ้างอิงตำรา'), findsOneWidget);
  });

  testWidgets('home quick-entry: empty field falls through to the full form',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpApp(tester);

    await tester.tap(find.text('เริ่มวิเคราะห์'));
    await tester.pumpAndSettle();

    expect(find.text('เล่าความฝัน'), findsOneWidget);
    expect(find.text('คุณรู้สึกอย่างไรในฝัน?'), findsOneWidget);
  });

  testWidgets('all tabs navigate', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('ความฝัน'));
    await tester.pumpAndSettle();
    expect(find.text('เล่าความฝัน'), findsOneWidget);

    await tester.tap(find.text('กระแส'));
    await tester.pumpAndSettle();
    expect(find.text('กระแสปีนี้'), findsOneWidget);

    await tester.tap(find.text('ดวง'));
    await tester.pumpAndSettle();
    expect(find.text('ดวงของฉัน'), findsOneWidget);

    await tester.tap(find.text('ตรวจหวย'));
    await tester.pumpAndSettle();
    expect(find.text('ตรวจหวยรัฐบาล'), findsOneWidget);
  });

  testWidgets('ดวงของฉัน asks for a birth date and invents nothing',
      (tester) async {
    // This screen used to render a ลัคนา, a badge claiming birth data was on
    // file, four 'เลขประจำดวง' and a line of money advice — all constants in a
    // mock. The absence assertions below fail the moment any of it returns.
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await pumpApp(tester);
    appRouter.go('/fortune');
    await tester.pumpAndSettle();

    expect(find.text('ดวงของฉัน'), findsOneWidget);
    expect(find.text('เก็บไว้ในเครื่องนี้เท่านั้น'), findsOneWidget);
    // The privacy card must name the field it actually stores. A date of birth
    // is more identifying than a month, so the copy may not soften it.
    expect(find.text('เก็บ: วันเดือนปีเกิด'), findsOneWidget);
    expect(find.text('วัน'), findsOneWidget);
    expect(find.text('เดือน'), findsOneWidget);
    expect(find.text('ปี พ.ศ.'), findsOneWidget);

    expect(find.textContaining('ลัคนา'), findsNothing);
    expect(find.textContaining('ข้อมูลเกิดครบ'), findsNothing);
    expect(find.textContaining('เลขประจำดวง'), findsNothing);

    // Nothing chosen yet, so no lunar date exists to be shown.
    expect(find.textContaining('ตรงกับวันทางจันทรคติ'), findsNothing);
  });

  testWidgets('a complete birth date shows a real lunar date, not a reading',
      (tester) async {
    tester.view.physicalSize = const Size(420, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Seeded rather than driven through three dropdowns: the storage migration
    // path is covered in local_repositories_test.dart, and what matters here is
    // what the screen renders for a known date.
    //
    // 29 ก.ค. 2569 is ขึ้น 15 ค่ำ เดือนแปดหลัง — วันอาสาฬหบูชา in an อธิกมาส
    // year, corroborated against published holiday records.
    SharedPreferences.setMockInitialValues(
        {'nimit.birth.v2': '{"date":"2026-07-29"}'});
    await pumpApp(tester);
    appRouter.go('/fortune');
    await tester.pumpAndSettle();

    expect(find.text('ขึ้น 15 ค่ำ เดือนแปดหลัง พ.ศ. 2569'), findsOneWidget);
    expect(find.text('อธิกมาส · ปกติวาร'), findsOneWidget);
    // เดือนแปดหลัง is the one thing a user cannot work out unaided.
    expect(find.textContaining('ไม่ใช่เดือนเก้า'), findsOneWidget);

    // A calendar conversion is shown; a prediction is not.
    expect(find.text('ยังไม่มีในคลังตำรา'), findsOneWidget);
    expect(find.text('ลบวันเกิดออกจากเครื่อง'), findsOneWidget);
  });

  testWidgets('a legacy month-only profile asks for the rest, not for nothing',
      (tester) async {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Users of the month-only build must not open the screen and find their
    // answer gone.
    SharedPreferences.setMockInitialValues(
        {'nimit.birthmonth.v1': '{"month":7}'});
    await pumpApp(tester);
    appRouter.go('/fortune');
    await tester.pumpAndSettle();

    expect(find.textContaining('เดิมคุณบอกไว้แค่เดือน กรกฎาคม'), findsOneWidget);
    // And no lunar date is claimed, because a month alone cannot produce one.
    expect(find.textContaining('ตรงกับวันทางจันทรคติ'), findsNothing);
  });

  testWidgets('the date picker survives a 360 px phone', (tester) async {
    // Three fields side by side on the cheapest handset this audience carries.
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    appRouter.go('/fortune');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('ปี พ.ศ.'), findsOneWidget);
  });


  testWidgets('กระแสปีนี้ shows real draws joined to ตำรา meaning',
      (tester) async {
    // The screen this replaced shipped invented "community mention" counts to
    // production with a caption claiming they came from public posts. Every
    // row here must be a draw that actually happened.
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester, lottery: _FixtureLotteryRepository.announced());
    await tester.tap(find.text('กระแส'));
    await tester.pumpAndSettle();

    expect(find.text('กระแสปีนี้'), findsOneWidget);
    // The drawn number and the symbol ตำรา tie to it appear together.
    expect(find.text('71'), findsWidgets);
    expect(find.text('ปลาเงินปลาทอง'), findsOneWidget);

    // None of the fabricated copy may survive anywhere on this screen.
    for (final ghost in [
      'สัญลักษณ์มาแรง',
      'เลขที่ถูกพูดถึง',
      'ข้อมูลจากโพสต์สาธารณะและการค้นหาในแอป',
    ]) {
      expect(find.text(ghost), findsNothing, reason: 'stale mock copy: $ghost');
    }
    expect(tester.takeException(), isNull);
  });

  group('ตรวจหวย renders money and withholds verdicts correctly', () {
    testWidgets('a winning saved number shows a formatted baht amount',
        (tester) async {
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({
        'nimit.tickets.v1': jsonEncode([
          {
            'number': '639214',
            'savedAt': '2026-07-16T09:00:00.000',
            'quantity': 2,
          }
        ]),
      });

      await pumpApp(tester, lottery: _FixtureLotteryRepository.announced());
      await tester.tap(find.text('ตรวจหวย'));
      await tester.pumpAndSettle();

      expect(find.text('ถูกรางวัล!'), findsOneWidget);
      // Separators matter: a bare 12000000 is unreadable at a glance to the
      // audience this screen is for.
      expect(find.text('฿12,000,000'), findsWidgets);
      expect(find.textContaining('ไม่ถูกรางวัล'), findsNothing);
    });

    testWidgets('prize tiers do not collide on a narrow phone', (tester) async {
      // Regression: the three secondary tiers were laid out as equal columns
      // in one Row, so at 400px each got ~110px and "เลขหน้า 683 709" ran into
      // "เลขท้าย 427 746", rendering as "709427". Two numbers from different
      // prizes reading as one number is the worst failure this screen has.
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpApp(tester, lottery: _FixtureLotteryRepository.announced());
      await tester.tap(find.text('ตรวจหวย'));
      await tester.pumpAndSettle();

      // No RenderFlex overflow anywhere on the screen.
      expect(tester.takeException(), isNull);

      // Each tier is its own labelled row, and the labels are all present.
      for (final label in ['เลขท้าย 2 ตัว', 'เลขหน้า 3 ตัว', 'เลขท้าย 3 ตัว']) {
        expect(find.text(label), findsOneWidget, reason: 'missing $label');
      }

      // The structural guard, and the one that actually holds. The old bug was
      // VISUAL — three Expanded columns each ~110px wide, so the numbers were
      // always separate Text widgets but rendered flush against each other.
      // Asserting on the text alone would pass for both layouts; asserting the
      // layout is three PrizeRows is what stops the columns coming back.
      expect(find.byType(PrizeRow), findsNWidgets(3),
          reason: 'secondary tiers must be labelled rows, not squeezed columns');

      // And each tier keeps its own numbers, with a wide separator.
      final rows = tester.widgetList<PrizeRow>(find.byType(PrizeRow)).toList();
      expect(rows.map((r) => r.numbers.join(',')),
          containsAll(['71', '683,709', '427,746']));
    });

    testWidgets('a PARTIAL draw never renders ไม่ถูกรางวัล', (tester) async {
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({
        'nimit.tickets.v1': jsonEncode([
          {'number': '111111', 'savedAt': '2026-07-16T09:00:00.000'}
        ]),
      });

      await pumpApp(tester, lottery: _FixtureLotteryRepository.partial());
      await tester.tap(find.text('ตรวจหวย'));
      await tester.pumpAndSettle();

      // The number is listed, but the app must not claim it lost — the draw
      // is only half announced and 4th/5th prize have not been published.
      expect(find.text('111111'), findsOneWidget);
      expect(find.textContaining('ไม่ถูกรางวัล'), findsNothing);
      expect(find.text('ผลยังไม่ครบ'), findsWidgets);
    });

    testWidgets('a losing number on a complete draw does say ไม่ถูกรางวัล',
        (tester) async {
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({
        'nimit.tickets.v1': jsonEncode([
          {'number': '111111', 'savedAt': '2026-07-16T09:00:00.000'}
        ]),
      });

      await pumpApp(tester, lottery: _FixtureLotteryRepository.announced());
      await tester.tap(find.text('ตรวจหวย'));
      await tester.pumpAndSettle();

      expect(find.text('ไม่ถูกรางวัล'), findsOneWidget);
    });
  });
}

/// A draw fixture with a real prize structure, injected per test.
///
/// Deliberately separate from MockLotteryRepository: the mock is the demo the
/// public build shows and its numbers are chosen NOT to win, whereas these
/// tests need a controlled winner.
class _FixtureLotteryRepository implements LotteryRepository {
  _FixtureLotteryRepository({required this.status, required this.complete});

  factory _FixtureLotteryRepository.announced() =>
      _FixtureLotteryRepository(status: DrawStatus.announced, complete: true);

  factory _FixtureLotteryRepository.partial() =>
      _FixtureLotteryRepository(status: DrawStatus.partial, complete: false);

  final DrawStatus status;
  final bool complete;

  DrawResult _draw() => DrawResult(
        drawDate: DateTime(2026, 7, 16),
        periodLabelTh: 'งวดวันที่ 16 กรกฎาคม 2569',
        status: status,
        resultRevision: 0,
        complete: complete,
        hasUnreadableTier: false,
        dutyRate: 0.005,
        prizes: [
          const PrizeTierResult(
            code: 'first',
            nameTh: 'รางวัลที่ 1',
            shortNameTh: 'ที่ 1',
            amountThb: 6000000,
            winnerCount: 1,
            matchKind: MatchKind.exact6,
            sort: 10,
            numbers: ['639214'],
          ),
          // The real งวด 16 ก.ค. 2569 values — these are the exact numbers that
          // collided as "709427" in the three-column layout.
          const PrizeTierResult(
            code: 'front3',
            nameTh: 'รางวัลเลขหน้า 3 ตัว',
            shortNameTh: 'หน้า 3 ตัว',
            amountThb: 4000,
            winnerCount: 2,
            matchKind: MatchKind.prefix3,
            sort: 70,
            numbers: ['683', '709'],
          ),
          const PrizeTierResult(
            code: 'last3',
            nameTh: 'รางวัลเลขท้าย 3 ตัว',
            shortNameTh: 'ท้าย 3 ตัว',
            amountThb: 4000,
            winnerCount: 2,
            matchKind: MatchKind.suffix3,
            sort: 80,
            numbers: ['427', '746'],
          ),
          const PrizeTierResult(
            code: 'last2',
            nameTh: 'รางวัลเลขท้าย 2 ตัว',
            shortNameTh: 'ท้าย 2 ตัว',
            amountThb: 2000,
            winnerCount: 1,
            matchKind: MatchKind.suffix2,
            sort: 90,
            numbers: ['71'],
          ),
        ],
        sourceCustodianTh: 'สำนักงานสลากกินแบ่งรัฐบาล',
      );

  @override
  Future<DrawInfo> currentDraw() async => DrawInfo(
        drawDate: DateTime(2026, 8, 1),
        statusTh: 'รอประกาศ',
        status: DrawStatus.scheduled,
      );

  @override
  Future<DrawResult> latestDraw() async => _draw();

  @override
  Future<List<DrawResult>> recentDraws({int limit = 12}) async => [_draw()];

  @override
  Future<YearTrends> yearTrends({int windowDraws = 24}) async => const
      YearTrends(
    windowDraws: 1,
    coveredByLibrary: 1,
    drawn: [
      DrawnNumber(number: '71', times: 1, symbols: [
        NumberSymbol(slug: 'goldfish', nameTh: 'ปลาเงินปลาทอง'),
      ]),
    ],
    noteTh: 'ทดสอบ',
  );

  @override
  Future<List<DrawSummary>> history({int limit = 48}) async => [
        DrawSummary(
          drawDate: DateTime(2026, 7, 16),
          labelTh: '16 กรกฎาคม 2569',
          yearBe: 2569,
          firstPrize: '639214',
          last2: '71',
        ),
      ];

  @override
  Future<DrawResult> drawFor(DateTime date) async => _draw();

  @override
  Future<DigitStats> digitStats({int windowDraws = 24}) async => const
      DigitStats(
    windowDraws: 1,
    last2: [],
    positionDigits: [],
    neverSeenLast2: 100,
    noteTh: 'ทดสอบ',
  );
}
