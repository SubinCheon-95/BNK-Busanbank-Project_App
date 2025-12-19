import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_storage_service.dart';

class StepPointService {
  final String baseUrl = "http://10.0.2.2:8080/busanbank";
  final TokenStorageService _tokenStorage = TokenStorageService();

  /// 만보기 포인트 지급
  Future<Map<String, dynamic>> earnStepsPoints({
    required int userNo,
    required int steps,
    required String date,
  }) async {
    final token = await _tokenStorage.readToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      'userNo': userNo,
      'steps': steps,
      'date': date,
    });

    final response = await http.post(
      Uri.parse('$baseUrl/api/flutter/points/steps/earn'),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? '포인트 지급 실패');
    }
  }
}