import 'dart:convert';
import 'package:http/http.dart' as http;

class VoiceCallApi {
  final String baseUrl; // ex) http://10.0.2.2:8080/busanbank

  VoiceCallApi({required this.baseUrl});

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  /// ✅ 고객: 전화 요청(= voice 큐에 enqueue)
  Future<Map<String, dynamic>> enqueue({
    required String sessionId,
  }) async {
    final res = await http.post(
      _u('/api/call/voice/enqueue/$sessionId'),
      headers: {'Content-Type': 'application/json'},
    );
    _ensureOk(res, 'enqueue');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// ✅ 고객: (선택) 대기 확인 - 디버깅용
  Future<List<dynamic>> waiting() async {
    final res = await http.get(_u('/api/call/voice/waiting'));
    _ensureOk(res, 'waiting');
    return jsonDecode(res.body) as List<dynamic>;
  }

  /// ✅ 고객: 통화 종료(고객이 끊기) - 상담사 화면에서 사라지게 하려면
  /// 현재 backend가 /api/call/{sessionId}/end 로 정리되는 구조면 그걸 호출.
  /// (주인님이 powershell로 성공시킨 그 엔드포인트)
  Future<Map<String, dynamic>> end({
    required String sessionId,
  }) async {
    final res = await http.post(
      _u('/api/call/$sessionId/end'),
      headers: {'Content-Type': 'application/json'},
    );
    _ensureOk(res, 'end');
    // end는 Map이 아닐 수도 있어서 안전하게 처리
    final body = res.body.trim();
    return body.isEmpty ? {'ok': true} : (jsonDecode(body) as Map<String, dynamic>);
  }

  void _ensureOk(http.Response res, String where) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('$where failed: ${res.statusCode} ${res.body}');
    }
  }
}
