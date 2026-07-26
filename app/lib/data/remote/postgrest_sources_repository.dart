import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/source.dart';
import '../repositories/repositories.dart';

/// Reads the live library through the `api` schema on Supabase.
///
/// Deliberately built on plain `http` rather than `supabase_flutter`: this
/// phase needs two anonymous GET endpoints, and the Supabase SDK drags auth,
/// realtime and storage clients into a web bundle that is currently lean.
/// The SDK earns its place in Phase 4 when sign-in arrives; not before.
///
/// Failure policy:
///  * [tiers] never touches the network. Tier wording and ordering are needed
///    to render the trust framework at all, and the enum is the same source
///    the badges draw from — a network round-trip adds a failure mode without
///    adding information.
///  * [libraryCount] queries `api.library_stats` and THROWS on failure rather
///    than inventing a number. The UI treats an error as "show no count",
///    which is honest; showing a stale or made-up count in a product about
///    verifiable sourcing is not.
class PostgrestSourcesRepository implements SourcesRepository {
  PostgrestSourcesRepository({
    required this.baseUrl,
    required this.anonKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String anonKey;
  final http.Client _client;

  static const _timeout = Duration(seconds: 8);

  Map<String, String> get _headers => {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
        'Accept': 'application/json',
      };

  @override
  Future<List<SourceTier>> tiers() async => SourceTier.values;

  @override
  Future<int> libraryCount() async {
    final uri = Uri.parse('$baseUrl/rest/v1/library_stats');
    final response = await _client.get(uri, headers: _headers).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('library_stats returned HTTP ${response.statusCode}');
    }
    // utf8 explicitly: Thai content plus a charset-less content-type header
    // would otherwise decode as Latin-1 on some platforms.
    final rows = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    if (rows.isEmpty) throw Exception('library_stats returned no rows');
    final stats = rows.first as Map<String, dynamic>;
    return stats['edition_count'] as int? ?? 0;
  }
}
