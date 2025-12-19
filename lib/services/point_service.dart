// 2025/12/18 - 포인트 조회 서비스 - 작성자: 진원
// 2025/12/18 - JWT 토큰 인증 추가 - 작성자: 진원
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/point.dart';
import 'token_storage_service.dart';

class PointService {
  final String baseUrl = "http://10.0.2.2:8080/busanbank";
  final TokenStorageService _tokenStorage = TokenStorageService();

  // 포인트 조회
  Future<Point> getUserPoints(int userNo) async {
    final token = await _tokenStorage.readToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.get(
      Uri.parse('$baseUrl/api/flutter/points/user/$userNo'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return Point.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('포인트 조회 실패');
    }
  }
}
