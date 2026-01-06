/*
  날짜: 2025/12/30
  내용: OTP PIN 저장 서비스
  작성자: 오서정
*/
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OtpPinStorageService {
  final _storage = const FlutterSecureStorage();

  // 해시 키만 사용
  static const _hashKey = 'otp_pin_hash';

  String _hash(String pin) => sha256.convert(utf8.encode(pin)).toString();

  /// OTP PIN 저장 (해시)
  Future<void> saveOtpPin(String pin) async {
    await _storage.write(key: _hashKey, value: _hash(pin));
  }

  /// OTP PIN 존재 여부
  Future<bool> hasOtpPin() async {
    return (await _storage.read(key: _hashKey)) != null;
  }

  /// OTP PIN 검증 (해시 비교)
  Future<bool> verifyOtpPin(String inputPin) async {
    final savedHash = await _storage.read(key: _hashKey);
    if (savedHash == null) return false;

    return savedHash == _hash(inputPin);
  }

  /// OTP PIN 삭제
  Future<void> clearOtpPin() async {
    await _storage.delete(key: _hashKey);
  }
}