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
import 'navigator_key.dart';
import 'screens/product/product_main_screen.dart';
import 'screens/member/point_history_screen.dart';
import 'screens/game/game_menu_screen.dart';
import 'package:tkbank/screens/product/join/join_step4_screen.dart';
import 'package:tkbank/screens/product/join/join_step3_screen.dart';
import 'package:tkbank/screens/product/join/join_step2_screen.dart';
import 'package:tkbank/models/product_join_request.dart';
import 'screens/my_page/my_page_screen.dart';
import 'screens/product/interest_calculator_screen.dart';  // ✅ 추가!
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
      navigatorKey: navigatorKey, // 푸시 알림 페이지 이동을 위한 키 설정 - 작성자: 윤종인
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

// _HomeScreenState 클래스 수정 (HomeScreen은 그대로)
class _HomeScreenState extends State<HomeScreen> {
  static const double _messageInputHeight = 64.0;

  int _step = 0;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

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
    _messageController.dispose();
    _focusNode.dispose();
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
          _buildCameraBackground(),
          _buildMascot(),
          if (_step == 0) _buildGreeting(),
          if (_step == 1) _buildQuestion(),

          // 하단 슬라이드 메뉴
          _buildBottomMenuSection(isLoggedIn),
          _buildMessageInput(),
        ],
      ),
    );
  }

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

  Widget _buildMascot() {
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;

    return Positioned(
      top: screenHeight * 0.28,
      left: 0,
      right: 0,
      child: Center(
        child: SizedBox(
          width: 350,
          height: 450,
          child: ModelViewer(
            src: 'assets/models/penguinman_hi.glb',
            alt: "딸깍은행 마스코트",
            autoRotate: false,
            cameraControls: false,
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;

    return Positioned(
      top: screenHeight * 0.10,
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

  Widget _buildQuestion() {
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;

    return Positioned(
      top: screenHeight * 0.1,
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
                  // 꼬리 때문에 아래 여백을 더 주고, 위 여백을 줄임
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 34),
                  child: Align(
                    alignment: const Alignment(0, 0), // 👈 아래로 살짝 (0.05~0.12 사이 조절)
                    child: const Text(
                      '무엇을 도와드릴까요?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
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
          bottom: MediaQuery
              .of(context)
              .padding
              .bottom + 8,
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
                  hintText: '딸깍이에게 무엇이든 물어보세요.',
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

  void _handleSendMessage(String message) {
    if (message
        .trim()
        .isEmpty) return;

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

  // 🎯 하단 수평 스크롤 메뉴 섹션
  Widget _buildBottomMenuSection(bool isLoggedIn) {
    // 메뉴 아이템 리스트
    final List<_MenuItem> menuItems = [
      _MenuItem(label: '상품 보기', icon: Icons.shopping_bag, onPressed: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => ProductMainScreen(baseUrl: widget.baseUrl)));
      }),
      _MenuItem(label: '금리계산기', icon: Icons.calculate, onPressed: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const InterestCalculatorScreen()));
      }),
      _MenuItem(label: '금융 게임', icon: Icons.games, onPressed: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => GameMenuScreen(baseUrl: widget.baseUrl)));
      }),
      _MenuItem(label: '고객센터', icon: Icons.support_agent, onPressed: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CustomerSupportScreen()));
      }),
      _MenuItem(label: '더보기', icon: Icons.more_horiz, onPressed: () {
        _showAllMenuModal();
      }),
    ];

    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: _messageInputHeight + safeBottom,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.white,

        padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 인기 메뉴 타이틀
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '인기 메뉴',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6A1B9A),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 0),

            // 👇 수평 스크롤 리스트!
            SizedBox(
              height: 88,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10, // 👈 이게 핵심
                ),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return _buildWideMenuButton(
                    item.icon,
                    item.label,
                    item.onPressed,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 수평 스크롤용 메뉴 아이템
  Widget _buildWideMenuButton(
      IconData icon,
      String label,
      VoidCallback onPressed,
      ) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 180, // 가로로 긴 직사각형
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.16),
                blurRadius: 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // 아이콘 박스
              Icon(
                icon,
                size: 30, // 아이콘만 단독이므로 살짝 키움
                color: const Color(0xFF662382), // 👈 보라색
              ),
              const SizedBox(width: 16),

              // 텍스트
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 더보기 모달
  void _showAllMenuModal() {
    final authProvider = context.read<AuthProvider>();
    final isLoggedIn = authProvider.isLoggedIn;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          Container(
            height: MediaQuery
                .of(context)
                .size
                .height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // 핸들
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // 타이틀
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Text(
                    '전체 메뉴',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6A1B9A),
                    ),
                  ),
                ),

                // 메뉴 리스트
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _tossMenuButton('금융상품 보기', Icons.shopping_bag, () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductMainScreen(baseUrl: widget.baseUrl),
                            ),
                          );
                        }),
                        _tossMenuButton('금리 계산기', Icons.calculate, () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const InterestCalculatorScreen(),
                            ),
                          );
                        }),
                        _tossMenuButton('금융게임', Icons.games, () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  GameMenuScreen(baseUrl: widget.baseUrl),
                            ),
                          );
                        }),
                        _tossMenuButton('AI 뉴스', Icons.auto_awesome, () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  NewsAnalysisMainScreen(
                                      baseUrl: widget.baseUrl),
                            ),
                          );
                        }),
                        _tossMenuButton('포인트 이력', Icons.stars, () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PointHistoryScreen(baseUrl: widget.baseUrl),
                            ),
                          );
                        }),
                        _tossMenuButton('고객센터', Icons.support_agent, () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CustomerSupportScreen(),
                            ),
                          );
                        }),

                        if (isLoggedIn) ...[
                          _tossMenuButton('금열매 이벤트', Icons.eco, () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SeedEventScreen(),
                              ),
                            );
                          }),
                          _tossMenuButton('인증센터', Icons.lock_outline, () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SecurityCenterScreen(),
                              ),
                            );
                          }),
                          _tossMenuButton('마이페이지', Icons.person, () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MyPageScreen(),
                              ),
                            );
                          }),
                        ],

                        _tossMenuButton('로고 인증 이벤트', Icons.camera_alt, () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const VisionTestScreen(),
                            ),
                          );
                        }),

                        const SizedBox(height: 16),

                        // 로그인/로그아웃
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
    );
  }

  // 기존 토스 스타일 버튼들은 그대로 유지
  Widget _tossMenuButton(String label, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.grey[100],
          highlightColor: Colors.grey[100],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
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

  Widget _tossLoginButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
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
                  fontSize: 18,
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

  Widget _tossLogoutButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (dialogContext) =>
                AlertDialog(
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

          if (confirm == true && mounted) { // 👈 context.mounted 대신 mounted
            Navigator.pop(context); // 👈 이 줄 추가! (모달 닫기)
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

// 👇 메뉴 아이템 클래스 (HomeScreen 밖에 추가)
class _MenuItem {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  _MenuItem({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
}