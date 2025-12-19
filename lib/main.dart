import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tkbank/providers/auth_provider.dart';
import 'package:tkbank/providers/register_provider.dart';
import 'package:tkbank/screens/camera/vision_test_screen.dart';
import 'package:tkbank/screens/cs/cs_support_screen.dart';
import 'package:tkbank/services/FcmService.dart';
import 'package:tkbank/screens/member/login_screen.dart';
import 'package:tkbank/services/token_storage_service.dart';
import 'screens/product/product_main_screen.dart';
import 'screens/member/point_history_screen.dart';
import 'screens/game/game_menu_screen.dart';
import 'package:tkbank/screens/product/join/join_step4_screen.dart';
import 'package:tkbank/screens/product/join/join_step3_screen.dart';
import 'package:tkbank/screens/product/join/join_step2_screen.dart';
import 'package:tkbank/models/product_join_request.dart';
import 'screens/my_page/my_page_screen.dart'; // 2025/12/18 - 마이페이지 추가 - 작성자: 진원
import 'package:tkbank/screens/product/news_analysis_screen.dart';

// 2025/12/17 - Locale 초기화 추가 - 작성자: 진원
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); //Flutter 플러그인과 플랫폼 기능을 쓰기 위한 사전 준비 작성자 : 윤종인

  // 날짜 포맷팅 Locale 초기화
  await initializeDateFormatting('ko_KR', null);

  await FcmService.init(); //firebase를 미리 준비 작성자 : 윤종인

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RegisterProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String baseUrl = 'http://10.0.2.2:8080/busanbank/api';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TK 딸깍은행',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6A1B9A),
      ),
      home: const HomeScreen(baseUrl: baseUrl),
      // ✅ 추가!
      onGenerateRoute: (settings) {
        // STEP 2
        if (settings.name == '/product/join/step2') {
          final request = settings.arguments as ProductJoinRequest;
          return MaterialPageRoute(
            builder: (context) => JoinStep2Screen(
              baseUrl: baseUrl,
              request: request,
            ),
          );
        }

        // STEP 3
        if (settings.name == '/product/join/step3') {
          final request = settings.arguments as ProductJoinRequest;
          return MaterialPageRoute(
            builder: (context) => JoinStep3Screen(request: request),
          );
        }

        // STEP 4
        if (settings.name == '/product/join/step4') {
          final request = settings.arguments as ProductJoinRequest;
          return MaterialPageRoute(
            builder: (context) => JoinStep4Screen(
              baseUrl: baseUrl,
              request: request,
            ),
          );
        }

        return null;
      },
    );
  }
}

/// 🔥 메인 홈 화면 (상품 메인 / 로그인 / 로그아웃 버튼)
class HomeScreen extends StatelessWidget {
  final String baseUrl;

  const HomeScreen({super.key, required this.baseUrl});

  Future<void> _logout(BuildContext context) async {
    await TokenStorageService().deleteToken();

    if (context.mounted) {
      final authProvider = context.read<AuthProvider>();
      authProvider.logout();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그아웃되었습니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoggedIn = authProvider.isLoggedIn;

    return Scaffold(
      appBar: AppBar(
        title: const Text('딸깍은행'),
        actions: [
          if (isLoggedIn)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 4),
                  const Text(
                    '로그인됨',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_balance,
                size: 100,
                color: Color(0xFF6A1B9A),
              ),
              const SizedBox(height: 24),
              const Text(
                '딸깍은행에 오신 것을 환영합니다',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // ✅ 버튼 1: 상품 메인
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductMainScreen(baseUrl: baseUrl),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_bag),
                  label: const Text(
                    '상품 둘러보기',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A1B9A),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ✅ 버튼 3: 포인트 이력
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PointHistoryScreen(baseUrl: baseUrl),
                      ),
                    );
                  },
                  icon: const Icon(Icons.stars),
                  label: const Text(
                    '포인트 이력',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ✅ 버튼 4: 금융게임
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GameMenuScreen(baseUrl: baseUrl),
                      ),
                    );
                  },
                  icon: const Icon(Icons.games),
                  label: const Text(
                    '금융게임',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C27B0),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),const SizedBox(height: 16),

              // ✅ 버튼 : 고객센터
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CustomerSupportScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.support_agent),
                  label: const Text(
                    '고객센터',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C27B0),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ✅ 버튼 : 금융감정분석
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NewsAnalysisMainScreen(baseUrl: baseUrl),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text(
                    'AI 뉴스 분석 & 상품 추천',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

              // ✅ 버튼 : 마이페이지 (2025/12/18 - 작성자: 진원)
              if (isLoggedIn)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyPageScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person),
                    label: const Text(
                      '마이페이지',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              
              if (isLoggedIn) const SizedBox(height: 16),
              SizedBox( // 25/12/18 임시 이미지 테스트 작성자: 윤종인 @@@@@@@@@@@@@@@@@@@@@@
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VisionTestScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text(
                    'OCR 테스트 (임시)',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),


              // ✅ 버튼 5: 로그인 / 로그아웃
              if (!isLoggedIn) ...[
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.login),
                    label: const Text(
                      '로그인',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFF6A1B9A),
                        width: 2,
                      ),
                      foregroundColor: const Color(0xFF6A1B9A),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('로그아웃'),
                          content: const Text('로그아웃하시겠습니까?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext, false),
                              child: const Text('취소'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext, true),
                              child: const Text('로그아웃'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && context.mounted) {
                        await _logout(context);
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      '로그아웃',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Colors.red,
                        width: 2,
                      ),
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}