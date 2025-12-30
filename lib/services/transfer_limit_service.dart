import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_storage_service.dart';

class TransferLimitService {
  final String baseUrl = 'http://10.0.2.2:8080/busanbank';
  final TokenStorageService _tokenStorage = TokenStorageService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenStorage.readToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getTransferLimit() async {
    final headers = await _getHeaders();

    final res = await http.get(
      Uri.parse('$baseUrl/api/transfer/limit'),
      headers: headers,
    );

    if (res.statusCode != 200) {
      throw Exception('이체한도 조회 실패: ${res.statusCode}');
    }

    return jsonDecode(res.body);
  }

  Future<void> updateTransferLimit(int onceLimit, int dailyLimit) async {
    final headers = await _getHeaders();

    final res = await http.post(
      Uri.parse('$baseUrl/api/transfer/limit'),
      headers: headers,
      body: jsonEncode({
        'onceLimit': onceLimit,
        'dailyLimit': dailyLimit,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('이체한도 변경 실패: ${res.statusCode}');
    }
  }
}
