

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorageService {



  // JWT 저장소
  final _tokenStorage = const FlutterSecureStorage();

  static const _accessTokenKey = 'accessToken';

  Future<void> saveToken(String token) async {
    await _tokenStorage.write(key: _accessTokenKey, value: token);
  }

  Future<void> deleteToken() async {
    await _tokenStorage.delete(key: _accessTokenKey);
  }

  Future<String?> readToken() async {
    return await _tokenStorage.read(key: _accessTokenKey);
  }
}