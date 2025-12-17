import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tkbank/providers/auth_provider.dart';
import 'package:tkbank/providers/register_provider.dart';
import 'package:tkbank/services/FcmService.dart';
import 'package:tkbank/screens/member/login_screen.dart';
import 'package:tkbank/services/token_storage_service.dart';
import 'screens/product/product_main_screen.dart';
import 'screens/member/coupon_screen.dart';
import 'screens/member/point_history_screen.dart';
import 'screens/game/game_menu_screen.dart';

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
        // 2025/12/16 - 회원가입 내용 저장용 provider 구독 - 작성자 : 오서정
        ChangeNotifierProvider(create: (_) => RegisterProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// 📌 에뮬레이터에서 스프링부트 서버 접속용
  /// - 브라우저: http://localhost:8080/busanbank/api/products
  /// - 에뮬레이터: http://10.0.2.2:8080/busanbank/api/products
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
    );
  }
}

/// 🔥 메인 홈 화면 (상품 메인 / 로그인 / 로그아웃 버튼)
class HomeScreen extends StatelessWidget {
  final String baseUrl;

  const HomeScreen({super.key, required this.baseUrl});

  Future<void> _logout(BuildContext context) async {
    // 토큰 삭제
    await TokenStorageService().deleteToken();

    // AuthProvider 업데이트
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
    // AuthProvider로 로그인 여부 확인
    final authProvider = context.watch<AuthProvider>();
    final isLoggedIn = authProvider.isLoggedIn;

    return Scaffold(
      appBar: AppBar(
        title: const Text('딸깍은행'),
        actions: [
          // 로그인 상태 표시 (AppBar actions)
          if (isLoggedIn)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 4),
                  // ✅ 방법 1: user 필드가 있으면 사용
                  // Text(
                  //   '${authProvider.user?.userName ?? "사용자"}님',
                  //   style: const TextStyle(fontSize: 14),
                  // ),

                  // ✅ 방법 2: user 필드 없으면 그냥 체크 아이콘만
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
              // 로고 또는 타이틀
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

              // ✅ 버튼 2: 쿠폰 등록
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CouponScreen(baseUrl: baseUrl),
                      ),
                    );
                  },
                  icon: const Icon(Icons.card_giftcard),
                  label: const Text(
                    '쿠폰 등록',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
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

              // ✅ 버튼 4: 금융게임 (2025-12-16 - 작성자: 진원)
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
              ),
              const SizedBox(height: 16),

              // ✅ 버튼 5: 로그인 / 로그아웃
              if (!isLoggedIn) ...[
                // 로그인 버튼
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
                // 로그아웃 버튼
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      // 확인 다이얼로그
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