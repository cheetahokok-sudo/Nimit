import '../../core/utils/thai_date.dart';
import '../models/dream.dart';
import '../models/fortune.dart';
import '../models/lottery.dart';
import '../models/source.dart';
import '../models/trends.dart';
import '../repositories/repositories.dart';

/// Seeded with the exact content of the v2 UI board so the scaffold demos
/// the real product story (white-snake dream) end to end.

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

  @override
  Future<List<String>> todaysNumbers() async {
    await Future<void>.delayed(_latency);
    return const ['16', '29', '68', '269'];
  }
}

class MockTrendsRepository implements TrendsRepository {
  @override
  Future<TrendsData> fetch(String regionTh) async {
    await Future<void>.delayed(_latency);
    return const TrendsData(
      hotSymbol: TrendingSymbol(
        nameTh: 'งูขาว',
        changePercent: 38,
        noteTh: 'ข้อมูลจากโพสต์สาธารณะและการค้นหาในแอป',
      ),
      mentions: [
        NumberMention(number: '16', count: 92),
        NumberMention(number: '29', count: 74),
        NumberMention(number: '68', count: 61),
        NumberMention(number: '61', count: 49),
      ],
      story: CommunityStory(
        quoteTh: '“คุณแม่ 3 คนในเชียงใหม่ฝันเห็นน้ำเหมือนกัน”',
      ),
    );
  }
}

class MockFortuneRepository implements FortuneRepository {
  @override
  Future<FortuneData> fetch() async {
    await Future<void>.delayed(_latency);
    return const FortuneData(
      lagnaTh: 'ลัคนาเมษ',
      monthThemeTh: 'เดือนนี้: เริ่มสิ่งใหม่อย่างมีแผน',
      profileCompleteTh: 'ข้อมูลเกิดครบแล้ว',
      monthlyNumbers: ['4', '14', '41', '149'],
      sourceCards: [
        FortuneSourceCard(
          tier: SourceTier.a2,
          titleTh: 'ฉบับตรวจชำระโดยสถาบัน',
          bodyTh: 'จักรทีปนี • ดาวอังคาร • ลัคนาและเรือน',
        ),
        FortuneSourceCard(
          tier: SourceTier.b1,
          titleTh: 'การวิเคราะห์เชิงวิชาการ',
          bodyTh: 'อธิบายความต่างระหว่างสำนัก ไม่รวมเป็นคำตอบเดียว',
        ),
      ],
      dailyAdviceTh: 'ทบทวนเป้าหมายการเงินก่อนตัดสินใจจากอารมณ์',
    );
  }
}

class MockLotteryRepository implements LotteryRepository {
  @override
  Future<DrawInfo> currentDraw() async {
    await Future<void>.delayed(_latency);
    return DrawInfo(
      drawDate: nextDrawDate(DateTime.now()),
      isAnnounced: false,
      statusTh: 'รอประกาศจากสำนักงานสลากกินแบ่งรัฐบาล',
    );
  }

  @override
  Future<String> check(String number) async {
    await Future<void>.delayed(_latency);
    return 'ยังไม่ประกาศผลงวดนี้ บันทึกเลขไว้แล้วระบบจะช่วยตรวจให้ทันทีที่มีผลอย่างเป็นทางการ';
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
