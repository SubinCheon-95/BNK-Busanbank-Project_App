/*
  날짜: 2025/12/21
  내용: 간편로그인 기능 저장
  이름: 오서정
 */
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SimpleLoginStorageService {
  static const _storage = FlutterSecureStorage();
  static const _key = 'simple_login_userId';

  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _key, value: userId);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _key);
  }

  Future<bool> hasUserId() async {
    return (await getUserId()) != null;
  }

  Future<void> clear() async {
    await _storage.delete(key: _key);
  }
}
