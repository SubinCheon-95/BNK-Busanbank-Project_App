/*
  날짜: 2025/12/30
  내용: 자동 로그아웃 화면
  작성자: 오서정
*/
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tkbank/main.dart';
import 'package:tkbank/providers/auth_provider.dart';
import 'package:tkbank/services/token_storage_service.dart';

// 색상 정의
const Color bnkPrimary = Color(0xFF6A1B9A);
const Color bnkPrimarySoft = Color(0xFFF3E5F5);
const Color bnkGray = Color(0xFF9CA3AF);
const Color pinPanelColor = bnkPrimary;        // 메인 보라
const Color pinTextColor = Colors.white;
const Color pinSubTextColor = Colors.white70;

class AutoLogoutScreen extends StatefulWidget {
  const AutoLogoutScreen({super.key});

  @override
  State<AutoLogoutScreen> createState() => _AutoLogoutScreenState();
}

class _AutoLogoutScreenState extends State<AutoLogoutScreen> {
  final TokenStorageService _tokenStorage = TokenStorageService();

  @override
  void initState() {
    super.initState();
    _logout();
  }
  Future<void> _logout() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bnkPrimarySoft, // 배경 보라 연하게
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.logout, size: 80, color: bnkPrimary),
              const SizedBox(height: 24),
              const Text(
                "자동 로그아웃 되었습니다.",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: bnkPrimary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "보안을 위해 일정 시간이 지나면 자동으로 로그아웃 됩니다.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: bnkGray,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bnkPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // 홈 화면으로 이동, 기존 스택 제거
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomeScreen(baseUrl: MyApp.baseUrl), // 필수 파라미터 전달
                      ),
                          (route) => false,
                    );
                  },
                  child: const Text(
                    "홈으로 이동",
                    style: TextStyle(
                      color: pinTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bnkGray,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    SystemNavigator.pop(); // 앱 종료
                  },
                  child: const Text(
                    "앱 종료",
                    style: TextStyle(
                      color: pinTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
