import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../token_storage_service.dart';

class ChatApiService {
  final String baseUrl = "http://10.0.2.2:8080/busanbank";

  /// 세션 생성 API 호출 (JWT 필요)
  Future<int?> startChatSession({
    required String inquiryType,
  }) async {
    final url = Uri.parse("$baseUrl/api/chat/start");

    final token = await TokenStorageService().readToken();
    if (token == null || token.isEmpty) {
      print("❌ 토큰 없음. 로그인 필요");
      return null;
    }

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "inquiryType": inquiryType,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json["status"] == "SUCCESS") return json["sessionId"] as int;
      print("❌ 세션 생성 실패: ${json["message"]}");
      return null;
    }

    print("❌ 세션 생성 HTTP 오류: ${response.statusCode} / body=${response.body}");
    return null;
  }
}
