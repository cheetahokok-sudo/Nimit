import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/lottery.dart';
import '../repositories/repositories.dart';

/// Official draw results from the live database.
///
/// The results originate with สำนักงานสลากกินแบ่งรัฐบาล and are ingested
/// server-side (see scripts/ingest-lottery.mjs) rather than fetched from
/// glo.or.th here: this app ships as a web build and the browser would block
/// the cross-origin call. Reading from our own database also means the app
/// keeps answering when GLO is down, and has the history the statistics need.
///
/// This repository returns FACTS and never a verdict. Whether a particular
/// ticket won is decided on-device by `lottery_checker.dart`, so the user's
/// numbers never travel over the network.
///
/// Errors throw rather than degrade to a plausible-looking empty draw. An
/// invented draw here would tell someone they lost.
class PostgrestLotteryRepository implements LotteryRepository {
  PostgrestLotteryRepository({
    required this.baseUrl,
    required this.anonKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String anonKey;
  final http.Client _client;

  static const _timeout = Duration(seconds: 10);

  Map<String, String> get _headers => {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      };

  Future<dynamic> _rpc(String fn, Map<String, dynamic> params) async {
    final uri = Uri.parse('$baseUrl/rest/v1/rpc/$fn');
    // Encode explicitly. Everything user-visible in these payloads is Thai —
    // 'งวดวันที่ 1 สิงหาคม 2569', 'รางวัลที่ 1' — and a charset-less
    // content-type on the response decodes as Latin-1, which is how an earlier
    // live check produced convincing mojibake instead of an obvious failure.
    final body = utf8.encode(jsonEncode(params));
    final response =
        await _client.post(uri, headers: _headers, body: body).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('$fn returned HTTP ${response.statusCode}');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  @override
  Future<DrawResult> latestDraw() async {
    final decoded = await _rpc('lottery_draw', {'p_draw_date': null});
    if (decoded is! Map<String, dynamic>) {
      // The function returns SQL NULL when no announced draw exists yet. That
      // is a real state (a fresh database, or ingestion not yet run) and the
      // UI must show it as "ยังไม่มีข้อมูล", never as "you did not win".
      throw Exception('lottery_draw returned no announced draw');
    }
    return DrawResult.fromJson(decoded);
  }

  @override
  Future<List<DrawResult>> recentDraws({int limit = 12}) async {
    final decoded = await _rpc('lottery_recent_draws', {'p_limit': limit});
    final rows = decoded as List<dynamic>? ?? const [];
    return [
      for (final r in rows) DrawResult.fromJson(r as Map<String, dynamic>),
    ];
  }

  @override
  Future<DigitStats> digitStats({int windowDraws = 24}) async {
    final decoded = await _rpc('lottery_digit_stats', {'p_window': windowDraws});
    return DigitStats.fromJson(decoded as Map<String, dynamic>);
  }

  @override
  Future<DrawInfo> currentDraw() async {
    final decoded =
        await _rpc('lottery_calendar', {'p_limit': 4}) as Map<String, dynamic>;

    final latestAnnounced = decoded['latestAnnounced'] as String?;
    final nextEstimated = decoded['nextEstimated'] as String?;
    final draws = decoded['draws'] as List<dynamic>? ?? const [];

    // Prefer a draw date we actually hold over the 1st/16th estimate. GLO moves
    // draws often enough that presenting the estimate as fact is wrong several
    // times a year, and always in the direction of claiming a completed งวด has
    // not happened yet.
    Map<String, dynamic>? pending;
    for (final d in draws) {
      final row = d as Map<String, dynamic>;
      final status = DrawStatus.fromCode(row['status'] as String?);
      if (status != DrawStatus.announced) pending = row;
    }

    if (pending != null) {
      return DrawInfo(
        drawDate: DateTime.parse(pending['drawDate'] as String),
        statusTh: DrawStatus.fromCode(pending['status'] as String?) ==
                DrawStatus.partial
            ? 'กำลังทยอยประกาศผล ยังไม่ครบทุกรางวัล'
            : 'รอประกาศจากสำนักงานสลากกินแบ่งรัฐบาล',
        status: DrawStatus.fromCode(pending['status'] as String?),
        estimated: false,
      );
    }

    if (nextEstimated != null) {
      return DrawInfo(
        drawDate: DateTime.parse(nextEstimated),
        statusTh: 'รอประกาศจากสำนักงานสลากกินแบ่งรัฐบาล',
        status: DrawStatus.scheduled,
        estimated: true,
      );
    }

    if (latestAnnounced != null) {
      return DrawInfo(
        drawDate: DateTime.parse(latestAnnounced),
        statusTh: 'ประกาศผลแล้ว',
        status: DrawStatus.announced,
        estimated: false,
      );
    }

    throw Exception('lottery_calendar returned no usable draw date');
  }
}
