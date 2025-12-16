/*
  날짜 : 2025/12/15
  내용 : 로그인 페이지 추가
  작성자 : 오서정
*/
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:tkbank/providers/auth_provider.dart';
import 'package:tkbank/screens/member/terms_screen.dart';
import 'package:tkbank/services/member_service.dart';
import 'package:tkbank/services/token_storage_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();

  final service = MemberService();

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
      final jsonData = await service.login(userId, userPw);
      print('[DEBUG] ============= 로그인 성공 =============');
      print('[DEBUG] 응답 데이터: $jsonData');

      final accessToken = jsonData['accessToken'];
      // 2025/12/16 - 로그인 응답에서 사용자 정보 추출 - 작성자: 진원
      final userNo = jsonData['userNo']?.toString() ?? '';
      final userIdFromApi = jsonData['userId']?.toString() ?? userId;
      final userName = jsonData['userName']?.toString() ?? '';
      final role = jsonData['role']?.toString() ?? 'USER';

      print('[DEBUG] accessToken: ${accessToken != null ? "있음" : "없음"}');
      print('[DEBUG] userNo: $userNo');
      print('[DEBUG] userName: $userName');

      log('accessToken : $accessToken');

      if (accessToken != null && userNo.isNotEmpty) {
        print('[DEBUG] 토큰 길이: ${accessToken.length}');
        print('[DEBUG] 토큰 시작 20자: ${accessToken.substring(0, 20)}...');

        if (mounted) {
          await context.read<AuthProvider>().login(
            accessToken,
            userNo: userNo,
            userId: userIdFromApi,
            userName: userName,
            role: role,
          );
          print('[DEBUG] AuthProvider.login() 호출 완료!');

          // ✅ 저장 확인
          final savedToken = await TokenStorageService().readToken();
          print('[DEBUG] 저장 확인: ${savedToken != null ? "성공" : "실패"}');
          if (savedToken != null) {
            print('[DEBUG] 저장된 토큰 시작 20자: ${savedToken.substring(0, 20)}...');
          }

          print('[DEBUG] isLoggedIn: ${context.read<AuthProvider>().isLoggedIn}');
          print('[DEBUG] userNo: ${context.read<AuthProvider>().userNo}');

          Navigator.of(context).pop();
        }
      } else {
        print('[ERROR] 로그인 응답에 필수 정보가 없습니다.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('로그인 정보가 올바르지 않습니다')),
          );
        }
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
                  '딸깍 은행',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: purple900,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 30),

                // 아이디
                TextField(
                  controller: _idController,
                  decoration: _inputDecoration('아이디'),
                ),

                const SizedBox(height: 16),

                // 비밀번호
                TextField(
                  controller: _pwController,
                  obscureText: true,
                  decoration: _inputDecoration('비밀번호'),
                ),

                const SizedBox(height: 24),

                // 로그인 버튼
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

                const SizedBox(height: 20),

                // 하단 메뉴 (아이디 찾기 | 회원가입 | 비밀번호 찾기)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        // TODO: 아이디 찾기
                      },
                      child: const Text(
                        '아이디 찾기',
                        style: TextStyle(color: purple900),
                      ),
                    ),

                    TextButton(
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
                        ),
                      ),
                    ),

                    TextButton(
                      onPressed: () {
                        // TODO: 비밀번호 찾기
                      },
                      child: const Text(
                        '비밀번호 찾기',
                        style: TextStyle(color: purple900),
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
}