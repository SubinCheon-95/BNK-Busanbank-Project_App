import 'package:flutter/material.dart';
import 'package:tkbank/screens/home/easy_home_screen.dart';
import '../../config/app_config.dart';
import '../../main.dart';

class BitcoinSuccessPage extends StatelessWidget {

  final int yesterday;
  final int today;

  const BitcoinSuccessPage({
    Key? key,
    required this.yesterday,
    required this.today,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 가격 변동률 계산
    final double changePercent = ((today - yesterday) / yesterday * 100);
    final String priceChangeStr = changePercent.toStringAsFixed(2);
    final bool isUp = today >= yesterday;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // 뒤로가기 버튼 제거 (확인 버튼으로 유도)
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // 🎉 이모지 애니메이션 효과를 위해 크게 배치
              const Text(
                '🎉',
                style: TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 24),

              // 제목 및 설명
              const Text(
                '예측 성공!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981), // Green 500
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '축하합니다!\n정확한 시세를 예측하셨네요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // 가격 정보 카드 (전체 너비 활용)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4), // Green 50
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFDCFCE7)),
                ),
                child: Column(
                  children: [
                    Text(
                      '비트코인 변동 결과',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPriceInfo('전일 종가', '$yesterday USD'),
                        const Icon(Icons.arrow_forward, color: Colors.grey),
                        _buildPriceInfo('현재가', '$today USD'),
                      ],
                    ),
                    const Divider(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '수익률 ',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Text(
                          isUp ? '▲ $priceChangeStr%' : '▼ $priceChangeStr%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isUp ? Colors.red : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 🎁 리워드 안내
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB), // Amber 50
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFEF3C7)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('🎁 ', style: TextStyle(fontSize: 18)),
                    Text(
                      '특별 리워드가 지급되었습니다!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB45309), // Amber 700
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 확인 버튼 (하단 고정 느낌)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const EasyHomeScreen(baseUrl: '${AppConfig.baseUrl}/api')), // 이동할 메인 화면
                          (route) => false, // 기존의 모든 경로(route)를 제거
                    );
                  },
                  child: const Text(
                    '확인',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceInfo(String label, String price) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          price,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}