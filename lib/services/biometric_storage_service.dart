/*
  날짜: 2025/12/21
  내용: 생체인증 저장
  이름: 오서정
 */
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricStorageService {
  static const _storage = FlutterSecureStorage();
  static const _key = 'biometric_enabled';

  Future<void> enable() async {
    await _storage.write(key: _key, value: 'true');
  }

  Future<void> disable() async {
    await _storage.delete(key: _key);
  }

  Future<bool> isEnabled() async {
    final value = await _storage.read(key: _key);
    return value == 'true';
  }
}
