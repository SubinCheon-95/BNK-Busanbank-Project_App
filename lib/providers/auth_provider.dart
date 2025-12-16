/*
  날짜 : 2025/12/15
  내용 : 인증 관련 provider 추가
  작성자 : 오서정

  날짜 : 2025/12/16
  내용 : 사용자 정보 저장 기능 추가
  작성자 : 진원
*/
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tkbank/services/token_storage_service.dart';

class AuthProvider with ChangeNotifier{

  final _tokenStorageService = TokenStorageService();
  final _storage = const FlutterSecureStorage();

  // 로그인 여부 상태
  bool _isLoggedIn = false;

  // 사용자 정보
  String? _userNo;
  String? _userId;
  String? _userName;
  String? _role;

  bool get isLoggedIn => _isLoggedIn;
  String? get userNo => _userNo;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get role => _role;

  AuthProvider(){
    // 앱 실행 시 로그인 여부 검사
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final token = await _tokenStorageService.readToken();

    if(token != null){
      _isLoggedIn = true;

      // 저장된 사용자 정보 불러오기
      _userNo = await _storage.read(key: 'userNo');
      _userId = await _storage.read(key: 'userId');
      _userName = await _storage.read(key: 'userName');
      _role = await _storage.read(key: 'role');

      // 해당 Provider를 구독하고 있는 Consumer 알림
      notifyListeners();
    }
  }

  Future<void> login(String token, {
    required String userNo,
    required String userId,
    required String userName,
    required String role,
  }) async {
    await _tokenStorageService.saveToken(token);

    // 사용자 정보 저장
    await _storage.write(key: 'userNo', value: userNo);
    await _storage.write(key: 'userId', value: userId);
    await _storage.write(key: 'userName', value: userName);
    await _storage.write(key: 'role', value: role);

    _isLoggedIn = true;
    _userNo = userNo;
    _userId = userId;
    _userName = userName;
    _role = role;

    // 해당 Provider를 구독하고 있는 Consumer 알림
    notifyListeners();
  }

  Future<void> logout() async {
    await _tokenStorageService.deleteToken();

    // 사용자 정보 삭제
    await _storage.delete(key: 'userNo');
    await _storage.delete(key: 'userId');
    await _storage.delete(key: 'userName');
    await _storage.delete(key: 'role');

    _isLoggedIn = false;
    _userNo = null;
    _userId = null;
    _userName = null;
    _role = null;

    notifyListeners(); // 해당 Provider를 구독하고 있는 Consumer 알림

  }





}