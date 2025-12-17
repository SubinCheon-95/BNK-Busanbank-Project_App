import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tkbank/providers/auth_provider.dart';
import 'package:tkbank/services/flutter_api_service.dart';

// 2025-12-16 - 출석체크 화면 (API 연동) - 작성자: 진원
// 2025-12-17 - FlutterApiService 사용하도록 수정 (JWT 토큰 자동 추가) - 작성자: 진원
class AttendanceCheckScreen extends StatefulWidget {
  final String baseUrl;

  const AttendanceCheckScreen({super.key, required this.baseUrl});

  @override
  State<AttendanceCheckScreen> createState() => _AttendanceCheckScreenState();
}

class _AttendanceCheckScreenState extends State<AttendanceCheckScreen> {
  late FlutterApiService _apiService;
  bool isCheckedToday = false;
  int consecutiveDays = 0;
  int totalPoints = 0;
  bool isLoading = false;

  // 이번 주 출석 현황 (월~일)
  List<bool> weeklyAttendance = [false, false, false, false, false, false, false];

  @override
  void initState() {
    super.initState();
    _apiService = FlutterApiService(baseUrl: widget.baseUrl);
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // 로그인한 사용자 정보 가져오기
      final authProvider = context.read<AuthProvider>();
      final userNo = authProvider.userNo;

      if (userNo == null) {
        throw Exception('로그인이 필요합니다');
      }

      final data = await _apiService.getAttendanceStatus(userNo);

      setState(() {
        isCheckedToday = data['isCheckedToday'] ?? false;
        consecutiveDays = data['consecutiveDays'] ?? 0;
        totalPoints = data['totalPoints'] ?? 0;

        // 주간 출석 현황
        List<dynamic> weeklyData = data['weeklyAttendance'] ?? [];
        for (int i = 0; i < weeklyData.length && i < 7; i++) {
          weeklyAttendance[i] = weeklyData[i] ?? false;
        }

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 로드 실패: $e')),
        );
      }
    }
  }

  Future<void> _checkAttendance() async {
    if (isCheckedToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('오늘은 이미 출석체크를 완료했습니다')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // 로그인한 사용자 정보 가져오기
      final authProvider = context.read<AuthProvider>();
      final userNo = authProvider.userNo;

      if (userNo == null) {
        throw Exception('로그인이 필요합니다');
      }

      final data = await _apiService.checkAttendance(userNo);

      setState(() {
        isLoading = false;
      });

      if (data['success'] == true) {
        // 출석 체크 성공 - 데이터 새로고침
        await _loadAttendanceData();

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('출석 완료!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${data['earnedPoints']} 포인트 적립!',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '연속 ${data['consecutiveDays']}일 출석 중',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (data['bonusPoints'] != null && data['bonusPoints'] > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '🎉 보너스 ${data['bonusPoints']}P 추가!',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        }
      } else {
        // 실패 메시지 표시
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? '출석 체크 실패')),
          );
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('출석체크 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(DateTime.now());
    final weekDays = ['월', '화', '수', '목', '금', '토', '일'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('출석체크'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 오늘 날짜
            Text(
              today,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),

            // 출석 현황 카드
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // 연속 출석일
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          icon: Icons.local_fire_department,
                          label: '연속 출석',
                          value: '$consecutiveDays일',
                          color: Colors.orange,
                        ),
                        _buildStatItem(
                          icon: Icons.stars,
                          label: '누적 포인트',
                          value: '$totalPoints P',
                          color: Colors.amber,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 이번 주 출석 현황
                    const Text(
                      '이번 주 출석 현황',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(7, (index) {
                        return Column(
                          children: [
                            Text(
                              weekDays[index],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: weeklyAttendance[index]
                                    ? const Color(0xFF4CAF50)
                                    : Colors.grey[300],
                              ),
                              child: weeklyAttendance[index]
                                  ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                                  : null,
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 출석체크 버튼
            SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: isCheckedToday ? null : _checkAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isCheckedToday ? '오늘 출석 완료!' : '출석 체크하기',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 안내 메시지
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '출석체크 안내',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('• 매일 출석하면 10 포인트를 받을 수 있어요'),
                  Text('• 7일 연속 출석 시 보너스 50 포인트 지급'),
                  Text('• 포인트는 다양한 혜택으로 사용 가능해요'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}