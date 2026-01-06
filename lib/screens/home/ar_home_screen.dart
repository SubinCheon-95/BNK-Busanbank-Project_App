import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:tkbank/theme/app_colors.dart';
import 'package:tkbank/widgets/home_menu_bar.dart';
import 'package:tkbank/core/menu/main_menu_config.dart';
import 'package:tkbank/providers/auth_provider.dart';
import 'package:tkbank/services/token_storage_service.dart';
import 'package:tkbank/screens/chatbot/chatbot_screen.dart';
import 'package:tkbank/screens/member/login_screen.dart';
import 'package:tkbank/screens/product/product_main_screen.dart';
import 'package:tkbank/screens/product/interest_calculator_screen.dart';
import 'package:tkbank/screens/game/game_menu_screen.dart';
import 'package:tkbank/screens/product/news_analysis_screen.dart';
import 'package:tkbank/screens/member/point_history_screen.dart';
import 'package:tkbank/screens/cs/cs_support_screen.dart';
import 'package:tkbank/screens/event/seed_event_screen.dart';
import 'package:tkbank/screens/member/security_center_screen.dart';
import 'package:tkbank/screens/my_page/my_page_screen.dart';
import 'package:tkbank/screens/camera/vision_test_screen.dart';
import 'easy_home_screen.dart';

// 모션 상태 enum
enum MascotMotion {
  intro,
  idle,
  nod,
  wave,
  typing,
}

class ArHomeScreen extends StatefulWidget {
  final String baseUrl;

  const ArHomeScreen({super.key, required this.baseUrl});

  @override
  State<ArHomeScreen> createState() => _ArHomeScreenState();
}

class _ArHomeScreenState extends State<ArHomeScreen> {
  int _step = 0;
  bool _highlightInput = false;

  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  // 모션 관리
  MascotMotion _currentMotion = MascotMotion.intro;
  final Map<MascotMotion, String> _motionFiles = {
    MascotMotion.intro: 'assets/models/A_intro.glb',
    MascotMotion.idle: 'assets/models/penguinman.glb',
  };

  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _playMotion(MascotMotion.intro);

