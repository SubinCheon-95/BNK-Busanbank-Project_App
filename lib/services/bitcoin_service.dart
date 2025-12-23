import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tkbank/services/token_storage_service.dart';

import '../models/Bitcoin_result.dart';

class BitcoinService { // 비트코인 예측 이벤트 데이터 처리 - 작성자: 윤종인 2025.12.23
  static const String baseUrl = "http://10.0.2.2:8080/busanbank";
  final TokenStorageService _tokenStorage = TokenStorageService();

  /// ✅ JWT 토큰 헤더 생성 (자동)
  Future<Map<String, String>> _getHeaders({bool needsAuth = false}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    // 인증이 필요한 요청이면 JWT 토큰 추가
    if (needsAuth) {
      final token = await _tokenStorage.readToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // 1️⃣ 가격 조회 + 실제 결과 계산 (GET)
  Future<BitcoinResult> fetchResult() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/coin/history/btc/yesterdayAndToday?symbol=BTC'),
    );

    if (response.statusCode != 200) {
      throw Exception('비트코인 시세 조회 실패');
    }

    final List<dynamic> data = jsonDecode(response.body);

    final int yesterday = (data[0]['price'] as num).round();
    final int today = (data[1]['price'] as num).round();
    print('yesterday = $yesterday, today = $today');

    return BitcoinResult(
      yesterday: yesterday,
      today: today,
      actual: yesterday < today ? 'up' : 'down',
    );
  }

  // 2️⃣ 이벤트 결과 전송 (POST)
  Future<void> submitEventResult(bool success, int userNo, {bool needsAuth = false}) async {
    final headers = await _getHeaders(needsAuth: needsAuth);

    final response = await http.post(
      Uri.parse('$baseUrl/api/btcEvent'),
      headers: headers,
      body: jsonEncode({
        'result': success ? 'success' : 'fail',
        'userNo': userNo.toString(),
      }),
    );

    print('btcEvent status = ${response.statusCode}');
    print('btcEvent body = ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('이벤트 전송 실패');
    }
  }
}