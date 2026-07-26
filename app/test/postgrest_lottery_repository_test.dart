import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nimit/data/models/lottery.dart';
import 'package:nimit/data/remote/postgrest_lottery_repository.dart';

/// The first http-mock test in this repository.
///
/// `MockClient` ships inside `package:http`, which is already a dependency, so
/// this needs no new dev dependency and no CI change. The repository is
/// constructed directly and `providers.dart` is never touched, so `flutter
/// test` stays hermetic and the mock defaults remain the app's defaults.
PostgrestLotteryRepository _repo(MockClient client) =>
    PostgrestLotteryRepository(
      baseUrl: 'https://example.supabase.co',
      anonKey: 'test-key',
      client: client,
    );

/// Deliberately charset-less, exactly as PostgREST replies. Decoding this as
/// Latin-1 is the failure this suite exists to prevent.
MockClient _serving(Object body, {int status = 200}) => MockClient((req) async {
      return http.Response.bytes(
        utf8.encode(body is String ? body : jsonEncode(body)),
        status,
        headers: {'content-type': 'application/json'},
      );
    });

Map<String, dynamic> _drawJson({
  String status = 'announced',
  bool complete = true,
  List<Map<String, dynamic>>? prizes,
}) =>
    {
      'drawDate': '2026-07-16',
      'periodLabelTh': 'งวดวันที่ 16 กรกฎาคม 2569',
      'status': status,
      'resultRevision': 0,
      'complete': complete,
      'dutyRate': 0.005,
      'source': {
        'custodianTh': 'สำนักงานสลากกินแบ่งรัฐบาล',
        'url': 'https://www.glo.or.th/',
        'licenceTh': 'GLO Public Used',
        'retrievedAt': '2026-07-16T18:02:00+07:00',
      },
      'prizes': prizes ??
          [
            {
              'code': 'first',
              'nameTh': 'รางวัลที่ 1',
              'shortNameTh': 'ที่ 1',
              'amountThb': 6000000,
              'winnerCount': 1,
              'matchKind': 'exact6',
              'sort': 10,
              'numbers': ['639214'],
            },
            {
              'code': 'last2',
              'nameTh': 'รางวัลเลขท้าย 2 ตัว',
              'shortNameTh': 'ท้าย 2 ตัว',
              'amountThb': 2000,
              'winnerCount': 1,
              'matchKind': 'suffix2',
              'sort': 90,
              'numbers': ['71'],
            },
          ],
      'nextDrawDate': '2026-08-01',
      'nextDrawEstimated': true,
    };

