/*
  날짜 : 2025/12/16
  내용 : 사용자 정보 저장 기능 추가, shasha + test 병합
  작성자 : 진원, 수진
*/
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tkbank/services/biometric_storage_service.dart';
import 'package:tkbank/services/member_service.dart';
import 'package:tkbank/services/pin_storage_service.dart';
import 'package:tkbank/services/simple_login_storage_service.dart';
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
  String? _nickname;      // 2025/12/23 - 닉네임 추가 - 작성자: 진원
  String? _avatarImage;   // 2025/12/23 - 아바타 이미지 추가 - 작성자: 진원

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  int? get userNo => _userNo;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get role => _role;
  String? get nickname => _nickname;        // 2025/12/23 - 닉네임 getter - 작성자: 진원
  String? get avatarImage => _avatarImage;  // 2025/12/23 - 아바타 이미지 getter - 작성자: 진원

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
      _nickname = await _storage.read(key: 'nickname');           // 2025/12/23 - 닉네임 로드 - 작성자: 진원
      _avatarImage = await _storage.read(key: 'avatarImage');     // 2025/12/23 - 아바타 이미지 로드 - 작성자: 진원

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

        // 2025/12/23 - 프로필 정보도 저장 - 작성자: 진원
        final nickname = jsonData['nickname'];
        final avatarImage = jsonData['avatarImage'];
        if (nickname != null) {
          _nickname = nickname;
          await _storage.write(key: 'nickname', value: nickname);
        }
        if (avatarImage != null) {
          _avatarImage = avatarImage;
          await _storage.write(key: 'avatarImage', value: avatarImage);
        }

        // 2025/12/21 - 로그인 시 아이디 간편 로그인 저장소 저장 - 작성자: 오서정
        await _simpleLoginStorage.saveUserId(_userId!);

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
    await _storage.delete(key: 'nickname');      // 2025/12/23 - 닉네임 삭제 - 작성자: 진원
    await _storage.delete(key: 'avatarImage');   // 2025/12/23 - 아바타 이미지 삭제 - 작성자: 진원

    _isLoggedIn = false;
    _accessToken = null;
    _refreshToken = null;
    _userNo = null;
    _userId = null;
    _userName = null;
    _role = null;
    _nickname = null;       // 2025/12/23 - 닉네임 초기화 - 작성자: 진원
    _avatarImage = null;    // 2025/12/23 - 아바타 이미지 초기화 - 작성자: 진원

    notifyListeners();
  }

  // 2025/12/21 - 간편 로그인 연동 추가, 간편 로그인 토큰 여부 추가 - 작성자: 오서정
  Future<void> loginWithStoredToken() async {
    final token = await _tokenStorageService.readToken();

    if (token == null) {
      throw Exception('저장된 로그인 정보가 없습니다.');
    }

    _accessToken = token;
    _refreshToken = await _storage.read(key: 'refreshToken');

    final userNoStr = await _storage.read(key: 'userNo');
    _userNo = userNoStr != null ? int.tryParse(userNoStr) : null;
    _userId = await _storage.read(key: 'userId');
    _userName = await _storage.read(key: 'userName');
    _role = await _storage.read(key: 'role');
    _nickname = await _storage.read(key: 'nickname');           // 2025/12/23 - 닉네임 로드 - 작성자: 진원
    _avatarImage = await _storage.read(key: 'avatarImage');     // 2025/12/23 - 아바타 이미지 로드 - 작성자: 진원

    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> loginWithSimpleAuth(String userId) async {
    final result = await _memberService.simpleLogin(userId);

    _accessToken = result.accessToken;
    _refreshToken = result.refreshToken;
    _userNo = result.userNo;
    _userId = result.userId;
    _userName = result.userName;
    _role = result.role;

    // ✅ 이게 핵심
    await _tokenStorageService.saveToken(_accessToken!);
    await _storage.write(key: 'refreshToken', value: _refreshToken);
    await _storage.write(key: 'userNo', value: _userNo.toString());
    await _storage.write(key: 'userId', value: _userId);
    await _storage.write(key: 'userName', value: _userName ?? '');
    await _storage.write(key: 'role', value: _role ?? 'USER');

    // 2025/12/23 - 프로필 정보도 저장 - 작성자: 진원
    if (_nickname != null) {
      await _storage.write(key: 'nickname', value: _nickname);
    }
    if (_avatarImage != null) {
      await _storage.write(key: 'avatarImage', value: _avatarImage);
    }

    _isLoggedIn = true;
    notifyListeners();
  }

  // 2025/12/23 - 프로필 업데이트 메서드 추가 - 작성자: 진원
  Future<void> updateProfile({String? nickname, String? avatarImage}) async {
    if (nickname != null) {
      _nickname = nickname;
      await _storage.write(key: 'nickname', value: nickname);
    }
    if (avatarImage != null) {
      _avatarImage = avatarImage;
      await _storage.write(key: 'avatarImage', value: avatarImage);
    }
    notifyListeners();
  }


  Future<bool> hasStoredLoginInfo() async {
    final token = await _tokenStorageService.readToken();
    final refresh = await _storage.read(key: 'refreshToken');
    final userNo = await _storage.read(key: 'userNo');

    return token != null && refresh != null && userNo != null;
  }

  final _simpleLoginStorage = SimpleLoginStorageService();

  Future<bool> hasSimpleLoginBaseInfo() {
    return _simpleLoginStorage.hasUserId();
  }



}