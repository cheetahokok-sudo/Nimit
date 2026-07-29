import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nimit/core/router/app_router.dart';
import 'package:nimit/data/models/library.dart';
import 'package:nimit/data/models/lottery.dart';
import 'package:nimit/data/providers.dart';
import 'package:nimit/data/repositories/repositories.dart';
import 'package:nimit/features/fortune/celestial_orb.dart';
import 'package:nimit/features/fortune/fortune_screen.dart' show completedYears;
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
      {LotteryRepository? lottery, LibraryRepository? library}) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          if (lottery != null)
            lotteryRepositoryProvider.overrideWithValue(lottery),
          if (library != null)
            libraryRepositoryProvider.overrideWithValue(library),
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
    expect(find.text('ข้อมูลเกิดครบแล้ว'), findsNothing,
        reason: 'no date stored yet, so the pill must not claim one');
    // The privacy card must name the field it actually stores. A date of birth
    // is more identifying than a month, so the copy may not soften it.
    expect(find.textContaining('เก็บวันเดือนปีเกิดไว้ในเครื่องนี้เท่านั้น'),
        findsOneWidget);
    expect(find.text('แตะเพื่อบอกวันเกิด'), findsOneWidget);

    expect(find.textContaining('ลัคนา'), findsNothing);
    expect(find.textContaining('ข้อมูลเกิดครบ'), findsNothing);
    expect(find.textContaining('เลขประจำดวง'), findsNothing);

    // Nothing chosen yet, so no lunar date exists to be shown.
    // No birth date stored, so no derived facts may be shown.
    expect(find.text('คำนวณจากวันเกิดของท่าน'), findsNothing);
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

    expect(find.text('ขึ้น ๑๕ ค่ำ เดือนแปดหลัง'), findsOneWidget);
    expect(find.text('อธิกมาส · ปกติวาร'), findsOneWidget);
    // The computed lookup keys a ตำรา reading is found by. These are no longer
    // only facts on a list: ปีนักษัตร now heads its own reading section too, so
    // the year name appears twice — once as the computed fact and once as the
    // subject of the reading it keys. Both are wanted; only one would mean a
    // section had silently stopped rendering.
    expect(find.text('วันพุธ'), findsOneWidget);
    expect(find.text('ปีมะเมีย'), findsNWidgets(2));
    // เดือนแปดหลัง is the one thing a user cannot work out unaided.
    expect(find.textContaining('ไม่ใช่เดือนเก้า'), findsOneWidget);

    // A calendar conversion is shown; a prediction is not.
    expect(find.text('ยังไม่มีตำราในคลังที่ทำนายจากวันเกิด'), findsOneWidget);
    expect(find.text('ลบ'), findsOneWidget);
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
    // No birth date stored, so no derived facts may be shown.
    expect(find.text('คำนวณจากวันเกิดของท่าน'), findsNothing);
  });

  testWidgets('a ทักษา reading renders with its citation', (tester) async {
    // The seeded readings are DRAFT — one copyrighted 1963 source, no second
    // witness — so the shipped app shows the empty state. This proves the
    // render path works the moment they are published, rather than leaving it
    // untested until the day it matters.
    tester.view.physicalSize = const Size(420, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // 29 ก.ค. 2569 is a Wednesday.
    SharedPreferences.setMockInitialValues(
        {'nimit.birth.v2': '{"date":"2026-07-29"}'});
    await pumpApp(tester, library: _StubLibrary());
    appRouter.go('/fortune');
    await tester.pumpAndSettle();

    // Summary and body are separately present, asserted on text unique to each.
    // Once in the hero subtitle, once in the reading card below it.
    expect(find.textContaining('ขยันและรู้งานรอบด้าน'), findsNWidgets(2));
    expect(find.textContaining('ให้นามประจำวันพุธว่า'), findsOneWidget);
    // A reading may never appear without a source line.
    // Matched on the ทักษา citation specifically, not on 'ที่มา: พรหมชาติ'
    // alone: วงราศีตามอายุ also cites พรหมชาติ and renders on this same screen,
    // so the loose match found two and proved nothing about either.
    expect(find.textContaining('ที่มา: พรหมชาติ · สุนันท์ วิโรภาส'),
        findsOneWidget);
    expect(find.textContaining('พ.ศ. 2506'), findsOneWidget);
    // And the empty state must be gone.
    expect(find.text('ยังไม่มีตำราในคลังที่ทำนายจากวันเกิด'), findsNothing);
  });

  // ── วงราศีตามอายุ ────────────────────────────────────────────────────────
  //
  // The wheel is the first reading in the app keyed on AGE rather than on a
  // birth date component, and the first that deliberately declines to ask the
  // user's sex: the ตำรา counts one way for men and the other for women, so
  // both results are fetched and both are shown. These tests hold that shape,
  // because the moment somebody "simplifies" it into one answer the app has
  // started guessing something personal about the reader.

  test('the age wheel counting rule matches the ตำรา', () {
    // อายุ ๑ starts on เจดีย์ for everyone; the directions separate after that.
    // Mirrors the SQL in api.agewheel_age — if these two ever disagree the
    // client and server are telling the user different years.
    int male(int age) => ((age - 1) % 12) + 1;
    int female(int age) => ((12 - ((age - 1) % 12)) % 12) + 1;

    expect(male(1), 1);
    expect(female(1), 1);
    expect(male(2), 2);
    expect(female(2), 12);
    expect(male(13), 1, reason: 'the wheel wraps every twelve years');
    expect(female(13), 1);
    for (var age = 1; age <= 150; age++) {
      expect(male(age), inInclusiveRange(1, 12));
      expect(female(age), inInclusiveRange(1, 12),
          reason: 'negative modulo must not push หญิง off the wheel');
    }
  });

  test('completedYears counts birthdays, not calendar years', () {
    final today = DateTime(2026, 7, 29);
    // Birthday already passed this year.
    expect(completedYears(DateTime(1990, 7, 28), today: today), 36);
    // Birthday is today — it counts.
    expect(completedYears(DateTime(1990, 7, 29), today: today), 36);
    // Birthday still ahead this year, so one fewer.
    expect(completedYears(DateTime(1990, 7, 30), today: today), 35);
    // Never negative, whatever the stored date says.
    expect(completedYears(DateTime(2030, 1, 1), today: today), 0);
  });

  testWidgets('ปีนักษัตร keeps the year reading and the month one apart',
      (tester) async {
    // In this ตำรา the เดือนเกิด group can invert the year's verdict — ปีชวด
    // born เดือน ๕–๗ is promised สติปัญญามาก and born เดือน ๘–๑๐ the opposite.
    // Merging the two into one undifferentiated stack would present a
    // refinement that applies to a quarter of people as the general case.
    tester.view.physicalSize = const Size(420, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues(
        {'nimit.birth.v2': '{"date":"2026-07-29"}'});
    await pumpApp(tester, library: _StubLibrary());
    appRouter.go('/fortune');
    await tester.pumpAndSettle();

    expect(find.text('คำทำนายตามปีนักษัตร'), findsOneWidget);
    // Each kind of reading is labelled as what it is.
    expect(find.text('คำทำนายประจำปีเกิด'), findsOneWidget);
    expect(find.text('คำทำนายย่อยตามเดือนเกิด'), findsOneWidget);
    // Both carry their own citation, and they are different pages.
    expect(find.textContaining('หน้า ๑๒–๑๓ คนเกิดปีชวด'), findsOneWidget);
    expect(find.textContaining('หน้า ๑๔–๑๕ ปีชวดแบ่งตามเดือนเกิด'),
        findsOneWidget);
    // With readings present the withheld notice must be gone.
    expect(find.textContaining('ยังไม่เผยแพร่คำทำนายตามปีนักษัตร'), findsNothing);
  });

  testWidgets('the age wheel shows both ชาย and หญิง, and withholds drafts',
      (tester) async {
    tester.view.physicalSize = const Size(420, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues(
        {'nimit.birth.v2': '{"date":"2026-07-29"}'});
    await pumpApp(tester, library: _StubLibrary());
    appRouter.go('/fortune');
    await tester.pumpAndSettle();

    // Both sides are labelled and named. Showing only one would mean the app
    // had silently decided the reader's sex.
    expect(find.textContaining('ถ้าเป็นชาย · ราหู'), findsOneWidget);
    expect(find.textContaining('ถ้าเป็นหญิง · เทวดาขี่เต่า'), findsOneWidget);

    // The published side renders its reading AND its source.
    expect(find.textContaining('ปีที่ตกราหูเป็นปีไม่ดี'), findsWidgets);
    expect(find.textContaining('ที่มา: พรหมชาติ · หน้า ๑–๓'), findsOneWidget);

    // The unpublished side says so plainly rather than showing nothing or,
    // worse, borrowing the other side's verdict.
    expect(find.textContaining('ต้องมีฉบับที่สองยืนยันก่อน'), findsOneWidget);

    // The age convention is stated, not left for the reader to assume.
    expect(find.textContaining('ปีเต็ม'), findsWidgets);
  });

  testWidgets('no published reading shows the honest empty state, not an error',
      (tester) async {
    tester.view.physicalSize = const Size(420, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // The default mock returns an empty reading list, which is the real
    // current state. It must read as "no source yet", never as a failure.
    SharedPreferences.setMockInitialValues(
        {'nimit.birth.v2': '{"date":"2026-07-29"}'});
    await pumpApp(tester);
    appRouter.go('/fortune');
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีตำราในคลังที่ทำนายจากวันเกิด'), findsOneWidget);
    expect(find.textContaining('ยังโหลดคำทำนายไม่ได้'), findsNothing);
  });

  // THE TEST THAT SHOULD HAVE EXISTED FIRST.
  //
  // The original width calculation forgot the card's left padding, so the
  // text column ran about 25 px under the graphic on a real phone. The 320 px
  // test passed anyway, because it only asserted "no overflow" — and text
  // drawn on top of a picture does not overflow anything. This compares the
  // painted rectangles instead, which is the property that was actually
  // claimed.
  //
  // One test per width rather than a loop inside one: re-pumping the whole app
  // several times in a single test body trips a Riverpod rebuild assertion,
  // and a harness problem masquerading as a layout failure wastes the next
  // person's afternoon.
  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    testWidgets('hero text never overlaps the orb at ${width.toInt()} px',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues(
          {'nimit.birth.v2': '{"date":"2026-07-29"}'});
      await pumpApp(tester);
      appRouter.go('/fortune');
      await tester.pumpAndSettle();

      final orb = tester.getRect(find.byType(CelestialOrb));
      // By KEY, not text. The headline renders DateTime.now()'s lunar month,
      // so finding it by 'เดือนแปดหลัง' worked only until 13 Aug 2026 — a test
      // with an expiry date, set to fail long after anyone remembers why.
      final rects = <String, Rect>{
        'headline': tester.getRect(find.byKey(const ValueKey('hero-month'))),
        'eyebrow': tester.getRect(find.text('วันนี้ทางจันทรคติ')),
      };

      for (final e in rects.entries) {
        expect(e.value.overlaps(orb), isFalse,
            reason: '${e.key} ${e.value} overlaps the orb $orb');
      }
    });
  }
  testWidgets('the hero card does not overflow at 320 px, orb and all',
      (tester) async {
    // The orbit motif occupies the right of the card, so the text column is
    // sized against it explicitly. This is the narrowest phone width worth
    // supporting; an earlier card on this screen shipped with colliding text,
    // and the fix has to be held in place by something other than good luck.
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(
        {'nimit.birth.v2': '{"date":"2026-07-29"}'});
    await pumpApp(tester);
    appRouter.go('/fortune');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(CelestialOrb), findsOneWidget);
    expect(find.text('ข้อมูลเกิดครบแล้ว'), findsOneWidget);
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
    expect(find.text('แตะเพื่อบอกวันเกิด'), findsOneWidget);
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

/// Serves one Wednesday reading so the populated render path is covered.
class _StubLibrary implements LibraryRepository {
  @override
  Future<TaksaReading> taksa(int weekday) async => const TaksaReading(
        slug: 'born-wednesday',
        nameTh: 'คนเกิดวันพุธ',
        weekday: 3,
        readings: [
          TaksaEntry(
            bodyTh: 'ตำราพรหมชาติให้นามประจำวันพุธว่า นามสุนัข ธาตุเถ้า',
            summaryTh: 'ตำราเก่าว่าคนเกิดวันพุธ นามสุนัข ธาตุเถ้า ขยันและรู้งานรอบด้าน',
            contextNoteTh: 'เป็นความเชื่อที่บันทึกไว้ในตำรา',
            sourceTh: 'พรหมชาติ · สุนันท์ วิโรภาส · พ.ศ. 2506 · หน้า ๑๔–๑๗ หมวดคนเกิดวัน',
          ),
        ],
      );

  /// Serves both sides of the wheel for age 30 with one published verdict on
  /// the ชาย side only, so the render covers a populated figure AND a figure
  /// whose readings are still withheld — which is the mixed state the screen
  /// will actually meet first.
  @override
  Future<AgeWheelReading> ageWheel(int age) async => const AgeWheelReading(
        age: 30,
        male: AgeWheelFigure(
          position: 6,
          slug: 'age-wheel-rahu',
          nameTh: 'ราหู',
          readings: [
            TaksaEntry(
              bodyTh: 'ตำราว่าปีที่ตกราหูเป็นปีไม่ดี ว่าจะเดือดร้อนใจ',
              summaryTh: 'ตำราว่าปีที่ตกราหูเป็นปีไม่ดี ใจไม่สงบ',
              contextNoteTh: 'เป็นความเชื่อตามตำรา ไม่ใช่คำแนะนำทางการแพทย์',
              sourceTh: 'พรหมชาติ · หน้า ๑–๓ หลักการทำนายตาม ๑๒ ราศี',
            ),
          ],
        ),
        female: AgeWheelFigure(
          position: 8,
          slug: 'age-wheel-deva-on-turtle',
          nameTh: 'เทวดาขี่เต่า',
          readings: [],
        ),
      );

  /// A year reading AND a month refinement, so the render proves the two are
  /// distinguishable. In this ตำรา the month can invert the year's verdict, so
  /// a screen that merged them would be telling the user something false.
  @override
  Future<ZodiacYearReading> zodiacYear(int index, int? lunarMonth) async =>
      const ZodiacYearReading(
        index: 0,
        lunarMonth: 6,
        slug: 'year-rat',
        nameTh: 'คนเกิดปีชวด',
        yearReadings: [
          TaksaEntry(
            bodyTh: 'ตำราจัดปีชวดเป็นธาตุน้ำ ชั้นมาเทวดาผู้ชาย',
            summaryTh: 'ตำราว่าคนปีชวด ธาตุน้ำ พูดตรงและทำตามใจตัว',
            contextNoteTh: 'เป็นความเชื่อตามตำรา',
            sourceTh: 'พรหมชาติ · หน้า ๑๒–๑๓ คนเกิดปีชวด',
          ),
        ],
        monthReadings: [
          TaksaEntry(
            bodyTh: 'ตำราจัดผู้เกิดปีชวด เดือน ๕–๗ เป็นหนูท้องขาว',
            summaryTh: 'ตำราว่าคนปีชวดที่เกิดเดือน ๕–๗ เป็นหนูท้องขาว ปัญญาดี',
            contextNoteTh: 'เป็นคำทำนายย่อยตามเดือนเกิด',
            sourceTh: 'พรหมชาติ · หน้า ๑๔–๑๕ ปีชวดแบ่งตามเดือนเกิด',
          ),
        ],
      );

  @override
  Future<SymbolStory> story(String slug) =>
      throw UnimplementedError('not used by this test');
}
