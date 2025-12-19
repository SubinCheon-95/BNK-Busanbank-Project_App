import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:tkbank/providers/auth_provider.dart';
import 'package:tkbank/services/step_point_service.dart';


class StepCounterPage extends StatefulWidget {
  @override
  _StepCounterPageState createState() => _StepCounterPageState();
}

class _StepCounterPageState extends State<StepCounterPage> with SingleTickerProviderStateMixin {
  late Stream<StepCount> _stepCountStream;
  String _steps = '0';
  String _status = '대기 중';
  bool _permissionDenied = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final int _goalSteps = 10000;
  final StepPointService _stepPointService = StepPointService();

  @override
  void initState() {
    super.initState();
    _requestPermission();

    // 애니메이션 설정
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    setState(() {
      _status = '권한 확인 중...';
    });

    PermissionStatus status = await Permission.activityRecognition.request();

    if (status.isGranted) {
      _initPedometer();
    } else if (status.isDenied) {
      setState(() {
        _status = '권한이 거부되었습니다';
        _permissionDenied = true;
      });
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _status = '설정에서 권한을 허용해주세요';
        _permissionDenied = true;
      });
    }
  }

  void _initPedometer() {
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(_onStepCount).onError(_onStepCountError);

    setState(() {
      _status = '측정 중';
    });
  }

  void _onStepCount(StepCount event) {
    setState(() {
      _steps = event.steps.toString();
    });
  }

  void _onStepCountError(error) {
    setState(() {
      _status = '센서 오류: $error';
    });
  }

  bool get _isGoalAchieved => int.tryParse(_steps) != null && int.parse(_steps) >= _goalSteps;

  double get _progress {
    final steps = int.tryParse(_steps) ?? 0;
    return (steps / _goalSteps).clamp(0.0, 1.0);
  }

  // CO2 감소량 계산 (걸음 수 기반)
  double get _co2Reduced {
    final steps = int.tryParse(_steps) ?? 0;
    // 10,000보 = 약 5km 걷기 = 자동차 대비 약 0.8kg CO2 감소
    return (steps / 10000) * 0.8;
  }

  // 나무 심기 효과
  int get _treesPlanted {
    final steps = int.tryParse(_steps) ?? 0;
    // 10,000보마다 나무 1그루 심기 효과
    return (steps / 10000).floor();
  }

  Future<void> _claimPoints() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userNo = authProvider.userNo;

    if (userNo == null) {
      _showDialog('오류', '로그인 정보를 찾을 수 없습니다');
      return;
    }

    if (!_isGoalAchieved) {
      _showDialog('목표 미달성', '10,000보를 달성해야 포인트를 받을 수 있습니다');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final result = await _stepPointService.earnStepsPoints(
        userNo: userNo,
        steps: int.parse(_steps),
        date: today,
      );

      if (result['success'] == true) {
        _showSuccessDialog(
          '🎉 지구를 지켰습니다!',
          '${result['earnedPoints']}포인트 적립\n탄소 ${_co2Reduced.toStringAsFixed(2)}kg 감소',
        );
      } else {
        _showDialog('지급 실패', result['message'] ?? '포인트 지급에 실패했습니다');
      }
    } catch (e) {
      _showDialog('오류', e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(Icons.eco, color: Colors.green, size: 60),
            SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
        content: Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _permissionDenied
          ? _buildPermissionDenied()
          : _buildESGStepCounter(),
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, size: 80, color: Colors.orange),
          SizedBox(height: 20),
          Text(
            _status,
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              openAppSettings();
            },
            child: Text('설정에서 권한 허용하기'),
          ),
        ],
      ),
    );
  }

  Widget _buildESGStepCounter() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF4CAF50),
            Color(0xFF81C784),
            Colors.white,
          ],
          stops: [0.0, 0.3, 0.5],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 헤더
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      '만보기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 48),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // 메인 지구 비주얼
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.blue[400]!,
                        Colors.green[700]!,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.public, size: 100, color: Colors.white.withOpacity(0.3)),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _steps,
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '걸음',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 10),

              // 진행률 바
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _isGoalAchieved ? Colors.amber : Colors.white,
                      ),
                      minHeight: 8,
                    ),
                    SizedBox(height: 8),
                    Text(
                      '목표까지 ${_goalSteps - (int.tryParse(_steps) ?? 0)} 걸음',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30),

              // ESG 임팩트 카드
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '오늘의 환경 기여도',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 24),

                    // CO2 감소
                    _buildImpactItem(
                      icon: Icons.cloud_off,
                      color: Colors.blue[400]!,
                      label: 'CO₂ 감소량',
                      value: '${_co2Reduced.toStringAsFixed(2)} kg',
                      subtitle: '자동차 대비',
                    ),

                    SizedBox(height: 16),
                    Divider(),
                    SizedBox(height: 16),

                    // 나무 심기
                    _buildImpactItem(
                      icon: Icons.park,
                      color: Colors.green[600]!,
                      label: '나무 심기 효과',
                      value: '$_treesPlanted 그루',
                      subtitle: '산소 생성',
                    ),

                    SizedBox(height: 16),
                    Divider(),
                    SizedBox(height: 16),

                    // 칼로리 소모
                    _buildImpactItem(
                      icon: Icons.local_fire_department,
                      color: Colors.orange[600]!,
                      label: '칼로리 소모',
                      value: '${((int.tryParse(_steps) ?? 0) * 0.04).toStringAsFixed(0)} kcal',
                      subtitle: '건강 증진',
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // 보상 안내
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber[400]!, Colors.orange[400]!],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.stars, color: Colors.white, size: 40),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '목표 달성 보상',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '10,000보 달성 시 100 포인트',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // 포인트 받기 버튼
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isGoalAchieved && !_isLoading ? _claimPoints : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isGoalAchieved ? Colors.green[600] : Colors.grey[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: _isGoalAchieved ? 8 : 2,
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isGoalAchieved ? Icons.eco : Icons.directions_walk,
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Text(
                          _isGoalAchieved ? '포인트 받고 지구 지키기' : '목표를 향해 걸어요!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImpactItem({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}