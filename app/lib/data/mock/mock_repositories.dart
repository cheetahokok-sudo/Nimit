import '../../core/utils/thai_date.dart';
import '../models/dream.dart';
import '../models/library.dart';
import '../models/lottery.dart';
import '../models/source.dart';
import '../repositories/repositories.dart';

/// Seeded with the exact content of the v2 UI board so the scaffold demos
/// the real product story (white-bird dream) end to end.

const _latency = Duration(milliseconds: 450);

class MockDreamRepository implements DreamRepository {
  @override
  Future<DreamAnalysis> analyze(
    String text, {
    String? feelingTh,
    String? timeOfNightTh,
  }) async {
    await Future<void>.delayed(_latency);
    // Demo uses a WHITE BIRD, not a snake: sample content is fed to everyone,
    // and snakes are unwelcome to many users.
    return const DreamAnalysis(
      headlineTh: 'นกสีขาว • หน้าบ้าน • ฝนเบา',
      themeTh: 'ข่าวดีที่กำลังเดินทางมาอย่างเงียบ ๆ',
      symbols: [
        DreamSymbol(nameTh: 'นก', count: 3),
        DreamSymbol(nameTh: 'สีขาว', count: 1),
        DreamSymbol(nameTh: 'บ้าน', count: 2),
        DreamSymbol(nameTh: 'ฝน', count: 1),
      ],
      interpretations: [
        SymbolInterpretation(
          tier: SourceTier.a1,
          sourceNameTh: 'ตำราโบราณที่ตรวจสอบได้',
          symbolTh: 'นก',
          summaryPlainTh:
              'ตำราว่า นกบินเข้าหาบ้านคือข่าวหรือผู้มาเยือนกำลังจะมาถึง '
              'ถ้านกดูสงบไม่ตื่นตกใจ มักเป็นเรื่องดีมากกว่าเรื่องร้าย',
          textTh:
              'การเห็นนกบินเข้ามาใกล้เรือน มักถูกตีความว่าจะมีข่าวสารหรือผู้มาเยือน '
              'เข้ามาเกี่ยวข้องกับครอบครัว',
        ),
        SymbolInterpretation(
          tier: SourceTier.b2,
          sourceNameTh: 'หนังสือพิมพ์เผยแพร่ทั่วไป',
          symbolTh: 'สีขาว',
          summaryPlainTh:
              'สีขาวเป็นสีของความสงบและการเริ่มต้นใหม่ '
              'ฝันที่มีสีขาวเด่นมักถูกมองว่าเป็นนิมิตทางดี',
          textTh:
              'สีขาวมักเชื่อมโยงกับความสงบ ผู้ใหญ่ หรือการเริ่มต้นใหม่',
        ),
      ],
      numbers: ['16', '61', '29', '269'],
      sourceCount: 3,
    );
  }

}

/// Demo draw used before a Supabase connection is configured.
///
/// Two deliberate properties, both of which have bitten this kind of fixture
/// before:
///
///  * the date is FIXED, not derived from `DateTime.now()`, so widget tests do
///    not drift with the calendar;
///  * the numbers are chosen NOT to win against anything the app demonstrates.
///    This fixture is what every user sees until remote is enabled, and a demo
///    that congratulates a stranger on six million baht is a support incident.
///    Stacking fixtures belong in lottery_checker_test.dart, as literals.
class MockLotteryRepository implements LotteryRepository {
  static final _drawDate = DateTime(2026, 8, 1);

  @override
  Future<DrawInfo> currentDraw() async {
    await Future<void>.delayed(_latency);
    return DrawInfo(
      drawDate: nextDrawDate(DateTime.now()),
      statusTh: 'รอประกาศจากสำนักงานสลากกินแบ่งรัฐบาล',
      status: DrawStatus.scheduled,
      estimated: true,
    );
  }

  @override
  Future<DrawResult> latestDraw() async {
    await Future<void>.delayed(_latency);
    return _demoDraw();
  }

  @override
  Future<List<DrawResult>> recentDraws({int limit = 12}) async {
    await Future<void>.delayed(_latency);
    return [_demoDraw()];
  }

  @override
  Future<List<DrawSummary>> history({int limit = 48}) async {
    await Future<void>.delayed(_latency);
    return [
      DrawSummary(
        drawDate: _drawDate,
        labelTh: '1 สิงหาคม 2569',
        yearBe: 2569,
        firstPrize: '482913',
        last2: '47',
        complete: false,
      ),
    ];
  }

  @override
  Future<DrawResult> drawFor(DateTime date) async {
    await Future<void>.delayed(_latency);
    return _demoDraw();
  }

  @override
  Future<YearTrends> yearTrends({int windowDraws = 24}) async {
    await Future<void>.delayed(_latency);
    // Demo shape only, and deliberately small: the screen this feeds used to
    // ship invented "community mention" counts as if they were measured, so
    // the mock now shows an obviously thin sample rather than a convincing one.
    return const YearTrends(
      windowDraws: 1,
      coveredByLibrary: 1,
      drawn: [
        DrawnNumber(number: '47', times: 1, symbols: [
          NumberSymbol(slug: 'butterfly', nameTh: 'ผีเสื้อ'),
        ]),
      ],
      noteTh: 'ข้อมูลตัวอย่างสำหรับทดลองใช้งาน — '
          'เลขที่ออกแล้วไม่ได้บอกว่าเลขใดจะออกงวดหน้า',
    );
  }

