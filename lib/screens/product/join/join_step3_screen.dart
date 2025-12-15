import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/product_join_request.dart';
import '../../../models/user_coupon.dart';
import '../../../services/flutter_api_service.dart';
import 'join_step4_screen.dart';
import 'dart:math' as math;

/// 🔥 STEP 3: 포인트/쿠폰 선택, 금리 계산
///
/// 기능:
/// - 사용자 포인트 조회
/// - 포인트 사용 입력 (1000점당 0.1% 보너스)
/// - 쿠폰 선택
/// - 실시간 금리 계산
/// - 예상 이자 계산
class JoinStep3Screen extends StatefulWidget {
  final String baseUrl;
  final ProductJoinRequest request;

  const JoinStep3Screen({
    super.key,
    required this.baseUrl,
    required this.request,
  });

  @override
  State<JoinStep3Screen> createState() => _JoinStep3ScreenState();
}

class _JoinStep3ScreenState extends State<JoinStep3Screen> {
  late FlutterApiService _apiService;

  // 포인트
  int _totalPoints = 0;
  int _usedPoints = 0;
  final TextEditingController _pointsCtrl = TextEditingController();
  bool _loadingPoints = true;

  // 쿠폰
  List<UserCoupon> _coupons = [];
  int? _selectedCouponId;
  bool _loadingCoupons = true;

  // 금리 계산
  double _baseRate = 0.0;
  double _pointBonusRate = 0.0;
  double _couponBonusRate = 0.0;
  double _finalRate = 0.0;

  @override
  void initState() {
    super.initState();
    _apiService = FlutterApiService(baseUrl: widget.baseUrl);
    _baseRate = widget.request.baseRate ?? 0.0;
    _finalRate = _baseRate;
    _loadUserData();
  }

