/*
  날짜 : 2025/12/16
  내용 : 사용자 정보 저장 기능 추가, shasha + test 병합
  작성자 : 진원, 수진
*/
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tkbank/services/member_service.dart';
import 'package:tkbank/services/token_storage_service.dart';

class AuthProvider with ChangeNotifier {
  final _tokenStorageService = TokenStorageService();
  final _storage = const FlutterSecureStorage();
  final _memberService = MemberService();

  // 로그인 상태
  bool _isLoggedIn = false;

  // 토큰 저장 (shasha 호환)
  String? _accessToken;
  String? _refreshToken;

  // 사용자 정보
  int? _userNo;
  String? _userId;
  String? _userName;
  String? _role;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  int? get userNo => _userNo;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get role => _role;

  AuthProvider() {
    // 앱 실행 시 로그인 여부 검사
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final token = await _tokenStorageService.readToken();

    if (token != null) {
      _isLoggedIn = true;
      _accessToken = token;
      _refreshToken = await _storage.read(key: 'refreshToken');

      // 저장된 사용자 정보 불러오기
      final userNoStr = await _storage.read(key: 'userNo');
      _userNo = userNoStr != null ? int.tryParse(userNoStr) : null;
      _userId = await _storage.read(key: 'userId');
      _userName = await _storage.read(key: 'userName');
      _role = await _storage.read(key: 'role');

      // 해당 Provider를 구독하고 있는 Consumer 알림
      notifyListeners();
    }
  }

  // shasha 방식: userId, userPw로 로그인
  Future<void> login(String userId, String userPw) async {
    try {
      final jsonData = await _memberService.login(userId, userPw);

      final accessToken = jsonData['accessToken'];
      final userNo = jsonData['userNo'];
      final userIdFromApi = jsonData['userId'] ?? userId;
      final userName = jsonData['userName'] ?? '';
      final role = jsonData['role'] ?? 'USER';
      final refreshToken = jsonData['refreshToken'];

      if (accessToken != null && userNo != null) {
        // 메모리에 저장 (shasha 호환)
        _accessToken = accessToken;
        _refreshToken = refreshToken;
        _userNo = userNo as int;
        _userId = userIdFromApi;
        _userName = userName;
        _role = role;

        // 암호화 저장소에 저장 (test 방식)
        await _tokenStorageService.saveToken(accessToken);
        await _storage.write(key: 'userNo', value: userNo.toString());
        await _storage.write(key: 'userId', value: userIdFromApi);
        await _storage.write(key: 'userName', value: userName);
        await _storage.write(key: 'role', value: role);
        if (refreshToken != null) {
          await _storage.write(key: 'refreshToken', value: refreshToken);
        }

        _isLoggedIn = true;
        notifyListeners();
      } else {
        throw Exception('로그인 응답에 필수 정보가 없습니다');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _tokenStorageService.deleteToken();

    // 사용자 정보 삭제
    await _storage.delete(key: 'userNo');
    await _storage.delete(key: 'userId');
    await _storage.delete(key: 'userName');
    await _storage.delete(key: 'role');
    await _storage.delete(key: 'refreshToken');

    _isLoggedIn = false;
    _accessToken = null;
    _refreshToken = null;
    _userNo = null;
    _userId = null;
    _userName = null;
    _role = null;

    notifyListeners();
  }
}