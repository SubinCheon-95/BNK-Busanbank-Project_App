/*
  날짜: 2025/12/21
  내용: 간편비밀번호 저장
  이름: 오서정
  수정: 2026/01/05 - 로직 정리 - 작성자: 오서정
*/
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinStorageService {
  static const _storage = FlutterSecureStorage();
  static const _pinKey = 'simple_pin_hash';

  String _hash(String pin) => sha256.convert(utf8.encode(pin)).toString();

  /// PIN 저장 (해시)
  Future<void> savePin(String pin) async {
    await _storage.write(key: _pinKey, value: _hash(pin));
  }

  /// PIN 존재 여부
  Future<bool> hasPin() async {
    return (await _storage.read(key: _pinKey)) != null;
  }

  /// PIN 검증
  Future<bool> verifyPin(String inputPin) async {
    final savedHash = await _storage.read(key: _pinKey);
    if (savedHash == null) return false;

    return savedHash == _hash(inputPin);
  }

  /// PIN 삭제
  Future<void> clearPin() async {
    await _storage.delete(key: _pinKey);
  }
}
