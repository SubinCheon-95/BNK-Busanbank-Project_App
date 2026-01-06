import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tkbank/services/token_storage_service.dart';

class VoiceCallApi {
  final String baseUrl; // ex) http://10.0.2.2:8080/busanbank
  final TokenStorageService _tokenStorage = TokenStorageService();

  VoiceCallApi({required this.baseUrl});

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  Future<String> _mustToken() async {
    final t = await _tokenStorage.readToken();
    if (t == null || t.isEmpty) throw Exception('토큰 없음: 로그인 필요');
    return t;
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
    _ensureOk(res, 'enqueue');
    return (res.body.trim().isEmpty) ? {'ok': true} : jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> end({required String sessionId, String reason = 'CUSTOMER_HANGUP'}) async {
    final token = await _mustToken();
    final res = await http.post(
      _u('/api/call/$sessionId/end'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'reason': reason}),
    );
    _ensureOk(res, 'end');
    final body = res.body.trim();
    return body.isEmpty ? {'ok': true} : (jsonDecode(body) as Map<String, dynamic>);
  }

  void _ensureOk(http.Response res, String where) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('$where failed: ${res.statusCode} ${res.body}');
    }
  }
}
