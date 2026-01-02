/*
  날짜: 2025/12/22
  내용: 비밀번호 찾기 결과 UI 수정
  이름: 오서정
*/
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:tkbank/screens/member/login_screen.dart';

class FindPwResultScreen extends StatelessWidget {
  const FindPwResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [

            /// 🔹 중앙 영역
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      /// ✅ 성공 애니메이션
                      SizedBox(
                        width: 130,
                        height: 130,
                        child: Lottie.asset(
                          'assets/lottie/TickSuccess.json',
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// 타이틀
                      const Text(
                        '비밀번호 변경 완료',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        '새 비밀번호로 로그인해 주세요.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            /// 🔹 하단 버튼 영역 (고정)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                  child: const Text('로그인하러 가기'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
