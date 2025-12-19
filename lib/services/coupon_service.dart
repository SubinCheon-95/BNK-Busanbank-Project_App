// 2025/12/18 - 쿠폰 조회/등록 서비스 - 작성자: 진원
// 2025/12/18 - JWT 토큰 인증 추가 - 작성자: 진원
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/coupon.dart';
import 'token_storage_service.dart';

class CouponService {
  final String baseUrl = "http://10.0.2.2:8080/busanbank";
  final TokenStorageService _tokenStorage = TokenStorageService();

  // 사용자 쿠폰 목록 조회
  Future<List<Coupon>> getUserCoupons(int userNo) async {
    final token = await _tokenStorage.readToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.get(
      Uri.parse('$baseUrl/api/flutter/coupons/user/$userNo'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Coupon.fromJson(json)).toList();
    } else {
      throw Exception('쿠폰 조회 실패');
    }
  }

  // 쿠폰 등록
  Future<Map<String, dynamic>> registerCoupon(String couponCode) async {
    final token = await _tokenStorage.readToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.post(
      Uri.parse('$baseUrl/my/coupon/register'),
      headers: headers,
      body: jsonEncode({'couponCode': couponCode}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? '쿠폰 등록 실패');
    }
  }
}
