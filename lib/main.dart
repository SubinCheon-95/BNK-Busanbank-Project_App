import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // 2025/12/21 - 웹 플랫폼 체크용 - 작성자: 진원
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tkbank/providers/auth_provider.dart';
import 'package:tkbank/providers/register_provider.dart';
import 'package:tkbank/screens/camera/vision_test_screen.dart';
import 'package:tkbank/screens/chatbot/chatbot_screen.dart';
import 'package:tkbank/screens/cs/cs_support_screen.dart';
import 'package:tkbank/screens/member/security_center_screen.dart';
import 'package:tkbank/screens/product/news_analysis_screen.dart';
import 'package:tkbank/services/FcmService.dart';
import 'package:tkbank/screens/member/login_screen.dart';
import 'package:tkbank/services/token_storage_service.dart';
import 'package:tkbank/screens/splash_screen.dart';
import 'screens/product/product_main_screen.dart';
import 'screens/member/point_history_screen.dart';
import 'screens/game/game_menu_screen.dart';
import 'package:tkbank/screens/product/join/join_step4_screen.dart';
import 'package:tkbank/screens/product/join/join_step3_screen.dart';
import 'package:tkbank/screens/product/join/join_step2_screen.dart';
import 'package:tkbank/models/product_join_request.dart';
import 'screens/my_page/my_page_screen.dart';
import 'screens/product/interest_calculator_screen.dart';  // ✅ 추가!
import 'screens/splash_screen.dart'; // 25.12.22 천수빈
import 'package:camera/camera.dart'; // 25.12.23 천수빈
import 'package:permission_handler/permission_handler.dart'; // 25.12.23 천수빈
import 'package:model_viewer_plus/model_viewer_plus.dart'; // 25.12.23 천수빈

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);

  // 2025/12/21 - 웹에서는 Firebase 초기화 건너뛰기 - 작성자: 진원
  if (!kIsWeb) {
    await FcmService.init();
  }

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
      onGenerateRoute: (settings) {
        if (settings.name == '/product/join/step2') {
          final request = settings.arguments as ProductJoinRequest;
          return MaterialPageRoute(
            builder: (context) => JoinStep2Screen(
              baseUrl: baseUrl,
              request: request,
            ),
          );
        }

        if (settings.name == '/product/join/step3') {
          final request = settings.arguments as ProductJoinRequest;
          return MaterialPageRoute(
            builder: (context) => JoinStep3Screen(request: request),
          );
        }

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
      home: const SplashScreen(),
    );
  }
}

// 2025.12.23 _ Home Screen 수정 - 수정자: 천수빈
class HomeScreen extends StatefulWidget {
  final String baseUrl;

  const HomeScreen({super.key, required this.baseUrl});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _step = 0; // 0: 인사, 1: 질문, 2: 메뉴
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();

    // 2초 후 자동으로 다음 단계
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _step = 1);
    });
  }

  Future<void> _initializeCamera() async {
    try {
      // 카메라 권한 요청
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          setState(() => _isCameraInitialized = false);
        }
        return;
      }

      // 사용 가능한 카메라 가져오기
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      // 후면 카메라 사용
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController?.initialize();

      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      print('카메라 초기화 실패: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

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
      body: Stack(
        children: [
          // 📹 카메라 배경
          _buildCameraBackground(),

          // 🎭 마스코트 (항상 표시)
          _buildMascot(),

          // 💬 단계별 UI
          if (_step == 0) _buildGreeting(),
          if (_step == 1) _buildQuestion(),
          if (_step == 2) _buildMenu(isLoggedIn),
        ],
      ),
    );
  }

  // 📹 카메라 배경
  Widget _buildCameraBackground() {
    if (_isCameraInitialized && _cameraController != null) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _cameraController!.value.previewSize!.height,
            height: _cameraController!.value.previewSize!.width,
            child: CameraPreview(_cameraController!),
          ),
        ),
      );
    }

    // 카메라 로딩 중이거나 실패 시 회색 배경
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6A1B9A),
        ),
      ),
    );
  }

  // 메인 마스코트 (중앙 상단)
  Widget _buildMascot() {
    return Positioned(
      top: 150,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 400,
          height: 600,
          child: ModelViewer(
            src: 'assets/models/penguinman.glb',
            alt: "딸깍은행 마스코트",
            autoRotate: false,
            cameraControls: false,
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
    );
  }

  // 💬 1단계: 인사
  Widget _buildGreeting() {
    return Positioned(
      bottom: 100,
      left: 24,
      right: 24,
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 500),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF6A1B9A), width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Text(
            '안녕하세요. 김딸깍님!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // 💬 2단계: 질문
  Widget _buildQuestion() {
    return Positioned(
      bottom: 100,
      left: 24,
      right: 24,
      child: GestureDetector(
        onTap: () => setState(() => _step = 2),
        child: AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 500),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF6A1B9A), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  '무엇을 도와드릴까요?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '탭하여 계속',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 📋 3단계: 메뉴 버튼들
  Widget _buildMenu(bool isLoggedIn) {
    return Positioned(
      bottom: 20,
      left: 24,
      right: 24,
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 500,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF6A1B9A), width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                '찾는게 있으시면\n선택해 주세요!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _menuButton('금융상품 보기', Icons.shopping_bag, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductMainScreen(baseUrl: widget.baseUrl),
                        ),
                      );
                    }),
                    _menuButton('금리 계산기', Icons.calculate, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InterestCalculatorScreen(),
                        ),
                      );
                    }),
                    _menuButton('금융게임 바로가기', Icons.games, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GameMenuScreen(baseUrl: widget.baseUrl),
                        ),
                      );
                    }),
                    _menuButton('AI 뉴스 분석', Icons.auto_awesome, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NewsAnalysisMainScreen(baseUrl: widget.baseUrl),
                        ),
                      );
                    }),
                    _menuButton('포인트 이력', Icons.stars, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PointHistoryScreen(baseUrl: widget.baseUrl),
                        ),
                      );
                    }),
                    _menuButton('고객센터', Icons.support_agent, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CustomerSupportScreen(),
                        ),
                      );
                    }),
                    _menuButton('챗봇', Icons.smart_toy_outlined, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChatbotScreen(),
                        ),
                      );
                    }),
                    if (isLoggedIn) ...[
                      _menuButton('인증센터', Icons.lock_outline, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SecurityCenterScreen(),
                          ),
                        );
                      }),
                      _menuButton('마이페이지', Icons.person, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyPageScreen(),
                          ),
                        );
                      }),
                    ],
                    _menuButton('OCR 테스트', Icons.camera_alt, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const VisionTestScreen(),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    if (!isLoggedIn)
                      _loginButton()
                    else
                      _logoutButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuButton(String label, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: const BorderSide(color: Colors.black, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.black),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            ),
          );
        },
        icon: const Icon(Icons.login),
        label: const Text('로그인'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: const Color(0xFF6A1B9A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }

  Widget _logoutButton() {
    return SizedBox(
      width: double.infinity,
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
        label: const Text('로그아웃'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.red, width: 2),
          foregroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}