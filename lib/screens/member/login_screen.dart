/*
  날짜 : 2025/12/15
  내용 : 로그인 페이지 추가
  작성자 : 오서정

  날짜 : 2025/12/16
  내용 : AuthProvider 병합  - 진원, 수진
*/
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:provider/provider.dart';
import 'package:tkbank/providers/auth_provider.dart';
import 'package:tkbank/screens/member/find_id_screen.dart';
import 'package:tkbank/screens/member/find_pw_screen.dart';
import 'package:tkbank/screens/member/terms_screen.dart';
import 'package:tkbank/services/biometric_auth_service.dart';
import 'package:tkbank/services/biometric_storage_service.dart';
import 'package:tkbank/services/pin_storage_service.dart';

// 25/12/21 - 간편 로그인 기능 추가 - 작성자: 오서정
enum LoginType {
  id,
  pin,
  biometric,
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  //25/12/21 - 간편 로그인 기능 추가 - 작성자: 오서정
  LoginType _loginType = LoginType.id;
  LoginType? _pendingLoginType;
  String _inputPin = '';
  bool _biometricTried = false;

  final _idController = TextEditingController();
  final _pwController = TextEditingController();

  static const Color purple900 = Color(0xFF662382);
  static const Color purple500 = Color(0xFFBD9FCD);

  void _procLogin() async {
    final userId = _idController.text.trim();
    final userPw = _pwController.text.trim();

    if (userId.isEmpty || userPw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디와 비밀번호를 입력하세요')),
      );
      return;
    }

