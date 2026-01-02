import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:tkbank/screens/member/find/find_pw_screen.dart';
import 'package:tkbank/screens/member/login_screen.dart';

class FindIdResultScreen extends StatelessWidget {
  final String userId;
  final String userName;

  const FindIdResultScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [

            /// 🔹 중앙 영역 (진짜 중앙)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // ⭐ 핵심
                    children: [

                      /// ✅ 체크 아이콘
                      Container(
                          width: 130,
                          height: 130,
                          child: Lottie.asset('assets/lottie/TickSuccess.json'),

                      ),

                      const SizedBox(height: 16),

                      /// 타이틀
                      const Text(
                        '아이디 찾기 완료',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        '${userName}님의 아이디는',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// 🧾 아이디 카드
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  userId,
                                  style: const TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 20),
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: userId),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('아이디가 복사되었습니다.'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '아이디는 대소문자를 구분합니다.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey
                              ),
                            ),
                          ],
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
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FindPwScreen(),
                              ),
                            );
                          },
                          child: const Text('비밀번호 재설정'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                          child: const Text('아이디로 로그인'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

  }
}
