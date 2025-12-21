/*
  날짜: 2025/12/19
  내용: ai 챗봇 연동 서비스 페이지
  작성자: 오서정
*/
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatbotService {
  final String baseUrl = "http://10.0.2.2:8080/busanbank";

  Future<Map<String, dynamic>> ask(String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chatbot/ask'),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "message": message,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return {
        "answer": data["answer"] ?? "답변이 없습니다.",
        "actions": data["actions"] != null
            ? List<String>.from(data["actions"])
            : null,
      };
    } else {
      throw Exception("챗봇 응답 실패");
    }
  }
}
