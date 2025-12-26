// 2025/12/20 - ESG 낚시 게임 화면 - 작성자: 진원

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
import '../models/trash.dart';
import '../services/fishing_service.dart';
import '../providers/auth_provider.dart';

class EsgFishingScreen extends StatefulWidget {
  final String baseUrl;

  const EsgFishingScreen({
    Key? key,
    required this.baseUrl,
  }) : super(key: key);

  @override
  State<EsgFishingScreen> createState() => _EsgFishingScreenState();
}

class _EsgFishingScreenState extends State<EsgFishingScreen>
    with SingleTickerProviderStateMixin {
  final FishingService _fishingService = FishingService();

  // 게임 상태
  GameState _gameState = GameState.ready;
  Trash? _currentTrash;
  int _totalPoints = 0;
  int _catchCount = 0;

  // 센서 관련
  StreamSubscription? _accelerometerSubscription;
  double _currentY = 0.0;
  double _shakeThreshold = 15.0; // 흔들기 감지 임계값

  // 애니메이션
  late AnimationController _animationController;
  late Animation<double> _hookAnimation;
  bool _isHookDown = false;

  // 타이머
  Timer? _biteTimer;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _startAccelerometer();
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _animationController.dispose();
    _biteTimer?.cancel();
    super.dispose();
  }

  void _initAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _hookAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _startAccelerometer() {
    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        setState(() {
          _currentY = event.y;
        });

        // 게임 상태에 따른 동작
        if (_gameState == GameState.ready && event.y.abs() > _shakeThreshold) {
          _castHook();
        } else if (_gameState == GameState.biting && event.y > _shakeThreshold) {
          _pullHook();
        }
      },
    );
  }

  // 낚싯줄 던지기
  void _castHook() {
    setState(() {
      _gameState = GameState.casting;
      _isHookDown = true;
    });

    _animationController.forward().then((_) {
      _waitForBite();
    });
  }

  // 물고기(쓰레기) 기다리기
  void _waitForBite() {
    setState(() {
      _gameState = GameState.waiting;
    });

    // 랜덤 시간 후 쓰레기가 물어뜯음
    final random = Random();
    final waitTime = 2 + random.nextInt(4); // 2~5초

    _biteTimer = Timer(Duration(seconds: waitTime), () {
      _onBite();
    });
  }

  // 쓰레기가 물었을 때
  void _onBite() {
    final trashList = _fishingService.getTrashList();
    final random = Random();

    // 희귀도에 따른 확률 (낮은 포인트가 더 자주 나옴)
    final rarityRoll = random.nextInt(100);
    Trash selectedTrash;

    if (rarityRoll < 40) {
      // 40% - 일반 쓰레기 (10-15점)
      selectedTrash = trashList[random.nextInt(2)];
    } else if (rarityRoll < 75) {
      // 35% - 중급 쓰레기 (20-25점)
      selectedTrash = trashList[2 + random.nextInt(2)];
    } else if (rarityRoll < 95) {
      // 20% - 고급 쓰레기 (50점)
      selectedTrash = trashList[4];
    } else {
      // 5% - 희귀 쓰레기 (100점)
      selectedTrash = trashList[5];
    }

    setState(() {
      _currentTrash = selectedTrash;
      _gameState = GameState.biting;
    });

    // 진동 효과 (선택적)
    _showBiteAlert();
  }

  void _showBiteAlert() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎣 쓰레기가 물었어요! 위로 올리세요!'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // 낚싯줄 당기기
  void _pullHook() {
    if (_currentTrash == null) return;

    setState(() {
      _gameState = GameState.caught;
    });

    _animationController.reverse().then((_) {
      _showCatchResult();
    });
  }

  // 잡은 결과 표시
  void _showCatchResult() {
    if (_currentTrash == null) return;

    setState(() {
      _totalPoints += _currentTrash!.points;
      _catchCount++;
    });

    // 백엔드에 결과 전송
    _submitResult();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 수거 성공!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _currentTrash!.emoji,
              style: const TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 16),
            Text(
              _currentTrash!.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_currentTrash!.description),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+${_currentTrash!.points} 포인트',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            child: const Text('계속하기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('종료'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitResult() async {
    if (_currentTrash == null) return;

    try {
      // 로그인한 사용자 정보 가져오기
      final authProvider = context.read<AuthProvider>();
      final userNo = authProvider.userNo;

      if (userNo == null) {
        print('[ESG 낚시] 로그인이 필요합니다');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('로그인이 필요합니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      print('[ESG 낚시] 포인트 저장 시작 - userId: $userNo, trashType: ${_currentTrash!.type}, points: ${_currentTrash!.points}');

      final result = await _fishingService.submitFishingResult(
        userId: userNo.toString(),
        trashType: _currentTrash!.type,
        points: _currentTrash!.points,
      );

      print('[ESG 낚시] 포인트 저장 성공 - 응답: $result');
    } catch (e) {
      print('[ESG 낚시] 포인트 저장 실패 - 에러: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('포인트 저장 실패: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _resetGame() {
    setState(() {
      _gameState = GameState.ready;
      _currentTrash = null;
      _isHookDown = false;
    });
    _animationController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ESG 바다 청소 낚시'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade300,
              Colors.blue.shade600,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 점수 표시
              _buildScoreBoard(),

              // 게임 영역
              Expanded(
                child: Stack(
                  children: [
                    // 바다 배경
                    _buildOceanBackground(),

                    // 낚싯줄과 쓰레기
                    _buildFishingHook(),

                    // 게임 상태 안내
                    _buildGameStateGuide(),
                  ],
                ),
              ),

              // 하단 안내
              _buildBottomGuide(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildScoreItem('총 포인트', '$_totalPoints P', Colors.green),
          _buildScoreItem('수거 개수', '$_catchCount 개', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildOceanBackground() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '🌊',
            style: TextStyle(fontSize: 100),
          ),
          const SizedBox(height: 8),
          Text(
            '바다를 깨끗하게!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFishingHook() {
    return AnimatedBuilder(
      animation: _hookAnimation,
      builder: (context, child) {
        return Positioned(
          top: 80 + (_hookAnimation.value * 300),
          left: MediaQuery.of(context).size.width / 2 - 50,
          child: Column(
            children: [
              // 낚싯줄
              Container(
                width: 2,
                height: _hookAnimation.value * 300,
                color: Colors.brown,
              ),
              // 낚싯바늘 또는 쓰레기
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _currentTrash != null
                      ? Colors.white
                      : Colors.grey.shade300,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _currentTrash?.emoji ?? '🎣',
                    style: const TextStyle(fontSize: 50),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGameStateGuide() {
    String guideText = '';
    Color guideColor = Colors.white;

    switch (_gameState) {
      case GameState.ready:
        guideText = '📱 휴대폰을 앞으로 흔들어서\n낚싯줄을 던지세요!';
        guideColor = Colors.yellow.shade700;
        break;
      case GameState.casting:
        guideText = '🎣 낚싯줄을 던지는 중...';
        guideColor = Colors.orange;
        break;
      case GameState.waiting:
        guideText = '⏰ 쓰레기를 기다리는 중...';
        guideColor = Colors.blue.shade200;
        break;
      case GameState.biting:
        guideText = '⚡ 위로 올리세요!';
        guideColor = Colors.red;
        break;
      case GameState.caught:
        guideText = '✅ 수거 성공!';
        guideColor = Colors.green;
        break;
    }

    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: guideColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            guideText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomGuide() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💡 게임 방법',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '1️⃣ 휴대폰을 앞으로 흔들어 낚싯줄 던지기\n'
                  '2️⃣ 쓰레기가 물면 알림이 울립니다\n'
                  '3️⃣ 빠르게 위로 올려서 쓰레기 수거하기',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.start,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '센서 Y축: ${_currentY.toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// 게임 상태 열거형
enum GameState {
  ready,    // 준비
  casting,  // 던지는 중
  waiting,  // 기다리는 중
  biting,   // 쓰레기가 물었음
  caught,   // 잡았음
}
