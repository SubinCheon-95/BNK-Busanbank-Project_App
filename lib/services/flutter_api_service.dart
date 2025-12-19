/*
  날짜 : 2025/12/15
  내용 : Flutter API 서비스 - JWT 토큰 자동 추가
  작성자 : Shasha
*/
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/branch.dart';
import '../models/employee.dart';
import '../models/product_terms.dart';
import '../models/user_coupon.dart';
import 'token_storage_service.dart';
import '../models/news_article.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import '../models/news_analysis_result.dart';

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
  final TokenStorageService _tokenStorage = TokenStorageService();

  FlutterApiService({required this.baseUrl});

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

  /// ✅ GET 요청 헬퍼 (인증 여부 선택 가능)
  Future<dynamic> _get(String path, {bool needsAuth = false}) async {
    final headers = await _getHeaders(needsAuth: needsAuth);
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('GET $path failed: ${response.statusCode}');
    }
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

  // ========================================
  // 공개 API (로그인 불필요)
  // ========================================

  /// 지점 목록 조회 (공개 API)
  Future<List<Branch>> getBranches() async {
    final data = await _get('/flutter/branches', needsAuth: false);  // 2025-12-17 - 공개 API로 수정 - 작성자: 진원
    return (data as List).map((e) => Branch.fromJson(e)).toList();
  }

  /// 지점별 직원 목록 조회 (공개 API)
  Future<List<Employee>> getEmployees(int branchId) async {
    final data = await _get('/flutter/branches/$branchId/employees', needsAuth: false);  // 2025-12-17 - 공개 API로 수정 - 작성자: 진원
    return (data as List).map((e) => Employee.fromJson(e)).toList();
  }

  /// 약관 목록 조회
  Future<List<ProductTerms>> getTerms(int productNo) async {
    final data = await _get('/flutter/products/$productNo/terms', needsAuth: false);
    return (data as List).map((e) => ProductTerms.fromJson(e)).toList();
  }

  // ========================================
  // 인증 필요 API (로그인 후 사용)
  // ========================================

  /// 쿠폰 목록 조회 (인증 필요!)
  Future<List<UserCoupon>> getCoupons(int userNo) async {
    final data = await _get('/flutter/coupons/user/$userNo', needsAuth: true);
    return (data as List).map((e) => UserCoupon.fromJson(e)).toList();
  }

  /// 포인트 조회 (인증 필요!)
  Future<int> getPoints(int userNo) async {
    final data = await _get('/flutter/points/user/$userNo', needsAuth: true);
    return data['totalPoints'] ?? 0;
  }

  /// 상품 가입 (인증 필요!)
  Future<Map<String, dynamic>> joinProduct(Map<String, dynamic> request) async {
    final response = await _post('/flutter/join/auth', request, needsAuth: true);
    print("응답 값 : $response");

    return response;
  }

  /// ✅ 쿠폰 목록 조회 (별칭)
  Future<List<UserCoupon>> getUserCoupons(int userNo) async {
    return await getCoupons(userNo);
  }

  /// ✅ 포인트 조회 (별칭, Map 반환)
  Future<Map<String, dynamic>> getUserPoints(int userNo) async {
    final points = await getPoints(userNo);
    return {'totalPoints': points};
  }

  // /// ✅ 포인트 조회 (별칭, Map 반환)
  // Future<Map<String, dynamic>> getUserPoints(int userNo) async {
  //   final data = await _get('/flutter/points/user/$userNo', needsAuth: true);
  //
  //   // ✅ Backend 응답을 그대로 반환
  //   return data;  // { "totalPoints": 2440, "availablePoints": 2440, ... }
  // }

  /// ✅ 게스트 가입 (별칭)
  Future<void> joinAsGuest(Map<String, dynamic> request) async {
    await joinProduct(request);
  }

  /// ✅ 계좌 비밀번호 검증 (인증 필요!)
  Future<Map<String, dynamic>> verifyAccountPassword({
    required int userNo,
    required String accountPassword,
  }) async {
    print('[DEBUG] verifyAccountPassword 호출');
    print('[DEBUG] userNo: $userNo');
    print('[DEBUG] accountPassword: $accountPassword');

    try {
      return await _post(
        '/flutter/verify/account-password',
        {
          'userNo': userNo,
          'accountPassword': accountPassword,
        },
        needsAuth: true,
      );
    } catch (e) {
      print('[ERROR] verifyAccountPassword 실패: $e');
      rethrow;
    }
  }

  // ========================================
  // 출석체크 및 게임 API (인증 필요)
  // ========================================

  /// ✅ 출석체크 현황 조회 (인증 필요!)
  Future<Map<String, dynamic>> getAttendanceStatus(int userNo) async {
    return await _get('/flutter/attendance/status/$userNo', needsAuth: true);
  }

  /// ✅ 출석체크 수행 (인증 필요!)
  Future<Map<String, dynamic>> checkAttendance(int userId) async {
    return await _post(
      '/flutter/attendance/check',
      {'userId': userId},
      needsAuth: true,
    );
  }

  /// ✅ 영업점 체크인 이력 조회 (인증 필요!)
  Future<Map<String, dynamic>> getCheckinHistory(int userNo) async {
    return await _get('/flutter/checkin/history/$userNo', needsAuth: true);
  }

  /// ✅ 영업점 체크인 수행 (인증 필요!)
  Future<Map<String, dynamic>> checkin({
    required int userId,
    required int branchId,
    required double latitude,
    required double longitude,
  }) async {
    return await _post(
      '/flutter/checkin',
      {
        'userId': userId,
        'branchId': branchId,
        'latitude': latitude,
        'longitude': longitude,
      },
      needsAuth: true,
    );
  }

  /// ✅ 포인트 이력 조회 (인증 필요!)
  Future<List<dynamic>> getPointHistory(int userNo) async {
    final data = await _get('/flutter/points/history/$userNo', needsAuth: true);
    return data as List<dynamic>;
  }

  /// ✅ URL 기반 뉴스 분석
  Future<NewsAnalysisResult> analyzeNewsUrl(String url) async {
    final response = await _post(
      '/flutter/news/analyze/url',
      {'url': url},
      needsAuth: false,  // 공개 API
    );
    return NewsAnalysisResult.fromJson(response);
  }

  /// ✅ 이미지 기반 뉴스 분석 (Multipart)
  Future<NewsAnalysisResult> analyzeNewsImage(File imageFile) async {
    final headers = await _getHeaders(needsAuth: false);

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/flutter/news/analyze/image'),
    );

    // 헤더 추가
    headers.forEach((key, value) {
      request.headers[key] = value;
    });

    // 파일 추가
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return NewsAnalysisResult.fromJson(data);
    } else {
      throw Exception('이미지 분석 실패: ${response.statusCode}');
    }
  }


}