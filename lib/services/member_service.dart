/*
  날짜 : 2025/12/15
  내용 : 회원 관련 기능 서비스 추가
  작성자 : 오서정
*/
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tkbank/models/term.dart';
import '../models/user_profile.dart';
import 'token_storage_service.dart';

// 2025/12/18 - 프로필/설정 관련 메서드 추가 - 작성자: 진원
// 2025/12/18 - JWT 토큰 인증 추가 - 작성자: 진원
class MemberService{

  final String baseUrl = "http://10.0.2.2:8080/busanbank";
  final TokenStorageService _tokenStorage = TokenStorageService();

  /// JWT 토큰 헤더 생성
  Future<Map<String, String>> _getHeaders({bool needsAuth = false}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (needsAuth) {
      final token = await _tokenStorage.readToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<Map<String, dynamic>> login(String userId, String userPw) async {

    try {
      final response = await http.post(
          Uri.parse('$baseUrl/api/member/login'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "userId": userId,
            "userPw": userPw
          })
      );

      if(response.statusCode == 200){
         return jsonDecode(response.body);
      }else{
        throw Exception(response.statusCode);
      }

    }catch(err){
      throw Exception('예외발생 : $err');
    }
  }

  Future<List<Term>> fetchTerms() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/member/terms'),
      );

      print('statusCode = ${response.statusCode}');
      print('body = ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print('decoded runtimeType = ${decoded.runtimeType}');

        final List list = decoded;
        return list.map((e) => Term.fromJson(e)).toList();
      } else {
        throw Exception('약관 조회 실패: ${response.statusCode}');
      }
    } catch (err) {
      print('fetchTerms error = $err');
      throw Exception('약관 조회 예외 발생: $err');
    }
  }

  Future<void> register(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/member/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (res.statusCode != 200) {
      throw Exception('회원가입 실패');
    }
  }


  /// 1️⃣ 인증번호 발송
  Future<String> sendHpCode(String hp) async {
    final res = await http.post(
      Uri.parse('$baseUrl/member/hp/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'hp': hp,
        'mode': 'app',
      }),
    );

    if (res.statusCode == 200) {
      return utf8.decode(res.bodyBytes); // ✅ "인증 코드 발송 완료"
    } else {
      throw Exception(utf8.decode(res.bodyBytes)); // ✅ 서버 메시지 그대로
    }
  }

  /// 2️⃣ 인증번호 검증
  Future<bool> verifyHpCode({
    required String hp,
    required String code,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/member/hp/code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'hp': hp,
        'code': code,
        'mode': 'app',
      }),
    );

    final data = jsonDecode(res.body);
    return data['isMatched'] == true;
  }

  /// 🔹 중복 검사 (userId / email / hp)
  Future<bool> isDuplicated({
    required String type,
    required String value,
  }) async {
    final res = await http.get(
      Uri.parse('$baseUrl/member/$type/$value'),
    );

    if (res.statusCode != 200) {
      throw Exception('중복 검사 실패');
    }

    final data = jsonDecode(res.body);
    return data['count'] > 0;
  }

  // 2025/12/18 - 사용자 프로필 조회 - 작성자: 진원
  Future<UserProfile> getUserProfile(int userNo) async {
    final headers = await _getHeaders(needsAuth: true);
    final response = await http.get(
      Uri.parse('$baseUrl/api/flutter/profile/$userNo'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return UserProfile.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('프로필 조회 실패: ${response.statusCode}');
    }
  }

  // 2025/12/18 - 사용자 정보 수정 - 작성자: 진원
  Future<void> updateUserInfo({
    required String userId,
    required String email,
    required String hp,
    String? zip,
    String? addr1,
    String? addr2,
  }) async {
    final token = await _tokenStorage.readToken();
    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.post(
      Uri.parse('$baseUrl/my/modify'),
      headers: headers,
      body: {
        'userId': userId,
        'email': email,
        'hp1': hp.substring(0, 3),
        'hp2': hp.substring(3, 7),
        'hp3': hp.substring(7),
        if (zip != null) 'zip': zip,
        if (addr1 != null) 'addr1': addr1,
        if (addr2 != null) 'addr2': addr2,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('정보 수정 실패');
    }
  }

  // 2025/12/18 - 비밀번호 변경 - 작성자: 진원
  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await _tokenStorage.readToken();
    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.post(
      Uri.parse('$baseUrl/my/change'),
      headers: headers,
      body: {
        'userId': userId,
        'pw': currentPassword,
        'userPw': newPassword,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('비밀번호 변경 실패');
    }
  }

  // 2025/12/18 - 회원 탈퇴 - 작성자: 진원
  Future<void> withdrawAccount({
    required String userId,
    required String password,
  }) async {
    final token = await _tokenStorage.readToken();
    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.post(
      Uri.parse('$baseUrl/my/withdraw'),
      headers: headers,
      body: {
        'userId': userId,
        'userPw': password,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('회원 탈퇴 실패');
    }
  }
}

