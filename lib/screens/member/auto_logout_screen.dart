/*
  날짜: 2025/12/30
  내용: 자동 로그아웃 화면 (하단 버튼 고정형, Lottie 적용, 흰 배경)
  작성자: 오서정
*/
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:tkbank/main.dart';
import 'package:tkbank/screens/home/easy_home_screen.dart';

// 🎨 Color System
const Color bnkPrimary = Color(0xFF6A1B9A);
const Color bnkGrayText = Color(0xFF6B7280);

class AutoLogoutScreen extends StatefulWidget {
  const AutoLogoutScreen({super.key});

  @override
  State<AutoLogoutScreen> createState() => _AutoLogoutScreenState();
}

class _AutoLogoutScreenState extends State<AutoLogoutScreen> {
  bool _snackShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ✅ 진입 시 1회 안내
    if (!_snackShown) {
      _snackShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('서비스 이용이 없어 자동 로그아웃되었습니다'),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ✅ 흰색으로 고정
      body: SafeArea(
        child: Column(
          children: [
            // ================== 상단 콘텐츠 ==================
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✅ Lottie
                      Lottie.asset(
                        'assets/lottie/Timeout.json',
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                        repeat: true,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '자동 로그아웃 되었습니다',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: bnkPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        '보안을 위해 20분 동안 서비스 이용이 없어\n자동으로 로그아웃 되었습니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.5,
                          color: bnkGrayText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ================== 하단 버튼 ==================
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  // 🔹 앱 종료 (보조)
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: bnkPrimary,
                          side: const BorderSide(color: bnkPrimary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => SystemNavigator.pop(),
                        child: const Text(
                          '앱 종료',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 🔹 홈으로 이동 (메인)
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: bnkPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EasyHomeScreen(baseUrl: MyApp.baseUrl),
                            ),
                                (route) => false,
                          );
                        },
                        child: const Text(
                          '홈으로 이동',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
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