  @override
  void dispose() {
    _pointsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    // 🔥 김부산 userNo = 231837269 (하드코딩)
    const userNo = 231837269;

    try {
      // 포인트 조회
      final pointsData = await _apiService.getUserPoints(userNo);
      setState(() {
        _totalPoints = pointsData['totalPoints'] ?? 0;
        _loadingPoints = false;
      });
    } catch (e) {
      setState(() => _loadingPoints = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('포인트 조회 실패: $e')),
        );
      }
    }

    try {
      // 쿠폰 조회
      final coupons = await _apiService.getUserCoupons(userNo);
      setState(() {
        _coupons = coupons;
        _loadingCoupons = false;
      });
    } catch (e) {
      setState(() => _loadingCoupons = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('쿠폰 조회 실패: $e')),
        );
      }
    }
  }

  void _calculateRate() {
    // 포인트 보너스: 1000점당 0.1%
    _pointBonusRate = (_usedPoints / 1000) * 0.1;

    // 쿠폰 보너스
    _couponBonusRate = 0.0;
    if (_selectedCouponId != null) {
      try {
        final coupon =
        _coupons.firstWhere((c) => c.couponId == _selectedCouponId);
        _couponBonusRate = coupon.bonusRate;
      } catch (e) {
        // 쿠폰을 찾지 못한 경우
        _couponBonusRate = 0.0;
      }
    }

    // 최종 금리
    _finalRate = _baseRate + _pointBonusRate + _couponBonusRate;

    setState(() {});
  }

  int _calculateInterest() {
    final amount = widget.request.principalAmount ?? 0;
    final months = widget.request.contractTerm ?? 0;

    // 단리 계산: 원금 × 금리 × (기간/12)
    final interest = (amount * (_finalRate / 100) * (months / 12)).toInt();
    return interest;
  }

  void _goNext() {
    // 포인트 사용 가능 여부 확인
    if (_usedPoints > _totalPoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('보유 포인트를 초과하여 사용할 수 없습니다.')),
      );
      return;
    }

    final updated = widget.request.copyWith(
      usedPoints: _usedPoints,
      selectedCouponId: _selectedCouponId,
      pointBonusRate: _pointBonusRate,
      couponBonusRate: _couponBonusRate,
      applyRate: _finalRate,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JoinStep4Screen(
          baseUrl: widget.baseUrl,
          request: updated,
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('STEP 3/4 - 포인트/쿠폰 선택'),
      ),
      body: Column(
        children: [
          // 진행 바
          _buildProgressBar(),

          // 내용
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 상품명
                Text(
                  widget.request.productName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                // 포인트 사용
                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                const Text(
                  '포인트 사용',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                _loadingPoints
                    ? const Center(child: CircularProgressIndicator())
                    : Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('보유 포인트'),
                            Text(
                              '${_formatNumber(_totalPoints)}P',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: _pointsCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: '사용할 포인트',
                            border: const OutlineInputBorder(),
                            suffixText: 'P',
                            helperText: '1,000P 당 금리 +0.1%',
                          ),
                          onChanged: (v) {
                            setState(() {
                              _usedPoints = int.tryParse(v) ?? 0;
                              _calculateRate();
                            });
                          },
                        ),

                        const SizedBox(height: 8),

                        // 전체 사용 버튼
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _usedPoints = _totalPoints;
                              _pointsCtrl.text = _totalPoints.toString();
                              _calculateRate();
                            });
                          },
                          child: const Text('전체 사용'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                // 쿠폰 선택
                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                const Text(
                  '쿠폰 선택',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                _loadingCoupons
                    ? const Center(child: CircularProgressIndicator())
                    : _coupons.isEmpty
                    ? Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.card_giftcard,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '사용 가능한 쿠폰이 없습니다',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                    : Column(
                  children: [
                    // 쿠폰 미사용 옵션
                    RadioListTile<int?>(
                      value: null,
                      groupValue: _selectedCouponId,
                      onChanged: (id) {
                        setState(() {
                          _selectedCouponId = id;
                          _calculateRate();
                        });
                      },
                      title: const Text('쿠폰 사용 안 함'),
                      contentPadding: EdgeInsets.zero,
                    ),

                    // 쿠폰 목록
                    ..._coupons.map((coupon) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: RadioListTile<int>(
                          value: coupon.couponId,
                          groupValue: _selectedCouponId,
                          onChanged: (id) {
                            setState(() {
                              _selectedCouponId = id;
                              _calculateRate();
                            });
                          },
                          title: Text(
                            coupon.couponName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '금리 +${coupon.bonusRate.toStringAsFixed(2)}%',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.local_offer,
                              color: Colors.red[700],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),

                const SizedBox(height: 24),

                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                // 금리 계산 결과
                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                const Text(
                  '금리 계산',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _rateRow('기본 금리', _baseRate),
                        if (_pointBonusRate > 0)
                          _rateRow('포인트 보너스', _pointBonusRate,
                              color: Colors.blue),
                        if (_couponBonusRate > 0)
                          _rateRow('쿠폰 보너스', _couponBonusRate,
                              color: Colors.red),
                        const Divider(height: 24, thickness: 2),
                        _rateRow(
                          '최종 적용 금리',
                          _finalRate,
                          isBold: true,
                          fontSize: 20,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                '예상 이자',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatNumber(_calculateInterest())}원',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '만기 수령액: ${_formatNumber((widget.request.principalAmount ?? 0) + _calculateInterest())}원',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),

          // 하단 버튼
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _rateRow(
      String label,
      double rate, {
        bool isBold = false,
        double fontSize = 16,
        Color? color,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
              color: color,
            ),
          ),
          Text(
            '${rate > 0 ? '+' : ''}${rate.toStringAsFixed(2)}%',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStep(1, true),
          _buildLine(true),
          _buildStep(2, true),
          _buildLine(true),
          _buildStep(3, true),
          _buildLine(false),
          _buildStep(4, false),
        ],
      ),
    );
  }

  Widget _buildStep(int step, bool active) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? Theme.of(context).primaryColor : Colors.grey[300],
      ),
      child: Center(
        child: Text(
          '$step',
          style: TextStyle(
            color: active ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLine(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        color: active ? Theme.of(context).primaryColor : Colors.grey[300],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 56),
                ),
                child: const Text('이전'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _goNext,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 56),
                ),
                child: const Text('다음 (STEP 4)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}