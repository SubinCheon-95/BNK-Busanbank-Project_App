/*
  날짜: 2025/12/21
  내용: 생체인증 추가
  이름: 오서정
 */
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> canUseBiometrics() async {
    return await _auth.canCheckBiometrics ||
        await _auth.isDeviceSupported();
  }

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: '지문으로 인증하세요',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      print('[BiometricAuth] error: $e');
      return false;
    }
  }
}

