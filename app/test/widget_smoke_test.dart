import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nimit/data/providers.dart';
import 'package:nimit/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    // No network in tests: fall back to bundled default fonts.
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpApp(WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const NimitApp(),
      ),
    );
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

  testWidgets('all tabs navigate', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('ความฝัน'));
    await tester.pumpAndSettle();
    expect(find.text('เล่าความฝัน'), findsOneWidget);

    await tester.tap(find.text('กระแส'));
    await tester.pumpAndSettle();
    expect(find.text('กระแสวันนี้'), findsOneWidget);

    await tester.tap(find.text('ดวง'));
    await tester.pumpAndSettle();
    expect(find.text('ดวงของฉัน'), findsOneWidget);

    await tester.tap(find.text('ตรวจหวย'));
    await tester.pumpAndSettle();
    expect(find.text('ตรวจหวยรัฐบาล'), findsOneWidget);
  });
}