  @override
  Future<DigitStats> digitStats({int windowDraws = 24}) async {
    await Future<void>.delayed(_latency);
    return DigitStats(
      windowDraws: 1,
      last2: [
        for (var i = 0; i < 100; i++)
          Last2Bucket(
            number: i.toString().padLeft(2, '0'),
            count: i == 47 ? 1 : 0,
            lastSeen: i == 47 ? _drawDate : null,
          ),
      ],
      positionDigits: [
        for (var p = 0; p < 6; p++) [for (var d = 0; d < 10; d++) 0],
      ],
      neverSeenLast2: 99,
      noteTh: 'สถิติคือสิ่งที่เคยออกมาแล้ว ไม่ใช่สิ่งที่จะออกงวดหน้า '
          'การออกรางวัลแต่ละงวดสุ่มใหม่ทั้งหมด ทุกเลขมีโอกาสเท่ากันเสมอ',
      sourceTh: 'ข้อมูลตัวอย่างสำหรับทดลองใช้งาน',
    );
  }

  DrawResult _demoDraw() {
    PrizeTierResult t(String code, String name, String short, int amount,
            MatchKind kind, List<String> numbers, int sort) =>
        PrizeTierResult(
          code: code,
          nameTh: name,
          shortNameTh: short,
          amountThb: amount,
          winnerCount: numbers.length,
          matchKind: kind,
          sort: sort,
          numbers: numbers,
        );

    return DrawResult(
      drawDate: _drawDate,
      periodLabelTh: 'งวดวันที่ 1 สิงหาคม 2569 (ตัวอย่าง)',
      status: DrawStatus.announced,
      resultRevision: 0,
      // False on purpose: this fixture carries a handful of numbers, not 173,
      // so the app must refuse to declare any ticket a loser against it.
      complete: false,
      hasUnreadableTier: false,
      dutyRate: 0.005,
      prizes: [
        t('first', 'รางวัลที่ 1', 'ที่ 1', 6000000, MatchKind.exact6,
            ['482913'], 10),
        t('near_first', 'รางวัลข้างเคียงรางวัลที่ 1', 'ข้างเคียง', 100000,
            MatchKind.exact6, ['482912', '482914'], 20),
        t('front3', 'รางวัลเลขหน้า 3 ตัว', 'หน้า 3 ตัว', 4000,
            MatchKind.prefix3, ['517', '063'], 70),
        t('last3', 'รางวัลเลขท้าย 3 ตัว', 'ท้าย 3 ตัว', 4000,
            MatchKind.suffix3, ['390', '628'], 80),
        t('last2', 'รางวัลเลขท้าย 2 ตัว', 'ท้าย 2 ตัว', 2000,
            MatchKind.suffix2, ['47'], 90),
      ],
      sourceCustodianTh: 'สำนักงานสลากกินแบ่งรัฐบาล (ข้อมูลตัวอย่าง)',
      nextDrawDate: DateTime(2026, 8, 16),
      nextDrawEstimated: true,
    );
  }
}

class MockSourcesRepository implements SourcesRepository {
  @override
  Future<List<SourceTier>> tiers() async {
    await Future<void>.delayed(_latency);
    return SourceTier.values;
  }

  @override
  Future<int> libraryCount() async => 147;
}

/// Demo story for the symbol screen before a Supabase connection exists.
class MockLibraryRepository implements LibraryRepository {
  /// Empty by default, and deliberately so: the ทักษา readings exist only in
  /// draft, from one copyrighted source, so the shipped behaviour is an honest
  /// empty state. A test that wants the populated path supplies its own.
  @override
  Future<TaksaReading> taksa(int weekday) async {
    await Future<void>.delayed(_latency);
    return TaksaReading(
        slug: '', nameTh: '', weekday: weekday, readings: const []);
  }

  /// Empty for the same reason ทักษา is: the วงราศี verdicts exist only in
  /// draft, from one compilation that has not been corroborated, so the
  /// shipped behaviour is an honest empty state. A test that wants the
  /// populated path supplies its own.
  @override
  Future<AgeWheelReading> ageWheel(int age) async {
    await Future<void>.delayed(_latency);
    return AgeWheelReading.empty(age);
  }

  @override
  Future<SymbolStory> story(String slug) async {
    await Future<void>.delayed(_latency);
    return const SymbolStory(
      slug: 'bird',
      nameTh: 'นก',
      category: 'สัญลักษณ์ในความฝัน',
      numbers: [],
      readings: [
        SymbolReading(
          tier: SourceTier.a2,
          workTh: 'ตัวอย่างข้อมูล',
          locatorTh: 'ตัวอย่าง',
          plainTh: 'ตัวอย่างคำแปล — เชื่อมฐานข้อมูลจริงเพื่อดูเนื้อหาจากตำรา',
        ),
      ],
      related: [],
      narrower: [],
    );
  }
}
