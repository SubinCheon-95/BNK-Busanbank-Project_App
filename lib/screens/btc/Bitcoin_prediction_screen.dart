import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/bitcoin_service.dart';

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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: Colors.green.shade600,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '예측이 접수됐어요',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '내일 결과를 알려드릴게요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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

      await _bitcoinService.submitEventResult(
        prediction,
        userNo,
        needsAuth: true
      );

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      print('예측 처리 실패: $e');
    }
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
            onTap: _loading ? null : () => _handlePrediction('UP'),
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
            onTap: _loading ? null : () => _handlePrediction('DOWN'),
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