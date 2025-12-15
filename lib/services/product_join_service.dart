// lib/service/product_join_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/product_terms.dart';
import '../models/product_join_request.dart';

/// 🔥 상품 가입 서비스
///
/// 상품 가입 관련 모든 API 호출
class ProductJoinService {
  final String baseUrl;

  ProductJoinService(this.baseUrl);

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 약관 조회
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// 상품별 약관 조회
  ///
  /// GET /api/flutter/products/{productNo}/terms
  Future<List<ProductTerms>> getTerms(int productNo) async {
    final uri = Uri.parse('$baseUrl/flutter/products/$productNo/terms');
    print('[DEBUG] getTerms URL = $uri');

    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('약관 조회 실패: ${res.statusCode} / ${res.body}');
    }

    final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
    return data.map((e) => ProductTerms.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 게스트 가입
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// 게스트 상품 가입 (로그인 전 - 김부산 고정)
  ///
  /// POST /api/flutter/join/guest
  Future<void> joinAsGuest(ProductJoinRequest request) async {
    final uri = Uri.parse('$baseUrl/flutter/join/guest');

    print('[DEBUG] joinAsGuest URL = $uri');
    print('[DEBUG] joinAsGuest body = ${jsonEncode(request.toJson())}');

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(request.toJson()),
    );

    print('[DEBUG] joinAsGuest status = ${res.statusCode}');
    print('[DEBUG] joinAsGuest response = ${res.body}');

    if (res.statusCode != 200) {
      throw Exception('가입 실패: ${res.body}');
    }
  }
}