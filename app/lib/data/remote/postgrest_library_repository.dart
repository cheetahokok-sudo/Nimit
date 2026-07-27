import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/library.dart';
import '../repositories/repositories.dart';

/// One symbol's full story from the live library.
///
/// Calls `api.symbol_story`, which assembles readings, numbers, tier badges and
/// relations server-side in a single round trip. The tier is joined from the
/// edition there rather than stored per reading, so a badge shown next to a
/// quote can never disagree with the bibliography it cites — and the decision
/// about whether verbatim text may be shown is made in SQL, never here.
class PostgrestLibraryRepository implements LibraryRepository {
  PostgrestLibraryRepository({
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

  @override
  Future<SymbolStory> story(String slug) async {
    final uri = Uri.parse('$baseUrl/rest/v1/rpc/symbol_story');
    // Explicit UTF-8 both ways: every field here is Thai, and a charset-less
    // response content-type decodes as Latin-1.
    final body = utf8.encode(jsonEncode({'p_slug': slug}));
    final response =
        await _client.post(uri, headers: _headers, body: body).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('symbol_story returned HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      // SQL NULL: the slug does not exist or is not published. A real state,
      // surfaced as an error the UI renders rather than an empty story that
      // would read as "this symbol means nothing".
      throw Exception('symbol_story: no published symbol "$slug"');
    }
    return SymbolStory.fromJson(decoded);
  }

  @override
  Future<TaksaReading> taksa(int weekday) async {
    final uri = Uri.parse('$baseUrl/rest/v1/rpc/taksa_birthday');
    final body = utf8.encode(jsonEncode({'p_weekday': weekday}));
    final response =
        await _client.post(uri, headers: _headers, body: body).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('taksa_birthday returned HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      // SQL NULL — the birthday symbol is not published yet. Unlike
      // symbol_story, this is NOT an error: it is the expected state until a
      // second source clears these readings. Return an empty reading so the
      // screen shows its honest empty state rather than a failure.
      return TaksaReading(
          slug: '', nameTh: '', weekday: weekday, readings: const []);
    }
    return TaksaReading.fromJson(decoded);
  }
}
