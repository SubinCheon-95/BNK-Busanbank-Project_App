import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tkbank/services/token_storage_service.dart';

class CameraPointService {
  final String baseUrl;
  final TokenStorageService _tokenStorage = TokenStorageService();

  CameraPointService({required this.baseUrl});

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

  /// ✅ POST 요청 헬퍼 (인증 여부 선택 가능)
  Future<dynamic> _post(String path, dynamic body, {bool needsAuth = false}) async {
    final headers = await _getHeaders(needsAuth: needsAuth);
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('POST $path failed: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> checkImage(int userId) async {
    return await _post(
      '/camera/check',
      {'userId': userId},
      needsAuth: true,
    );
  }
}