import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tkbank/services/token_storage_service.dart';

class VoiceCallApi {
  final String baseUrl; // ex) http://10.0.2.2:8080/busanbank
  final TokenStorageService _tokenStorage = TokenStorageService();

  VoiceCallApi({required this.baseUrl});

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  Future<Map<String, dynamic>> enqueue({required String sessionId}) async {
    final token = await _tokenStorage.readToken();

    // 🔍 ① 토큰 확인 로그
    print("📌 tokenLen=${token?.length} tokenHead=${token == null ? 'null' : token.substring(0, 20)}");

    final res = await http.post(
      _u('/cs/call/voice/enqueue/$sessionId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    // 🔍 ② 실제 전송된 Authorization / 응답 확인
    print("📌 sentAuth=${'Bearer ${token ?? ''}'.substring(0, 30)}...");
    print("📌 status=${res.statusCode} body=${utf8.decode(res.bodyBytes)}");

    _ensureOk(res, 'enqueue');
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> end({required String sessionId}) async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw Exception('토큰 없음: 로그인 필요');
    }

    final res = await http.post(
      _u('/cs/call/voice/$sessionId/end'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    _ensureOk(res, 'end');
    final body = utf8.decode(res.bodyBytes).trim();
    return body.isEmpty ? {'ok': true} : (jsonDecode(body) as Map<String, dynamic>);
  }

  Future<List<dynamic>> waiting() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw Exception('토큰 없음: 로그인 필요');
    }

    final res = await http.get(
      _u('/cs/call/voice/waiting'),
      headers: {'Authorization': 'Bearer $token'},
    );

    _ensureOk(res, 'waiting');
    return jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
  }

  void _ensureOk(http.Response res, String where) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('$where failed: ${res.statusCode} ${res.body}');
    }
  }
}
