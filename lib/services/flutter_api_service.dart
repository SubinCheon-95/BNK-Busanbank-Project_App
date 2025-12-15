// lib/service/flutter_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/branch.dart';
import '../model/employee.dart';
import '../model/product_terms.dart';
import '../model/user_coupon.dart';
import '../model/product_join_request.dart';

/// 🔥 Flutter 전용 API 서비스
///
/// Flutter 앱에서 사용하는 모든 API 호출을 담당
/// - 지점 조회
/// - 직원 조회
/// - 약관 조회
/// - 쿠폰 조회
/// - 포인트 조회
/// - 상품 가입
class FlutterApiService {
  final String baseUrl;

  FlutterApiService(this.baseUrl);

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 1. 지점 목록 조회
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// 전체 지점 목록 조회
  ///
  /// GET /api/flutter/branches
  Future<List<Branch>> getBranches() async {
    final uri = Uri.parse('$baseUrl/flutter/branches');
    print('[DEBUG] getBranches URL = $uri');

    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('지점 조회 실패: ${res.statusCode} / ${res.body}');
    }

    final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
    return data.map((e) => Branch.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 2. 직원 목록 조회
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// 지점별 직원 목록 조회
  ///
  /// GET /api/flutter/employees?branchId={branchId}
  Future<List<Employee>> getEmployees(int branchId) async {
    final uri = Uri.parse('$baseUrl/flutter/employees?branchId=$branchId');
    print('[DEBUG] getEmployees URL = $uri');

    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('직원 조회 실패: ${res.statusCode} / ${res.body}');
    }

    final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
    return data.map((e) => Employee.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 3. 약관 조회
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
  // 4. 쿠폰 조회
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// 사용자 쿠폰 조회 (사용 가능한 것만)
  ///
  /// GET /api/flutter/coupons/user/{userNo}
  Future<List<UserCoupon>> getUserCoupons(int userNo) async {
    final uri = Uri.parse('$baseUrl/flutter/coupons/user/$userNo');
    print('[DEBUG] getUserCoupons URL = $uri');

    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('쿠폰 조회 실패: ${res.statusCode} / ${res.body}');
    }

    final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
    return data.map((e) => UserCoupon.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 5. 포인트 조회
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// 사용자 포인트 조회
  ///
  /// GET /api/flutter/points/user/{userNo}
  ///
  /// Response:
  /// {
  ///   "userNo": 231837269,
  ///   "totalPoints": 1500,
  ///   "availablePoints": 1200,
  ///   "usedPoints": 300
  /// }
  Future<Map<String, dynamic>> getUserPoints(int userNo) async {
    final uri = Uri.parse('$baseUrl/flutter/points/user/$userNo');
    print('[DEBUG] getUserPoints URL = $uri');

    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('포인트 조회 실패: ${res.statusCode} / ${res.body}');
    }

    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 6. 게스트 가입 (로그인 전)
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

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 7. 인증 가입 (로그인 후) - TODO
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// 인증 상품 가입 (로그인 후 - 실제 사용자)
  ///
  /// POST /api/flutter/join/auth
  ///
  /// TODO: 로그인 기능 구현 후 작성
  Future<void> joinAsAuth(ProductJoinRequest request) async {
    final uri = Uri.parse('$baseUrl/flutter/join/auth');

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(request.toJson()),
    );

    if (res.statusCode != 200) {
      throw Exception('가입 실패: ${res.body}');
    }
  }
}