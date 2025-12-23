import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/bitcoin_service.dart';
import 'Bitcoin_fail_page.dart';
import 'Bitcoin_success_page.dart';

class BitcoinPredictionScreen extends StatefulWidget { // 비트코인 예측 이벤트 - 작성자: 윤종인 2025.12.23
  final Function(String)? onPredictionSelected;

  const BitcoinPredictionScreen({
    Key? key,
    this.onPredictionSelected,
  }) : super(key: key);

  @override
  State<BitcoinPredictionScreen> createState() =>
      _BitcoinPredictionScreenState();
}

class _BitcoinPredictionScreenState extends State<BitcoinPredictionScreen> {
  final BitcoinService _bitcoinService = BitcoinService();

  String? _previousClosePrice;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrice();
  }

  Future<void> _loadPrice() async {
    try {
      final result = await _bitcoinService.fetchResult();

      setState(() {
        _previousClosePrice = '${result.yesterday} USD';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _previousClosePrice = '불러오기 실패';
        _loading = false;
      });
    }
  }


  void _handlePrediction(String prediction) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userNo = authProvider.userNo;
      print('userNo 테스트: $userNo');

      if (userNo == null) {
        print('사용자 정보가 없습니다.');
        return;
      }

      final result = await _bitcoinService.fetchResult();
      print('실제 상승하락: ${result.actual}');
      print('예상값: $prediction');

      final bool isSuccess = prediction == result.actual;
      print('isSuccess = $isSuccess');

      await _bitcoinService.submitEventResult(
        isSuccess,
        userNo,
        needsAuth: true
      );

      if (isSuccess) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BitcoinSuccessPage(
              yesterday: result.yesterday,
              today: result.today,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BitcoinFailPage(
              yesterday: result.yesterday,
              today: result.today,
            ),
          ),
        );
      }
    } catch (e) {
      print('예측 처리 실패: $e');
    }
  }

  void showSuccessModal(int yesterday, int today) {
    final priceChange =
    ((today - yesterday) / yesterday * 100).toStringAsFixed(2);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🎉 이모지
                const Text(
                  '🎉',
                  style: TextStyle(fontSize: 64),
                ),
                const SizedBox(height: 16),

                // 제목
                const Text(
                  '예측 성공!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),

                const Text(
                  '축하합니다! 정확하게 예측하셨어요',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),

                // 가격 정보 카드
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '가격 변동',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$yesterday → $today USD',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        priceChange.startsWith('-')
                            ? '⬇ $priceChange%'
                            : '⬆ $priceChange%',
                        style: TextStyle(
                          color: priceChange.startsWith('-')
                              ? Colors.red
                              : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 🎁 리워드
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '🎁 리워드 지급 완료!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 확인 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 32),

              // Stock Info
              _buildStockInfo(),
              const SizedBox(height: 24),

              // Question
              _buildQuestion(),
              const SizedBox(height: 24),

              // Selection Buttons
              _buildSelectionButtons(),
              const SizedBox(height: 24),

              // Footer
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                '🎁 ',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                '특별 이벤트',
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '비트코인 예측 챌린지',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '다음 시세를 예측하고 리워드를 받아가세요!',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStockInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFF6FF), Color(0xFFE0E7FF)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            _loading ? '로딩 중...' : _previousClosePrice ?? '-',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '전일 종가',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion() {
    return const Text(
      '다음 시세는 어떻게 될까요?',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1F2937),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSelectionButtons() {
    return Row(
      children: [
        // 상승 버튼
        Expanded(
          child: _buildPredictionButton(
            label: '상승',
            icon: Icons.trending_up,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF22C55E), Color(0xFF059669)],
            ),
            onTap: _loading ? null : () => _handlePrediction('up'),
          ),
        ),
        const SizedBox(width: 12),
        // 하락 버튼
        Expanded(
          child: _buildPredictionButton(
            label: '하락',
            icon: Icons.trending_down,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEF4444), Color(0xFFE11D48)],
            ),
            onTap: _loading ? null : () => _handlePrediction('down'),
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionButton({
    required String label,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Text(
      '선택 후 결과를 확인할 수 있습니다',
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[400],
      ),
      textAlign: TextAlign.center,
    );
  }
}