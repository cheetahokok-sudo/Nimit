import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/dream.dart';
import '../repositories/repositories.dart';

/// Real dream analysis against the live library via `api.analyze_dream`.
///
/// The server does everything deterministic — longest-match term extraction,
/// interpretation lookup, tier joining, lawful-quote decisions — and returns
/// JSON already shaped for [DreamAnalysis.fromJson]. The client adds nothing:
/// no generation, no reordering, no invented meaning. If the library has no
/// match, the user sees the honest empty state the server sent.
class PostgrestDreamRepository implements DreamRepository {
  PostgrestDreamRepository({
    required this.baseUrl,
    required this.anonKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String anonKey;
  final http.Client _client;

  static const _timeout = Duration(seconds: 12);

  Map<String, String> get _headers => {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      };

  @override
  Future<DreamAnalysis> analyze(
    String text, {
    String? feelingTh,
    String? timeOfNightTh,
  }) async {
    final uri = Uri.parse('$baseUrl/rest/v1/rpc/analyze_dream');
    // Encode explicitly: Thai text through default encoding paths is how an
    // earlier live check produced a false "no results".
    final body = utf8.encode(jsonEncode({'p_text': text}));
    final response =
        await _client.post(uri, headers: _headers, body: body).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('analyze_dream returned HTTP ${response.statusCode}');
    }
    final decoded =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return DreamAnalysis.fromJson(decoded);
  }

}
