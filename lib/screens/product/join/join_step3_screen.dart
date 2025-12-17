import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/product_join_request.dart';
import '../../../models/user_coupon.dart';
import '../../../services/flutter_api_service.dart';
import '../../../providers/auth_provider.dart';

/// 🔥 STEP 3: 포인트/쿠폰 선택, 금리 계산
///
/// 기능:
/// - 사용자 포인트 조회
/// - 포인트 사용 입력 (1000점당 0.1% 보너스)
/// - 쿠폰 선택
/// - 실시간 금리 계산
/// - 예상 이자 계산

class JoinStep3Screen extends StatefulWidget {
  final ProductJoinRequest request;

  const JoinStep3Screen({
    super.key,
    required this.request,
  });

  @override
  State<JoinStep3Screen> createState() => _JoinStep3ScreenState();
}

class _JoinStep3ScreenState extends State<JoinStep3Screen> {
  final FlutterApiService _apiService = FlutterApiService(
    baseUrl: 'http://10.0.2.2:8080/busanbank/api',
  );

  int _totalPoints = 0;
  List<UserCoupon> _coupons = [];
  int? _selectedCouponId;
  int? _selectedPointAmount;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // ✅ 강제 로그!
    print('========================================');
    print('🔥 _loadUserData() 시작!');
    print('========================================');

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    print('[DEBUG] authProvider.userNo: ${authProvider.userNo}');

    final userNo = authProvider.userNo;

    if (userNo == null) {
      print('[ERROR] ❌ userNo가 null입니다!');
      return;
    }

    try {
      print('[DEBUG] 📌 포인트 조회 시작...');
      final pointsData = await _apiService.getUserPoints(userNo);
      print('[DEBUG] ✅ 포인트 응답: $pointsData');

      print('[DEBUG] 📌 쿠폰 조회 시작...');
      final coupons = await _apiService.getUserCoupons(userNo);
      print('[DEBUG] ✅ 쿠폰: ${coupons.length}개');

      setState(() {
        _totalPoints = pointsData['totalPoints'] ?? 0;
        _coupons = coupons;
        _isLoading = false;
      });

    } catch (e, stackTrace) {
      print('[ERROR] ❌ 실패: $e');
      print('[ERROR] 스택: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('STEP 3/4 - 금리 우대'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 진행 표시
            _buildProgressIndicator(),
            const SizedBox(height: 24),

            // 포인트 사용
            _buildPointSection(),
            const SizedBox(height: 24),

            // 쿠폰 선택
            _buildCouponSection(),
            const SizedBox(height: 24),

            // 금리 정보
            _buildInterestRateInfo(),
            const SizedBox(height: 24),

            // 예상 수익
            _buildExpectedProfit(),
            const SizedBox(height: 32),

            // 다음 버튼
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        _buildProgressCircle(1, true),
        _buildProgressLine(true),
        _buildProgressCircle(2, true),
        _buildProgressLine(true),
        _buildProgressCircle(3, true),
        _buildProgressLine(false),
        _buildProgressCircle(4, false),
      ],
    );
  }

  Widget _buildProgressCircle(int step, bool isActive) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.blue : Colors.grey.shade300,
      ),
      child: Center(
        child: Text(
          '$step',
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? Colors.blue : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildPointSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '포인트 사용',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_totalPoints}P 보유 중',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '보유 포인트',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_totalPoints}P',
                  style: const TextStyle(fontSize: 16),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedPointAmount = _totalPoints;
                    });
                  },
                  child: const Text(
                    '전액 사용',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '사용할 포인트',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '0',
              suffix: const Text('P'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _selectedPointAmount = int.tryParse(value);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCouponSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '쿠폰 선택',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_coupons.isEmpty)
          const Text(
            '사용 가능한 쿠폰이 없습니다.',
            style: TextStyle(color: Colors.grey),
          )
        else
          ..._coupons.map((coupon) => _buildCouponItem(coupon)),
      ],
    );
  }

  Widget _buildCouponItem(UserCoupon coupon) {
    final isSelected = _selectedCouponId == coupon.ucNo;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Colors.blue.shade50 : Colors.white,
      child: ListTile(
        title: Text(
          coupon.couponName,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '금리 우대: ${coupon.bonusRate}%',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            // ✅ 추가 정보 (선택사항)
            if (coupon.expireDate != null)
              Text(
                '만료일: ${_formatDate(coupon.expireDate!)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
        trailing: Radio<int>(
          value: coupon.ucNo,
          groupValue: _selectedCouponId,
          onChanged: (value) {
            setState(() {
              _selectedCouponId = value;
            });
          },
        ),
      ),
    );
  }

  // ✅ 날짜 포맷 헬퍼
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildInterestRateInfo() {
    final baseRate = 2.30;
    final bonusRate = _getSelectedCouponRate();
    final totalRate = baseRate + bonusRate;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('기본 금리'),
              Text('$baseRate%'),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '최종 적용 금리',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '$totalRate%',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpectedProfit() {
    final principal = widget.request.principalAmount ?? 0;
    final term = widget.request.contractTerm ?? 0;
    final rate = 2.30 + _getSelectedCouponRate();
    final expectedProfit = _calculateProfit(principal, term, rate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '예상 수익',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('가입 금액'),
              Text('${_formatNumber(principal)}원'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('예상 이자'),
              Text(
                '${_formatNumber(expectedProfit)}원',
                style: const TextStyle(color: Colors.blue),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '만기 금액',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${_formatNumber(principal + expectedProfit)}원',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _goToStep4,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          '다음 (STEP 4)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  double _getSelectedCouponRate() {
    if (_selectedCouponId == null) return 0.0;
    final coupon = _coupons.firstWhere(
          (c) => c.ucNo == _selectedCouponId,
      orElse: () => _coupons.first,
    );
    return coupon.bonusRate;
  }

  int _calculateProfit(int principal, int months, double rate) {
    return (principal * (rate / 100) * (months / 12)).round();
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  void _goToStep4() {
    // STEP 4로 이동
    final updatedRequest = ProductJoinRequest(
      productNo: widget.request.productNo,
      productName: widget.request.productName,
      principalAmount: widget.request.principalAmount,
      contractTerm: widget.request.contractTerm,
      accountPassword: widget.request.accountPassword,
      branchId: widget.request.branchId,
      empId: widget.request.empId,
      agreedTermIds: widget.request.agreedTermIds,
      selectedCouponId: _selectedCouponId,
      usedPoints: _selectedPointAmount ?? 0,  // ✅ usedPoints!
    );

    Navigator.pushNamed(
      context,
      '/product/join/step4',
      arguments: updatedRequest,
    );
  }
}