    Future.delayed(const Duration(milliseconds: 2100), () {
      if (mounted) {
        _playMotion(MascotMotion.idle);
      }
    });
  }

  void _playMotion(MascotMotion motion, {bool returnToIdle = false}) {
    setState(() {
      _currentMotion = motion;
    });

    if (returnToIdle && motion != MascotMotion.idle) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _playMotion(MascotMotion.idle);
        }
      });
    }
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
    // 👇 화면 크기
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _buildCameraBackground(),
          _buildMascot(),
          if (_step == 0) _buildGreeting(),
          if (_step == 1) _buildQuestion(),

          // 뒤로가기 버튼
          Positioned(
            top: MediaQuery
                .of(context)
                .padding
                .top + 16,
            left: 20,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EasyHomeScreen(baseUrl: widget.baseUrl),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.chevron_left,
                  color: AppColors.white,
                  size: 34,
                ),
              ),
            ),
          ),

          // 하단 슬라이드 메뉴
          Positioned(
            bottom: screenHeight * 0.05 + MediaQuery
                .of(context)
                .padding
                .bottom,
            left: 0,
            right: 0,
            child: HomeMenuBar(
              menuType: MainMenuType.normal,
              baseUrl: widget.baseUrl,
              onMorePressed: _showAllMenuModal,
            ),
          ),

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
      color: AppColors.gray3,
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildMascot() {
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;

    return Positioned(
      top: screenHeight * 0.2,
      left: 0,
      right: 0,
      child: Center(
        child: SizedBox(
          width: screenWidth * 1.05,
          height: screenHeight * 0.65,
          child: Stack(
            children: MascotMotion.values.map((motion) {
              if (!_motionFiles.containsKey(motion))
                return const SizedBox.shrink();

              final isActive = _currentMotion == motion;
              return AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isActive ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: !isActive,
                  child: ModelViewer(
                    key: ValueKey(motion),
                    src: _motionFiles[motion]!,
                    alt: "딸깍은행 마스코트",
                    autoPlay: true,
                    autoRotate: false,
                    cameraControls: false,
                    backgroundColor: Colors.transparent,

                    scale: '0.5 0.5 0.5',
                    cameraOrbit: "0deg 80deg 3m",
                    fieldOfView: "30deg",
                  ),
                ),
              );
            }).toList(),
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
        onTap: () {
          setState(() {
            _step = 1;
          });

          // 0.6초 후 원래 색으로 복귀
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              setState(() => _highlightInput = false);
            }
          });

        },
        child: SizedBox(
          height: screenHeight * 0.2,
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
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '탭하여 계속',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gray4,
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
      top: screenHeight * 0.10,
      left: 24,
      right: 24,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _highlightInput = true;
          });

          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              setState(() => _highlightInput = false); // 다시 원래 색
            }
          });
        },

        child: SizedBox(
          height: screenHeight * 0.2,
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
                          fontSize: 26, // 🔽 기존 32 → 26
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '탭하여 계속',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gray4,
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


  Widget _buildMessageInput() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 15,
          bottom: MediaQuery.of(context).padding.bottom + 8,
        ),
        decoration: BoxDecoration(
          color: _highlightInput
              ? AppColors.primary
              : AppColors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: '딸깍이에게 무엇이든 물어보세요.',
                  hintStyle: const TextStyle(
                    color: AppColors.gray4,
                    fontSize: 16,
                  ),
                  filled: true,
                  fillColor: AppColors.gray2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: AppColors.white),
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
    if (message.trim().isEmpty) return;

    print('AI 챗봇에게 메시지 전송: $message');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatbotScreen(
          initialMessage: message,
        ),
      ),
    );

    _messageController.clear();
    _focusNode.unfocus();
  }

  void _showAllMenuModal() {
    final authProvider = context.read<AuthProvider>();
    final isLoggedIn = authProvider.isLoggedIn;
    final screenHeight = MediaQuery.of(context).size.height;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: screenHeight * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.white,
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
                color: AppColors.gray3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 타이틀
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                '전체 메뉴',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),

            // 메뉴 리스트
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _tossMenuButton('금융상품 보기', Icons.shopping_bag, () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductMainScreen(baseUrl: widget.baseUrl),
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
                          builder: (_) => GameMenuScreen(baseUrl: widget.baseUrl),
                        ),
                      );
                    }),
                    _tossMenuButton('AI 뉴스', Icons.auto_awesome, () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NewsAnalysisMainScreen(baseUrl: widget.baseUrl),
                        ),
                      );
                    }),
                    _tossMenuButton('포인트 이력', Icons.stars, () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PointHistoryScreen(baseUrl: widget.baseUrl),
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

                    const SizedBox(height: 20),

                    if (!isLoggedIn)
                      _tossLoginButton()
                    else
                      _tossLogoutButton(),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tossMenuButton(String label, IconData icon, VoidCallback onPressed) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: screenHeight * 0.027,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.gray4,
                size: 24,
              ),
            ],
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
        borderRadius: BorderRadius.circular(15),
        splashColor: AppColors.primary.withOpacity(0.1),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, color: AppColors.white),
              SizedBox(width: 8),
              Text(
                '로그인',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
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
            builder: (dialogContext) => AlertDialog(
              backgroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: const Text(
                '로그아웃',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.black,
                ),
              ),
              content: const Text(
                '로그아웃 하시겠습니까?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray5,
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text(
                    '취소',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.red,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text(
                    '로그아웃',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray5,
                    ),
                  ),
                ),
              ],
            ),
          );

          if (confirm == true && mounted) {
            Navigator.pop(context);
            await _logout(context);
          }
        },
        borderRadius: BorderRadius.circular(15),
        splashColor: AppColors.red.withOpacity(0.1),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.red, width: 2),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, color: AppColors.red),
              SizedBox(width: 8),
              Text(
                '로그아웃',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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