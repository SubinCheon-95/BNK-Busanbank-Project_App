import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tkbank/services/token_storage_service.dart';

class VoiceCallApi {
  final String baseUrl; // ex) http://10.0.2.2:8080/busanbank
  final TokenStorageService _tokenStorage = TokenStorageService();

  VoiceCallApi({required this.baseUrl});

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  Future<String> _mustToken() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw Exception('토큰 없음: 로그인 필요');
    }
    return token;
  }

  Future<Map<String, dynamic>> enqueue({required String sessionId}) async {
    final token = await _mustToken();

    final res = await http.post(
      _u('/api/call/voice/enqueue/$sessionId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = utf8.decode(res.bodyBytes);
    print("📌 [enqueue] status=${res.statusCode} body=$body");

    _ensureOk(res, 'enqueue');
    return jsonDecode(body) as Map<String, dynamic>;
  }

  /// ✅ status 조회 (WAITING / ACCEPTED / ENDED)
  Future<Map<String, dynamic>> status({required String sessionId}) async {
    final token = await _mustToken();

    final res = await http.get(
      _u('/api/call/voice/$sessionId/status'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final body = utf8.decode(res.bodyBytes);
    print("📌 [status] status=${res.statusCode} body=$body");

    _ensureOk(res, 'status');
    return jsonDecode(body) as Map<String, dynamic>;
  }

  /// ✅ 고객 종료는 /api/call/{sessionId}/end (너가 만든 CallEndController)
  Future<Map<String, dynamic>> end({required String sessionId, String reason = ''}) async {
    final token = await _mustToken();

    final res = await http.post(
      _u('/api/call/$sessionId/end'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'reason': reason}),
    );

    final body = utf8.decode(res.bodyBytes);
    print("📌 [end] status=${res.statusCode} body=$body");

    _ensureOk(res, 'end');
    return body.trim().isEmpty ? {'ok': true} : (jsonDecode(body) as Map<String, dynamic>);
  }

  void _ensureOk(http.Response res, String where) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('$where failed: ${res.statusCode} ${utf8.decode(res.bodyBytes)}');
    }
  }
}
