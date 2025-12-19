// 2025/12/18 - 포인트 조회 서비스 - 작성자: 진원
// 2025/12/18 - JWT 토큰 인증 추가 - 작성자: 진원
// 2025/12/19 - 에러 처리 및 디버그 로그 추가 - 작성자: 진원
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/point.dart';
import 'token_storage_service.dart';

class PointService {
  final String baseUrl = "http://10.0.2.2:8080/busanbank";
  final TokenStorageService _tokenStorage = TokenStorageService();

  // 포인트 조회
  Future<Point> getUserPoints(int userNo) async {
    try {
      final token = await _tokenStorage.readToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      print('[DEBUG] 포인트 조회 요청 - userNo: $userNo'); // 2025/12/19 - 디버그 로그 추가 - 작성자: 진원
      print('[DEBUG] 포인트 조회 URL: $baseUrl/api/flutter/points/user/$userNo'); // 2025/12/19 - 디버그 로그 추가 - 작성자: 진원

      final response = await http.get(
        Uri.parse('$baseUrl/api/flutter/points/user/$userNo'),
        headers: headers,
      );

      print('[DEBUG] 포인트 조회 응답 코드: ${response.statusCode}'); // 2025/12/19 - 디버그 로그 추가 - 작성자: 진원
      print('[DEBUG] 포인트 조회 응답 본문: ${response.body}'); // 2025/12/19 - 디버그 로그 추가 - 작성자: 진원

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Point.fromJson(data);
      } else {
        throw Exception('포인트 조회 실패: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('[ERROR] 포인트 조회 예외: $e'); // 2025/12/19 - 디버그 로그 추가 - 작성자: 진원
      rethrow;
    }
  }
}
