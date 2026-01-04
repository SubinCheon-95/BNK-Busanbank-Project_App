import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:tkbank/screens/member/find/find_pw_screen.dart';
import 'package:tkbank/screens/member/login_screen.dart';
import 'package:tkbank/theme/app_colors.dart'; // ✅ 추가

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
    // ✅ FindIdScreen 버튼 느낌 그대로
    final primaryBtnStyle = ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      disabledBackgroundColor: AppColors.primary.withOpacity(0.3),
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );

    // ✅ Outlined도 같은 높이/라운드/폰트 맞추기
    final outlineBtnStyle = OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: BorderSide(color: AppColors.primary, width: 1.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 130,
                        height: 130,
                        child: Lottie.asset('assets/lottie/TickSuccess.json'),
                      ),
                      const SizedBox(height: 16),
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
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ✅ 하단 버튼 영역: FindIdScreen과 동일한 패딩/높이 느낌
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56, // ✅ 통일
                      child: OutlinedButton(
                        style: outlineBtnStyle,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => FindPwScreen()),
                          );
                        },
                        child: const Text('비밀번호 재설정'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 56, // ✅ 통일
                      child: ElevatedButton(
                        style: primaryBtnStyle,
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        child: const Text('아이디로 로그인'),
                      ),
                    ),
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
