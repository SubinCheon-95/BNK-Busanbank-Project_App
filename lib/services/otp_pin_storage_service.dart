/*
  날짜: 2025/12/30
  내용: OTP PIN 저장 서비스
  작성자: 오서정
*/
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OtpPinStorageService {
  final _storage = const FlutterSecureStorage();
  static const _key = 'otp_pin';

  Future<void> saveOtpPin(String pin) async {
    await _storage.write(key: _key, value: pin);
  }

  Future<bool> hasOtpPin() async {
    final pin = await _storage.read(key: _key);
    return pin != null;
  }

  Future<bool> verifyOtpPin(String inputPin) async {
    final storedPin = await _storage.read(key: _key);
    return storedPin != null && storedPin == inputPin;
  }

  Future<void> clearOtpPin() async {
    await _storage.delete(key: _key);
  }
}
