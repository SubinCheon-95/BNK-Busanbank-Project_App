/*
  날짜 : 2025/12/15
  내용 : 회원 관련 기능 서비스 추가
  작성자 : 오서정
*/
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tkbank/models/simple_login_result.dart';
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

  // 2025/12/18 - 약관 기능 - 작성자: 오서정
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

  // 2025/12/18 - 회원가입 기능 - 작성자: 오서정
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


  // 2025/12/18 - 휴대폰 인증 기능 - 작성자: 오서정
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

  // 2025/12/18 - 사용자 정보 중복검사 - 작성자: 오서정
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

  // 2025/12/18 - 아이디 찾기 기능 - 작성자: 오서정
  Future<Map<String, dynamic>> findUserIdByHp({required String userName, required String hp,}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/member/find/id/hp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userName': userName,
        'hp': hp,
      }),
    );
// 2025/01/04 - 아이디/비밀번호 찾기 실패 시 수정 - 작성자: 오서정
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode != 200) {
      throw Exception(decoded['message'] ?? '아이디 찾기에 실패했습니다.');
    }

    return decoded;
  }

  // 2025/12/18 - 비밀번호 찾기 기능 - 작성자: 오서정
  Future<void> verifyUserForPw({
    required String userName,
    required String userId,
    required String hp,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/member/find/pw/hp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userName': userName,
        'userId': userId,
        'hp': hp,
      }),
    );
  // 2025/01/04 - 아이디/비밀번호 찾기 실패 시 수정 - 작성자: 오서정
    // ✅ 200이면 그냥 성공 (body 없어도 OK)
    if (res.statusCode == 200) return;

    // ✅ 실패(400)는 JSON(message) 내려오니까 그때만 decode
    final bodyStr = utf8.decode(res.bodyBytes).trim();
    if (bodyStr.isNotEmpty) {
      final decoded = jsonDecode(bodyStr);
      throw Exception(decoded['message'] ?? '비밀번호 찾기에 실패했습니다.');
    }

    throw Exception('비밀번호 찾기에 실패했습니다.');
  }

  // 2025/12/18 - 비밀번호 재설정 기능 - 작성자: 오서정
  Future<void> resetPassword({
    required String userId,
    required String newPw,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/member/find/pw/reset'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'userPw': newPw,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('비밀번호 변경 실패');
    }
  }
  // 2025/12/18 - 사용자 프로필 조회 - 작성자: 진원
  // 2025/12/19 - 에러 처리 및 디버그 로그 추가 - 작성자: 진원
  Future<UserProfile> getUserProfile(int userNo) async {
    try {
      final headers = await _getHeaders(needsAuth: true);

      print('[DEBUG] 프로필 조회 요청 - userNo: $userNo'); // 2025/12/19 - 디버그 로그 추가 - 작성자: 진원
      print('[DEBUG] 프로필 조회 URL: $baseUrl/api/flutter/profile/$userNo'); // 2025/12/19 - 디버그 로그 추가 - 작성자: 진원

      final response = await http.get(
        Uri.parse('$baseUrl/api/flutter/profile/$userNo'),
        headers: headers,
      );

      print('[DEBUG] 프로필 조회 응답 코드: ${response.statusCode}'); // 2025/12/19 - 디버그 로그 추가 - 작성자: 진원
      print('[DEBUG] 프로필 조회 응답 본문: ${response.body}'); // 2025/12/19 - 디버그 로그 추가 - 작성자: 진원

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserProfile.fromJson(data);
      } else {
        throw Exception('프로필 조회 실패: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('[ERROR] 프로필 조회 예외: $e'); // 2025/12/19 - 디버그 로그 추가 - 작성자: 진원
      rethrow;
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

  // 2025/12/21 - 간편 로그인 기능 추가 - 작성자: 오서정
  Future<SimpleLoginResult> simpleLogin(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/member/simple-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return SimpleLoginResult.fromJson(json);
    } else {
      throw Exception('간편 로그인 실패');
    }
  }
// 2026/01/02 - 신분증 OCR 추가 - 작성자: 오서정
  Future<String> idOcrByVision({required String base64}) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/api/member/id-ocr'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({'base64': base64}),
    );

    if (resp.statusCode != 200) {
      throw Exception('id-ocr failed: ${resp.statusCode} ${resp.body}');
    }

    final decoded = jsonDecode(resp.body);
    return (decoded['text'] ?? '').toString();
  }

  Future<bool> verifyIdWithDb({
    required String userName,
    required String rrn,
  }) async {
    final headers = await _getHeaders(needsAuth: true);

    final resp = await http.post(
      Uri.parse('$baseUrl/api/member/id-verify'),
      headers: headers,
      body: jsonEncode({
        'userName': userName,
        'rrn': rrn,
      }),
    );

    if (resp.statusCode != 200) {
      throw Exception('id-verify failed: ${resp.statusCode} ${resp.body}');
    }

    final decoded = jsonDecode(resp.body);
    return decoded['matched'] == true;
  }

  // 2026/01/02 - OTP 핸드폰 인증 추가 - 작성자: 오서정
  Future<String> sendOtpHpCode({required String hp}) async {
    final headers = await _getHeaders(needsAuth: true);

    final res = await http.post(
      Uri.parse('$baseUrl/api/member/otp/hp/send'),
      headers: headers,
      body: jsonEncode({'hp': hp}),
    );

    if (res.statusCode == 200) {
      return utf8.decode(res.bodyBytes);
    } else {
      throw Exception(utf8.decode(res.bodyBytes));
    }
  }

  Future<bool> verifyOtpHpCode({
    required String hp,
    required String code,
  }) async {
    final headers = await _getHeaders(needsAuth: true);

    final res = await http.post(
      Uri.parse('$baseUrl/api/member/otp/hp/verify'),
      headers: headers,
      body: jsonEncode({'hp': hp, 'code': code}),
    );

    if (res.statusCode != 200) return false;

    final data = jsonDecode(res.body);
    return data['isMatched'] == true;
  }
}

