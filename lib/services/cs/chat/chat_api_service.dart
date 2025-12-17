import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatApiService {
  final String baseUrl = "http://10.0.2.2:8080/busanbank";

  /// 세션 생성 API 호출
  Future<int?> startChatSession({
    required int userId,
    required String inquiryType,
  }) async {
    final url = Uri.parse("$baseUrl/api/chat/start");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "inquiryType": inquiryType,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json["status"] == "SUCCESS") {
        return json["sessionId"] as int;
      } else {
        print("❌ 세션 생성 실패: ${json["message"]}");
      }
    } else {
      print("❌ 세션 생성 HTTP 오류: ${response.statusCode}");
    }
    return null;
  }
}
