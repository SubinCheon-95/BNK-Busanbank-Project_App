import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // 2025/12/21 - 웹 플랫폼 체크용 - 작성자: 진원
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tkbank/providers/auth_provider.dart';
import 'package:tkbank/providers/register_provider.dart';
import 'package:tkbank/providers/seed_event_provider.dart';
import 'package:tkbank/screens/camera/vision_test_screen.dart';
import 'package:tkbank/screens/chatbot/chatbot_screen.dart';
import 'package:tkbank/screens/cs/cs_support_screen.dart';
import 'package:tkbank/screens/event/seed_event_screen.dart';
import 'package:tkbank/screens/member/security_center_screen.dart';
import 'package:tkbank/screens/product/news_analysis_screen.dart';
import 'package:tkbank/services/FcmService.dart';
import 'package:tkbank/screens/member/login_screen.dart';
import 'package:tkbank/services/seed_event_service.dart';
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
        // 2025/12/23 -  금열매 이벤트 Provider 추가 - 작성자: 오서정
        ChangeNotifierProvider(create: (_) => SeedEventProvider(SeedEventService()),),

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

        // 👇 전체 앱에 폰트 적용!
        fontFamily: 'Pretendard',
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
  int _step = 0; // 0: 인사, 1: 질문, 2: 대화중, 3: 메뉴
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showMenu = false; // 👈 메뉴 표시 여부

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          setState(() => _isCameraInitialized = false);
        }
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

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
    _messageController.dispose(); // 👈 추가
    _focusNode.dispose(); // 👈 추가
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
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 📹 카메라 배경
          _buildCameraBackground(),

          // 🎭 마스코트 (항상 표시)
          _buildMascot(),

          // 💬 단계별 대화창
          if (_step == 0) _buildGreeting(),
          if (_step == 1) _buildQuestion(),

          // 📝 하단 입력창 (항상 표시)
          _buildMessageInput(),

          // 🔘 플로팅 메뉴 버튼 (오른쪽) - 새로 추가!
          _buildFloatingMenuButton(),

          // 📋 메뉴 (버튼 눌렀을 때만 표시)
          if (_showMenu) _buildMenu(isLoggedIn),
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
    final screenHeight = MediaQuery.of(context).size.height;

    return Positioned(
      top: screenHeight * 0.28,
      left: 0,
      right: 0,
      child: Center(
        child: SizedBox(
          width: 400,
          height: 500,
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

  // 💬 1단계: 인사 (도트 대화창)
  Widget _buildGreeting() {
    final screenHeight = MediaQuery.of(context).size.height;

    return Positioned(
      top: screenHeight * 0.10,  // 👈 화면 높이의 10% 위치
      left: 24,
      right: 24,
      child: GestureDetector(
        onTap: () => setState(() => _step = 1),
        child: SizedBox(
          height: 180,
          child: Stack(
            children: [
              Image.asset(
                'assets/images/dialog_box.png',
                fit: BoxFit.contain,
                width: double.infinity,
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '안녕하세요. 저는 딸깍이에요!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '탭하여 계속',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 💬 2단계: 질문 (화면 비율로!)
  Widget _buildQuestion() {
    final screenHeight = MediaQuery.of(context).size.height;

    return Positioned(
      top: screenHeight * 0.1,  // 👈 화면 높이의 10% 위치
      left: 24,
      right: 24,
      child: GestureDetector(
        onTap: () {
          _focusNode.requestFocus();
        },
        child: SizedBox(
          height: 180,
          child: Stack(
            children: [
              Image.asset(
                'assets/images/dialog_box.png',
                fit: BoxFit.contain,
                width: double.infinity,
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '무엇을 도와드릴까요?',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '딸깍이에게 무엇이든 물어보세요',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔘 플로팅 메뉴 버튼 (화면 비율 유지 + SafeArea 고려!)
  Widget _buildFloatingMenuButton() {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      right: 16,
      bottom: 90 + bottomPadding,  // 👈 하단 네비게이션 바(75) + 여백(15) + 안전영역
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: FloatingActionButton(
          onPressed: () {
            setState(() => _showMenu = !_showMenu);
          },
          backgroundColor: const Color(0xFF6A1B9A),
          elevation: 6,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _showMenu ? Icons.close : Icons.menu,
              key: ValueKey(_showMenu),
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  // 📝 하단 메시지 입력창
  Widget _buildMessageInput() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).padding.bottom + 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: '딸깍이에게 무엇이든 물어보세요...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (value) {
                  _handleSendMessage(value);
                },
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF6A1B9A),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: () {
                  _handleSendMessage(_messageController.text);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 메시지 전송 처리
  void _handleSendMessage(String message) {
    if (message.trim().isEmpty) return;

    print('AI 챗봇에게 메시지 전송: $message');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ChatbotScreen(),
      ),
    );

    _messageController.clear();
    _focusNode.unfocus();
  }

  // 📋 3단계: 메뉴 (버튼으로 열기)
  Widget _buildMenu(bool isLoggedIn) {
    return GestureDetector(
      onTap: () {
        setState(() => _showMenu = false);
      },
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,  // 👈 0.75 → 0.85로 증가!
                maxWidth: 500,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 헤더 (수정!)
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 25, 16, 12),  // 👈 패딩 조정
                    child: Stack(
                      children: [
                        // 타이틀 (센터)
                        const Center(  // 👈 Center로 감싸기
                          child: Text(
                            '자주 찾는 메뉴',
                            style: TextStyle(
                              fontSize: 30,
                              color: Color(0xFF6A1B9A),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // X 버튼 (오른쪽 상단) - 수정!
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 28),
                            onPressed: () {
                              setState(() => _showMenu = false);
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 메뉴 리스트
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _tossMenuButton('금융상품 보기', Icons.shopping_bag, () {
                            setState(() => _showMenu = false);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductMainScreen(baseUrl: widget.baseUrl),
                              ),
                            );
                          }),
                          _tossMenuButton('금리 계산기', Icons.calculate, () {
                            setState(() => _showMenu = false);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const InterestCalculatorScreen(),
                              ),
                            );
                          }),
                          _tossMenuButton('금융게임 바로가기', Icons.games, () {
                            setState(() => _showMenu = false);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GameMenuScreen(baseUrl: widget.baseUrl),
                              ),
                            );
                          }),
                          _tossMenuButton('AI 뉴스 분석', Icons.auto_awesome, () {
                            setState(() => _showMenu = false);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NewsAnalysisMainScreen(baseUrl: widget.baseUrl),
                              ),
                            );
                          }),
                          _tossMenuButton('포인트 이력', Icons.stars, () {
                            setState(() => _showMenu = false);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PointHistoryScreen(baseUrl: widget.baseUrl),
                              ),
                            );
                          }),
                          _tossMenuButton('고객센터', Icons.support_agent, () {
                            setState(() => _showMenu = false);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CustomerSupportScreen(),
                              ),
                            );
                          }),

                          if (isLoggedIn) ...[
                            _tossMenuButton('금열매 이벤트', Icons.eco, () {
                              setState(() => _showMenu = false);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SeedEventScreen(),
                                ),
                              );
                            }),
                            _tossMenuButton('인증센터', Icons.lock_outline, () {
                              setState(() => _showMenu = false);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SecurityCenterScreen(),
                                ),
                              );
                            }),
                            _tossMenuButton('마이페이지', Icons.person, () {
                              setState(() => _showMenu = false);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MyPageScreen(),
                                ),
                              );
                            }),
                          ],

                          _tossMenuButton('OCR 테스트', Icons.camera_alt, () {
                            setState(() => _showMenu = false);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const VisionTestScreen(),
                              ),
                            );
                          }),

                          const SizedBox(height: 16),

                          // 로그인/로그아웃 버튼
                          if (!isLoggedIn)
                            _tossLoginButton()
                          else
                            _tossLogoutButton(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🎨 토스 스타일 메뉴 버튼 (수정!)
  Widget _tossMenuButton(String label, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.grey[100],  // 👈 탭 순간 효과
          highlightColor: Colors.grey[100],  // 👈 누르고 있을 때 회색!
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,  // 👈 기본은 흰색!
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // 아이콘
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF6A1B9A),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // 텍스트
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                // 화살표
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🎨 토스 스타일 로그인 버튼
  Widget _tossLoginButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() => _showMenu = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: const Color(0xFF6A1B9A).withOpacity(0.1),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF6A1B9A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, color: Colors.white),
              SizedBox(width: 8),
              Text(
                '로그인',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎨 토스 스타일 로그아웃 버튼
  Widget _tossLogoutButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
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
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.red.withOpacity(0.1),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red, width: 1.5),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 8),
              Text(
                '로그아웃',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

