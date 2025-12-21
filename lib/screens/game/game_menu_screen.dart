import 'package:flutter/material.dart';
import 'attendance_check_screen.dart';
import 'branch_map_webview_screen.dart';
import '../esg_fishing_screen.dart';

// 2025-12-16 - 금융게임 메뉴 화면 (출석체크, 영업점체크인) - 작성자: 진원
// 2025-12-17 - 영업점 체크인 카카오맵 WebView로 변경 - 작성자: 진원
// 2025-12-20 - ESG 낚시 게임 추가 - 작성자: 진원
class GameMenuScreen extends StatelessWidget {
  final String baseUrl;

  const GameMenuScreen({super.key, required this.baseUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('금융게임'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 게임 아이콘
            const Icon(
              Icons.games,
              size: 80,
              color: Color(0xFF6A1B9A),
            ),
            const SizedBox(height: 24),
            const Text(
              '금융게임',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '포인트를 모으고 혜택을 받으세요!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 48),

            // 출석체크 버튼
            SizedBox(
              width: double.infinity,
              child: Card(
                elevation: 4,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AttendanceCheckScreen(baseUrl: baseUrl),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            size: 32,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '출석체크',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '매일 출석하고 포인트 받기',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 영업점체크인 버튼
            SizedBox(
              width: double.infinity,
              child: Card(
                elevation: 4,
                child: InkWell(
                  onTap: () {
                    // 2025-12-17 - 카카오맵 WebView로 변경 - 작성자: 진원
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BranchMapWebViewScreen(baseUrl: baseUrl),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            size: 32,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '영업점 체크인',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '영업점 방문하고 포인트 받기',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ESG 낚시 게임 버튼
            SizedBox(
              width: double.infinity,
              child: Card(
                elevation: 4,
                child: InkWell(
                  onTap: () {
                    // 2025-12-20 - ESG 낚시 게임으로 이동 - 작성자: 진원
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EsgFishingScreen(baseUrl: baseUrl),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00BCD4).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.waves,
                            size: 32,
                            color: Color(0xFF00BCD4),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '🌊 ESG 바다 청소',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '쓰레기 수거하고 포인트 받기',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