    try {
      // AuthProvider에서 직접 API 호출
      await context.read<AuthProvider>().login(userId, userPw);

      print('[DEBUG] AuthProvider.login() 호출 완료!');
      print('[DEBUG] isLoggedIn: ${context.read<AuthProvider>().isLoggedIn}');
      print('[DEBUG] userNo: ${context.read<AuthProvider>().userNo}');

      if (mounted) {
        Navigator.of(context).pop();
      }

    } catch (err) {
      print('[ERROR] 로그인 실패: $err');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 실패: $err')),
        );
      }
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: purple900),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: purple900, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: purple500),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2F8),
      appBar: AppBar(
        title: const Text('로그인'),
        centerTitle: true,
        backgroundColor: purple900,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),

                // 로고 or 타이틀
                const Text(
                  '로그인', // 2025/12/21 - text 수정 - 작성자: 오서정
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: purple900,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 30),

                // 2025/12/21 - 로그인 방법 간편로그인 추가 - 작성자: 오서정
                _loginTypeTabs(),

                const SizedBox(height: 20),

                if (_loginType == LoginType.id) _idLoginForm(),
                if (_loginType == LoginType.pin) _pinLoginView(),
                if (_loginType == LoginType.biometric) _biometricLoginView(),

                
                // 하단 메뉴 (아이디 찾기 | 회원가입 | 비밀번호 찾기)
                // 오버플로우 수정 - 수진
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(  // ✅ 추가!
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const FindIdScreen()),
                          );
                        },
                        child: const Text(
                          '아이디 찾기',
                          style: TextStyle(
                            color: purple900,
                            fontSize: 12,  // ✅ 14 → 12
                          ),
                        ),
                      ),
                    ),

                    Expanded(  // ✅ 추가!
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TermsScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          '회원가입',
                          style: TextStyle(
                            color: purple900,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,  // ✅ 14 → 12
                          ),
                        ),
                      ),
                    ),

                    Expanded(  // ✅ 추가!
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FindPwScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          '비밀번호 찾기',
                          style: TextStyle(
                            color: purple900,
                            fontSize: 12,  // ✅ 14 → 12
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  //2025/12/21 - 간편 로그인 기능 추가 - 오서정
  Widget _loginTypeTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: purple500.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _tab(LoginType.id, '아이디'),
          _tab(LoginType.pin, '간편비밀번호'),
          _tab(LoginType.biometric, '지문인증'),
        ],
      ),
    );
  }

  Widget _tab(LoginType type, String label) {
    final selected = _loginType == type;

    return Expanded(
      child: GestureDetector(
          onTap: () async {
            _pendingLoginType = type;
            _handleLoginTypeTap();
          },
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected ? purple900 : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _idLoginForm() {
    return Column(
      children: [
        TextField(
          controller: _idController,
          decoration: _inputDecoration('아이디'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _pwController,
          obscureText: true,
          decoration: _inputDecoration('비밀번호'),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _procLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: purple900,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              '로그인',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onPinNumberPressed(String num) async {
    if (_inputPin.length >= 6) return;

    setState(() => _inputPin += num);

    if (_inputPin.length == 6) {
      await _tryPinLogin();
    }
  }

  void _onPinDelete() {
    if (_inputPin.isEmpty) return;
    setState(() => _inputPin = _inputPin.substring(0, _inputPin.length - 1));
  }

  Future<void> _tryPinLogin() async {
    final ok = await PinStorageService().verifyPin(_inputPin);

    if (!ok) {
      setState(() => _inputPin = '');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('간편 비밀번호가 틀렸습니다')),
      );
      return;
    }

    final userId =
    await const FlutterSecureStorage().read(key: 'simple_login_userId');

    if (userId == null) {
      _showGuideDialog(
        '간편 로그인 불가',
        '아이디 로그인 후 간편 로그인을 등록해주세요.',
      );
      setState(() => _inputPin = '');
      return;
    }

    await context.read<AuthProvider>().loginWithSimpleAuth(userId);

    if (mounted) Navigator.pop(context);
  }


  Widget _pinLoginView() {
    return Column(
      children: [
        const Text(
          '간편 비밀번호 입력',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: purple900,
          ),
        ),
        const SizedBox(height: 20),
        // 🔵 PIN 입력 표시 (●●●○○○)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (i) {
            return Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < _inputPin.length ? purple900 : purple500,
              ),
            );
          }),
        ),

        _pinKeypad(),

        const SizedBox(height: 30),


      ],
    );
  }

  Widget _biometricLoginView() {
    if (!_biometricTried) {
      _biometricTried = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _tryBiometricLogin();
        }
      });
    }

    return Column(
      children: [
        const Icon(Icons.fingerprint, size: 80, color: purple900),
        const SizedBox(height: 20),
        const Text('지문 인증 중입니다...'),
      ],
    );
  }

  void _showGuideDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _loginType = LoginType.id);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _pinKeypad() {
    return Column(
      children: [
        for (var row in [
          ['1','2','3'],
          ['4','5','6'],
          ['7','8','9'],
          ['','0','⌫'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              if (key == '') return const SizedBox(width: 60);

              return IconButton(
                iconSize: 28,
                onPressed: () {
                  if (key == '⌫') {
                    _onPinDelete();
                  } else {
                    _onPinNumberPressed(key);
                  }
                },
                icon: Text(
                  key,
                  style: const TextStyle(fontSize: 22),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Future<void> _handleLoginTypeTap() async {
    final type = _pendingLoginType;
    if (type == null) return;

    final auth = context.read<AuthProvider>();

    // 🔹 PIN 탭
    if (type == LoginType.pin) {
      final hasPin = await PinStorageService().hasPin();
      final hasBaseInfo = await auth.hasSimpleLoginBaseInfo();
      //final canLogin = await auth.hasStoredLoginInfo();

      if (!hasPin || !hasBaseInfo) {
        _showGuideDialog(
          '간편 로그인 불가',
          '아이디 로그인 후 인증센터에서\n간편 비밀번호를 등록해주세요.',
        );
        _pendingLoginType = null;
        return;
      }
    }

    // 🔹 지문 탭
    if (type == LoginType.biometric) {
      final enabled = await BiometricStorageService().isEnabled();
      final hasBaseInfo = await auth.hasSimpleLoginBaseInfo();
      //final canLogin = await auth.hasStoredLoginInfo();

      if (!enabled || !hasBaseInfo) {
        _showGuideDialog(
          '생체 인증 불가',
          '아이디 로그인 후 인증센터에서\n생체 인증을 등록해주세요.',
        );
        _pendingLoginType = null;
        return;
      }
    }


    // ✅ 여기까지 왔으면 보여줘도 됨
    setState(() {
      _loginType = type;
      _inputPin = '';
      _pendingLoginType = null;

      if (type != LoginType.biometric) {
        _biometricTried = false;
      }
    });
  }

  Future<void> _tryBiometricLogin() async {
    try {
      final success = await BiometricAuthService().authenticate();
      if (!success) return;

      final userId =
      await const FlutterSecureStorage().read(key: 'simple_login_userId');

      if (userId == null) {
        _showGuideDialog(
          '생체 인증 불가',
          '아이디 로그인 후 생체 인증을 등록해주세요.',
        );
        return;
      }

      await context.read<AuthProvider>().loginWithSimpleAuth(userId);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('생체 인증에 실패했습니다')),
      );
    }
  }



}