void main() {
  group('request shape', () {
    test('posts p_-prefixed params with the anon key, UTF-8 encoded', () async {
      late http.Request seen;
      final client = MockClient((req) async {
        seen = req;
        return http.Response.bytes(utf8.encode(jsonEncode(_drawJson())), 200,
            headers: {'content-type': 'application/json'});
      });

      await _repo(client).latestDraw();

      expect(seen.url.path, '/rest/v1/rpc/lottery_draw');
      expect(seen.headers['apikey'], 'test-key');
      expect(seen.headers['Authorization'], 'Bearer test-key');
      final body =
          jsonDecode(utf8.decode(seen.bodyBytes)) as Map<String, dynamic>;
      expect(body.containsKey('p_draw_date'), isTrue);
      expect(body['p_draw_date'], isNull);
    });

    test('no request ever carries a user ticket number', () async {
      // The privacy property this whole design rests on: matching is local, so
      // nothing the user typed may appear in an outbound body.
      final bodies = <String>[];
      final client = MockClient((req) async {
        bodies.add(utf8.decode(req.bodyBytes));
        return http.Response.bytes(utf8.encode(jsonEncode(_drawJson())), 200,
            headers: {'content-type': 'application/json'});
      });
      final repo = _repo(client);
      await repo.latestDraw();
      for (final b in bodies) {
        expect(b.contains('number'), isFalse);
        expect(b.contains('ticket'), isFalse);
      }
    });
  });

  group('Thai survives a charset-less content-type', () {
    // PostgREST replies `application/json` with no charset. Decoding those
    // bytes as Latin-1 produces convincing mojibake rather than an obvious
    // error, so this asserts the exact strings, not just that parsing worked.
    test('prize names and the period label decode correctly', () async {
      final draw = await _repo(_serving(_drawJson())).latestDraw();
      expect(draw.periodLabelTh, 'งวดวันที่ 16 กรกฎาคม 2569');
      expect(draw.prizes.first.nameTh, 'รางวัลที่ 1');
      expect(draw.sourceCustodianTh, 'สำนักงานสลากกินแบ่งรัฐบาล');
    });

    test('the statistics caveat decodes correctly', () async {
      const note = 'สถิติคือสิ่งที่เคยออกมาแล้ว ไม่ใช่สิ่งที่จะออกงวดหน้า';
      final stats = await _repo(_serving({
        'windowDraws': 24,
        'last2': [
          {'n': '00', 'count': 0, 'lastSeenDate': null},
        ],
        'positionDigits': [],
        'neverSeenLast2': 99,
        'noteTh': note,
      })).digitStats();
      expect(stats.noteTh, note);
    });
  });

  group('parsing', () {
    test('a full draw parses with its amounts and match rules', () async {
      final draw = await _repo(_serving(_drawJson())).latestDraw();
      expect(draw.status, DrawStatus.announced);
      expect(draw.complete, isTrue);
      expect(draw.verdictAvailable, isTrue);
      expect(draw.tier('first')!.amountThb, 6000000);
      expect(draw.tier('first')!.matchKind, MatchKind.exact6);
      expect(draw.tier('last2')!.numbers, ['71']);
      expect(draw.dutyRate, 0.005);
    });

    test('prizes are ordered by sort regardless of payload order', () async {
      final json = _drawJson();
      json['prizes'] = (json['prizes'] as List).reversed.toList();
      final draw = await _repo(_serving(json)).latestDraw();
      expect(draw.prizes.first.code, 'first');
    });

    test('an unknown match rule poisons the verdict for the whole draw',
        () async {
      final draw = await _repo(_serving(_drawJson(prizes: [
        {
          'code': 'first',
          'nameTh': 'รางวัลที่ 1',
          'shortNameTh': 'ที่ 1',
          'amountThb': 6000000,
          'winnerCount': 1,
          'matchKind': 'exact6',
          'sort': 10,
          'numbers': ['639214'],
        },
        {
          'code': 'brand_new',
          'nameTh': 'รางวัลรูปแบบใหม่',
          'shortNameTh': 'ใหม่',
          'amountThb': 5000,
          'winnerCount': 1,
          'matchKind': 'middle4',
          'sort': 95,
          'numbers': ['1234'],
        },
      ]))).latestDraw();

      expect(draw.hasUnreadableTier, isTrue);
      expect(draw.verdictAvailable, isFalse);
    });

    test('an empty prize list parses to incomplete rather than crashing',
        () async {
      final draw =
          await _repo(_serving(_drawJson(complete: false, prizes: [])))
              .latestDraw();
      expect(draw.prizes, isEmpty);
      expect(draw.verdictAvailable, isFalse);
    });

    test('an unknown status never resolves to announced', () async {
      final draw =
          await _repo(_serving(_drawJson(status: 'in_progress'))).latestDraw();
      expect(draw.status, DrawStatus.unknown);
      expect(draw.verdictAvailable, isFalse);
    });

    test('recentDraws parses an array', () async {
      final draws = await _repo(_serving(<Map<String, dynamic>>[
        _drawJson(),
        _drawJson(),
      ])).recentDraws();
      expect(draws.length, 2);
      expect(draws.first.tier('first')!.numbers, ['639214']);
    });
  });

  group('failure is loud, never invented', () {
    test('HTTP 500 throws and fabricates no draw', () async {
      expect(
        () => _repo(_serving('{"message":"boom"}', status: 500)).latestDraw(),
        throwsA(isA<Exception>()),
      );
    });

    test('a non-JSON body throws', () async {
      expect(
        () => _repo(_serving('<html>gateway error</html>')).latestDraw(),
        throwsA(isA<Exception>()),
      );
    });

    test('SQL NULL (no announced draw yet) throws rather than faking one',
        () async {
      // This is a real state on a fresh database. It must surface as an error
      // the UI renders as "ยังไม่มีข้อมูล", never as an empty draw that would
      // read as "you did not win".
      expect(
        () => _repo(_serving('null')).latestDraw(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('currentDraw prefers held data over the 1st/16th estimate', () {
    test('a pending draw we hold is used, and marked not estimated', () async {
      final info = await _repo(_serving({
        'today': '2026-07-26',
        'latestAnnounced': '2026-07-16',
        'nextEstimated': '2026-08-01',
        'draws': [
          {
            'drawDate': '2026-08-02',
            'labelTh': 'งวดวันที่ 2 สิงหาคม 2569',
            'status': 'scheduled',
          },
          {
            'drawDate': '2026-07-16',
            'labelTh': 'งวดวันที่ 16 กรกฎาคม 2569',
            'status': 'announced',
          },
        ],
      })).currentDraw();

      expect(info.drawDate, DateTime.parse('2026-08-02'));
      expect(info.estimated, isFalse);
      expect(info.isAnnounced, isFalse);
    });

    test('falls back to the estimate and says so', () async {
      final info = await _repo(_serving({
        'today': '2026-07-26',
        'latestAnnounced': '2026-07-16',
        'nextEstimated': '2026-08-01',
        'draws': [
          {
            'drawDate': '2026-07-16',
            'labelTh': 'งวดวันที่ 16 กรกฎาคม 2569',
            'status': 'announced',
          },
        ],
      })).currentDraw();

      expect(info.drawDate, DateTime.parse('2026-08-01'));
      expect(info.estimated, isTrue);
    });

    test('a partial draw is surfaced with its own wording', () async {
      final info = await _repo(_serving({
        'today': '2026-08-01',
        'latestAnnounced': '2026-07-16',
        'nextEstimated': '2026-08-16',
        'draws': [
          {
            'drawDate': '2026-08-01',
            'labelTh': 'งวดวันที่ 1 สิงหาคม 2569',
            'status': 'partial',
          },
        ],
      })).currentDraw();

      expect(info.status, DrawStatus.partial);
      expect(info.isAnnounced, isFalse);
      expect(info.statusTh, contains('ยังไม่ครบ'));
    });
  });
}
