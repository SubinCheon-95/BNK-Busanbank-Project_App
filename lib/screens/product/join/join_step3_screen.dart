import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/product_join_request.dart';
import '../../../models/user_coupon.dart';
import '../../../services/flutter_api_service.dart';
import '../../../providers/auth_provider.dart';
import 'join_step4_screen.dart';

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

  String? _selectedCouponKey;
  int? _selectedPointAmount;
  bool _isLoading = true;

  // ✅ 추가!
  bool _contractAgreed = false;  // 예금상품계약서 동의

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

      // ✅ 여기를 변경 추가
      for (final c in coupons) {
        print('✅ 쿠폰 파싱확인: ucNo=${c.ucNo}, couponNo=${c.couponNo}, name=${c.couponName}, status=${c.status}');
      }

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

            // ✅ 계약서 섹션
            _buildContractSection(),

            const SizedBox(height: 100),

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
    // ✅ 여기 변경
    final couponKey = coupon.ucNo.toString();
    // final couponKey = coupon.ucNo != 0
    //     ? coupon.ucNo.toString()
    //     : coupon.couponName;

    final isSelected = _selectedCouponKey == couponKey;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Colors.blue.shade50 : Colors.white,
      child: ListTile(
        onTap: () {
          // ✅ ListTile 탭도 동일 동작 (라디오/타일 어디 눌러도 똑같이)
          setState(() {
            _selectedCouponKey = (isSelected) ? null : couponKey;
          });
          print('📌 쿠폰 클릭: key=$couponKey, 이름=${coupon.couponName}, 금리=${coupon.bonusRate}%');
        },
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
        trailing: Radio<String>(
          value: couponKey,                 // ✅ String
          groupValue: _selectedCouponKey,   // ✅ String?
          toggleable: true,                // ✅ 다시 누르면 해제됨
          onChanged: (value) {
            setState(() {
              _selectedCouponKey = value;   // toggleable이라 null도 들어올 수 있음
            });
            print('📌 Radio 변경: $_selectedCouponKey');
          },
          activeColor: Colors.blue,
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 1. _buildInterestRateInfo 수정 (360줄 근처)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ✅ 날짜 포맷 헬퍼
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildInterestRateInfo() {
    // ✅ 상품 기본 금리 (하드코딩 X!)
    final baseRate = widget.request.baseRate ?? 0.0;
    final couponBonus = _getSelectedCouponRate();
    final pointBonus = (_selectedPointAmount ?? 0) * 0.001;
    final totalRate = baseRate + couponBonus + pointBonus;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 기본 금리
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('기본 금리'),
              Text('${baseRate.toStringAsFixed(2)}%'),
            ],
          ),

          // ✅ 쿠폰 보너스 (있을 때만)
          if (couponBonus > 0) ...[
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('쿠폰 보너스', style: TextStyle(color: Colors.green)),
                Text(
                  '+${couponBonus.toStringAsFixed(2)}%',
                  style: const TextStyle(color: Colors.green),
                ),
              ],
            ),
          ],

          // ✅ 포인트 보너스 (있을 때만)
          if (pointBonus > 0) ...[
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('포인트 보너스', style: TextStyle(color: Colors.orange)),
                Text(


                  '+${pointBonus.toStringAsFixed(2)}%',
                  style: const TextStyle(color: Colors.orange),
                ),
              ],
            ),
          ],

          const Divider(height: 24),

          // 최종 적용 금리
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '최종 적용 금리',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '${totalRate.toStringAsFixed(2)}%',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 2. _buildExpectedProfit
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildExpectedProfit() {
    final principal = widget.request.principalAmount ?? 0;
    final term = widget.request.contractTerm ?? 0;

    // ✅ 동적 금리 계산
    final baseRate = widget.request.baseRate ?? 0.0;
    final couponBonus = _getSelectedCouponRate();
    final pointBonus = (_selectedPointAmount ?? 0) * 0.001;
    final totalRate = baseRate + couponBonus + pointBonus;

    final expectedProfit = _calculateProfit(principal, term, totalRate);

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
              const Text('가입 기간'),
              Text('$term개월'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('적용 금리'),
              Text(
                '${totalRate.toStringAsFixed(2)}%',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '${_formatNumber(principal + expectedProfit)}원',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 3. _buildContractTable 수정 (633줄 근처)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildContractTable() {
    final req = widget.request;
    final today = DateTime.now();

    // ✅ 동적 금리 계산
    final baseRate = widget.request.baseRate ?? 0.0;
    final couponBonus = _getSelectedCouponRate();
    final pointBonus = (_selectedPointAmount ?? 0) * 0.001;
    final totalRate = baseRate + couponBonus + pointBonus;

    return Table(
      border: TableBorder.all(color: Colors.grey[300]!),
      children: [
        _buildTableRow('상품명', req.productName ?? ''),
        _buildTableRow(
          '신규 금액',
          '${_formatNumber(req.principalAmount ?? 0)}원',
        ),
        _buildTableRow('계약 기간', '${req.contractTerm ?? 0}개월'),
        _buildTableRow(
          '최초 신규 적용 이율',
          '연 ${totalRate.toStringAsFixed(2)}%',  // ✅ 동적!
        ),
        _buildTableRow('이자 지급 방식', '만기일시지급 단리식'),
        _buildTableRow('과세 구분', '일반과세'),
        _buildTableRow(
          '계약 체결일',
          '${today.year}.${today.month}.${today.day}',
        ),
      ],
    );
  }


  // ✅ 계약서 섹션 추가!
  Widget _buildContractSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '예금상품계약서 전자서명 동의',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '계약서 내용을 확인하셨습니까?',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _showContractDialog,
            icon: const Icon(Icons.description),
            label: const Text('계약서 확인하기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(
                value: _contractAgreed,
                onChanged: (value) {
                  setState(() {
                    _contractAgreed = value ?? false;
                  });
                },
              ),
              const Expanded(
                child: Text(
                  '예금상품계약서 내용을 확인하였으며 동의합니다.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 4. 계약서 다이얼로그 추가
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void _showContractDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          '[예금상품 계약서]',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 계약 정보 테이블
              _buildContractTable(),

              const SizedBox(height: 16),

              const Text(
                '■ 예금상품 계약 체결에 관한 사항',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              const Text(
                '본인은 위 예금상품의 중요한 사항을 충분히 설명받고 이해하였습니까?',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),

              const Text(
                '✅ 예, 충분히 설명받고 이해하였습니다.',
                style: TextStyle(fontSize: 13, color: Colors.green),
              ),
              const SizedBox(height: 16),

              const Text(
                '■ 예금상품의 중요 내용 요약',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              const Text(
                '• 상품의 개요 (계약 기간, 이자의 지급 시기 및 지급 방식 등)\n'
                    '• 이자율 및 이자 계산 방법, 중도해지 이자율\n'
                    '• 계약 해지 조건, 예금자 보호 여부\n'
                    '• 손실 발생 위험, 민원 처리 및 분쟁 조정',
                style: TextStyle(fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '이 예금 상품 계약서에 명시된 모든 내용을 충분히 읽고 이해하였으며, 이 계약에 동의합니다.',
                  style: TextStyle(fontSize: 12, height: 1.5),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('닫기'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _contractAgreed = true;
              });
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('계약서 내용을 확인했습니다.')),
              );
            },
            child: const Text('확인 및 동의'),
          ),
        ],
      ),
    );
  }


  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 5. 계약 정보 테이블 추가
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━



  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.grey[200],
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          child: Text(
            value,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
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

  // 쿠폰 리스트 비었을 때도 안 터짐 + null 방어
  double _getSelectedCouponRate() {
    if (_selectedCouponKey == null) return 0.0;
    if (_coupons.isEmpty) return 0.0;

    final selected = _coupons.where((c) => c.ucNo.toString() == _selectedCouponKey).toList();
    if (selected.isEmpty) {
      print('[DEBUG] ❌ 선택 key=$_selectedCouponKey 인 쿠폰을 못 찾음 → 0% 처리');
      return 0.0;
    }

    final coupon = selected.first;
    final rate = coupon.bonusRate.toDouble();

    print('[DEBUG] ✅ 선택된 쿠폰: ${coupon.couponName}, ucNo=${coupon.ucNo}, 금리: $rate%');
    return rate;
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


  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 6. _goToStep4 메서드 수정 - 계약서 동의 체크
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ✅ 계약서 동의 체크 추가!
  void _goToStep4() {
    // ✅ 계약서 동의 체크 추가!
    if (!_contractAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('예금상품계약서를 확인하고 동의해주세요.')),
      );
      return;
    }

    final baseRate = widget.request.baseRate ?? 0.0;
    final bonusRate = _getSelectedCouponRate();
    final pointBonus = (_selectedPointAmount ?? 0) * 0.001;
    final totalRate = baseRate + bonusRate + pointBonus;

    // ✅ 여기를 변경
    int? selectedCouponUcNo;
    if (_selectedCouponKey != null) {
      final matches = _coupons.where((c) => c.ucNo.toString() == _selectedCouponKey).toList();
      if (matches.isNotEmpty) {
        selectedCouponUcNo = matches.first.ucNo; // ✅ 그대로 전송
      } else {
        selectedCouponUcNo = null;
      }
    }

    print('[DEBUG] 📊 최종 금리:');
    print('[DEBUG]    기본: $baseRate%, 쿠폰: $bonusRate%, 포인트: $pointBonus%');
    print('[DEBUG]    최종: $totalRate%');
    print('[DEBUG]    선택 쿠폰 key: $_selectedCouponKey');
    print('[DEBUG]    선택 쿠폰 ucNo: $selectedCouponUcNo');

    // ✅✅✅ copyWith 사용! (HP, 비밀번호 유지!)
    final updatedRequest = widget.request.copyWith(
      selectedCouponId: selectedCouponUcNo,  // ✅ int!
      usedPoints: _selectedPointAmount ?? 0,
      pointBonusRate: pointBonus,
      couponBonusRate: bonusRate,
      applyRate: totalRate,
    );

    print('[DEBUG] 📋 STEP4로 전달:');
    print('[DEBUG]    HP: ${updatedRequest.notificationHp}');
    print('[DEBUG]    Email: ${updatedRequest.notificationEmailAddr}');
    print('[DEBUG]    Password: ${updatedRequest.accountPasswordOriginal != null ? "있음" : "없음"}');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JoinStep4Screen(
          baseUrl: 'http://10.0.2.2:8080/busanbank/api',
          request: updatedRequest,
        ),
      ),
    );
  }

}