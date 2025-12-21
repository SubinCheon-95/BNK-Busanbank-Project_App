/*
  날짜: 2025/12/21
  내용: 간편비밀번호 저장
  이름: 오서정
 */
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class PinStorageService {
  static const _storage = FlutterSecureStorage();
  static const _pinKey = 'simple_pin_hash';

  /// PIN 저장 (해시)
  Future<void> savePin(String pin) async {
    final hash = sha256.convert(utf8.encode(pin)).toString();
    await _storage.write(key: _pinKey, value: hash);
  }

  /// PIN 존재 여부
  Future<bool> hasPin() async {
    final value = await _storage.read(key: _pinKey);
    return value != null;
  }

  /// PIN 검증
  Future<bool> verifyPin(String inputPin) async {
    final savedHash = await _storage.read(key: _pinKey);
    if (savedHash == null) return false;

    final inputHash = sha256.convert(utf8.encode(inputPin)).toString();
    return savedHash == inputHash;
  }

  /// PIN 삭제
  Future<void> clearPin() async {
    await _storage.delete(key: _pinKey);
  }
}
