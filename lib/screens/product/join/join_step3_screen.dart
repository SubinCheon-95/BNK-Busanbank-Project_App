import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/product_join_request.dart';
import '../../../models/user_coupon.dart';
import '../../../services/flutter_api_service.dart';
import '../../../providers/auth_provider.dart';
import 'join_step4_screen.dart';
import 'package:tkbank/theme/app_colors.dart';
import 'package:flutter/services.dart';

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

  final TextEditingController _pointCtrl = TextEditingController();

  int _totalPoints = 0;
  List<UserCoupon> _coupons = [];

  String? _selectedCouponKey;
  int _selectedPointAmount = 0; // 기존 int? _selectedPointAmount;
  bool _isLoading = true;

  // 추가
  bool _contractAgreed = false;  // 예금상품계약서 동의

  @override
  void dispose() {
    _pointCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // 강제 로그
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
  
  // 콘텐츠 본문 UI 전체 수정 (26/01/04_수빈)
  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.gray1,

      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),

              // 타이틀
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '금리 우대 선택',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    _buildMiniStepIndicator(currentStep: 3),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Text(
                  widget.request.productName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray5,
                  ),
                ),
              ),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      _sectionCard(
                        title: '포인트 사용',
                        child: _buildPointSection(),
                      ),
                      const SizedBox(height: 20),

                      _sectionCard(
                        title: '쿠폰 선택',
                        child: _buildCouponSection(),
                      ),
                      const SizedBox(height: 20),

                      _sectionCard(
                        title: '적용 금리',
                        child: _buildInterestRateInfo(),
                      ),
                      const SizedBox(height: 20),

                      _sectionCard(
                        title: '예상 수익',
                        child: _buildExpectedProfit(),
                      ),
                      const SizedBox(height: 20),

                      _sectionCard(
                        title: '계약 동의',
                        child: _buildContractSection(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 뒤로가기 버튼
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.chevron_left, size: 34),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),

      // 하단 CTA
      bottomNavigationBar: _buildBottomCTA(context),
    );
  }

  // 포인트 사용 UI 전체 수정 (26/01/04_수빈)
  Widget _buildPointSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 보유 포인트 표시(타이틀 중복 X)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '보유 포인트',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.gray5,
              ),
            ),
            Text(
              '${_formatNumber(_totalPoints)}P',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        TextFormField(
          controller: _pointCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly
          ],
          decoration: _inputDecoration(label: '사용할 포인트', suffix: 'P'),
          onChanged: (value) {
            if (value.isEmpty) {
              setState(() {
                _selectedPointAmount = 0;
              });
            return;
          }

          // 콤마 제거
          final raw = value.replaceAll(',', '');

          // 숫자 변환
          final parsed = int.tryParse(raw) ?? 0;

          // 보유 포인트 초과 방지
          final clamped = _clampPoint(parsed);

          // 콤마 포맷
          final formatted = _formatNumber(clamped);

          // 텍스트 + 커서 갱신
          _pointCtrl.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );

          // 상태 반영
          setState(() {
            _selectedPointAmount = clamped;
          });
        },
      ),

        const SizedBox(height: 8),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _selectedPointAmount = _totalPoints;
                _pointCtrl.text = _totalPoints.toString();
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text('전액 사용 (${_formatNumber(_totalPoints)}P)'),
          ),
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            const Spacer(),
            Text(
              '포인트 보너스: +${(_selectedPointAmount * 0.001).toStringAsFixed(2)}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.gray5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  int _clampPoint(int value) {
    if (value < 0) return 0;
    if (value > _totalPoints) return _totalPoints;
    return value;
  }

  // 쿠폰 사용 UI 전체 수정 (26/01/04_수빈)
  Widget _buildCouponSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ 보유 쿠폰 표시
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '보유 쿠폰',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.gray5,
              ),
            ),
            Text(
              '${_coupons.length}개',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ✅ 쿠폰 없을 때
        if (_coupons.isEmpty)
          const Text(
            '사용 가능한 쿠폰이 없습니다.',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.gray5,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          Container(
            width: double.infinity,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _coupons.map((c) => _couponChip(c)).toList(),
            ),
          ),
      ],
    );
  }

  Widget _couponChip(UserCoupon coupon) {
    final key = coupon.ucNo.toString();
    final selected = _selectedCouponKey == key;

    return ChoiceChip(
      label: Text(
        '${coupon.couponName} (+${coupon.bonusRate}%)',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: selected ? AppColors.white : AppColors.primary,
        ),
      ),
      selected: selected,
      checkmarkColor: AppColors.white,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.white,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected
              ? AppColors.primary
              : AppColors.primary.withOpacity(0.3),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      onSelected: (_) {
        setState(() {
          _selectedCouponKey = selected ? null : key;
        });
      },
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 1. _buildInterestRateInfo 수정 (26/01/04_수빈)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 날짜 포맷 헬퍼
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildInterestRateInfo() {
    final baseRate = widget.request.baseRate ?? 0.0;
    final couponBonus = _getSelectedCouponRate();
    final pointBonus = _selectedPointAmount * 0.001;
    final totalRate = baseRate + couponBonus + pointBonus;

    return Column(
      children: [
        _rateRow('기본 금리', '${baseRate.toStringAsFixed(2)}%'),
        if (couponBonus > 0) ...[
          const SizedBox(height: 10),
          _rateRow(
            '쿠폰 보너스',
            '+${couponBonus.toStringAsFixed(2)}%',
            valueColor: AppColors.primary,
          ),
        ],
        if (pointBonus > 0) ...[
          const SizedBox(height: 10),
          _rateRow(
            '포인트 보너스',
            '+${pointBonus.toStringAsFixed(2)}%',
            valueColor: AppColors.primary,
          ),
        ],
        const SizedBox(height: 14),
        _dashedDivider(),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '최종 적용 금리',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.black,
              ),
            ),
            Text(
              '${totalRate.toStringAsFixed(2)}%',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _rateRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.gray5,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: valueColor ?? AppColors.black,
          ),
        ),
      ],
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 2. _buildExpectedProfit (26/01/04_수빈)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildExpectedProfit() {
    final principal = widget.request.principalAmount ?? 0;
    final term = widget.request.contractTerm ?? 0;

    final baseRate = widget.request.baseRate ?? 0.0;
    final couponBonus = _getSelectedCouponRate();
    final pointBonus = _selectedPointAmount * 0.001;
    final totalRate = baseRate + couponBonus + pointBonus;

    final expectedProfit = _calculateProfit(principal, term, totalRate);
    final maturity = principal + expectedProfit;

    return Column(
      children: [
        _rateRow('가입 금액', '${_formatNumber(principal)}원'),
        const SizedBox(height: 10),
        _rateRow('가입 기간', '$term개월'),
        const SizedBox(height: 10),
        _rateRow('적용 금리', '${totalRate.toStringAsFixed(2)}%'),
        const SizedBox(height: 10),
        _rateRow('예상 이자', '${_formatNumber(expectedProfit)}원',
            valueColor: AppColors.primary),
        const SizedBox(height: 14),
        _dashedDivider(),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '만기 금액',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.black,
              ),
            ),
            Text(
              '${_formatNumber(maturity)}원',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }


  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 3. _buildContractTable 수정 (26/01/04_수빈)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildContractTable() {
    final req = widget.request;
    final today = DateTime.now();

    final baseRate = widget.request.baseRate ?? 0.0;
    final couponBonus = _getSelectedCouponRate();
    final pointBonus = _selectedPointAmount * 0.001;
    final totalRate = baseRate + couponBonus + pointBonus;

    return Table(
      border: TableBorder.all(color: Colors.grey[300]!),
      children: [
        _buildTableRow('상품명', req.productName ?? ''),
        _buildTableRow('신규 금액', '${_formatNumber(req.principalAmount ?? 0)}원'),
        _buildTableRow('계약 기간', '${req.contractTerm ?? 0}개월'),
        _buildTableRow('최초 신규 적용 이율', '연 ${totalRate.toStringAsFixed(2)}%'),
        _buildTableRow('이자 지급 방식', '만기일시지급 단리식'),
        _buildTableRow('과세 구분', '일반과세'),
        _buildTableRow('계약 체결일', '${today.year}.${today.month}.${today.day}'),
      ],
    );
  }

  // 계약서 섹션 추가
  Widget _buildContractSection() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _showContractDialog,

          icon: const Icon(
            Icons.description,
            size: 20,
          ),

          label: const Text(
            '계약서 확인하기',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.primary,
            elevation: 0,

            minimumSize: const Size(double.infinity, 56),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: AppColors.primary.withOpacity(0.25),
              ),
            ),

            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
          ),
        ),
        const SizedBox(height: 12),

        SwitchListTile(
          title: const Text(
            '예금상품계약서 동의',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          subtitle: const Text(
            '계약서 내용을 확인하였으며 동의합니다.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.gray5,
            ),
          ),
          value: _contractAgreed,
          onChanged: (v) => setState(() => _contractAgreed = v),
          activeColor: AppColors.white,
          activeTrackColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 4. 계약서 다이얼로그 수정 (26/01/04_수빈)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  void _showContractDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (dialogContext) {
        bool isChecked = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                '예금상품 계약서',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 계약 정보 테이블
                    _buildContractTable(),
                    const SizedBox(height: 20),

                    // 계약 체결 안내
                    const Text(
                      '■ 예금상품 계약 체결에 관한 사항',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '본인은 위 예금상품의 중요한 사항을 충분히 설명받고 이해하였습니까?',
                      style: TextStyle(fontSize: 13),
                    ),

                    // 체크박스 + 확인 문구
                    Row(
                      children: [
                        const Spacer(),
                        Checkbox(
                          value: isChecked,
                          activeColor: AppColors.primary,
                          onChanged: (value) {
                            setDialogState(() {
                              isChecked = value ?? false;
                            });
                          },
                        ),
                        const Text(
                          '예, 충분히 설명받고 이해하였습니다.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // 중요 내용 요약
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

                    // 회색 안내 박스
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '이 예금 상품 계약서에 명시된 모든 내용을 충분히 읽고 이해하였으며, 이 계약에 동의합니다.',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                            color: AppColors.gray5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 확인 및 동의 버튼
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isChecked
                        ? () {
                      setState(() => _contractAgreed = true);
                      Navigator.pop(dialogContext);
                    }
                        : null,

                    style: ElevatedButton.styleFrom(
                      // 활성
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,

                      // 비활성
                      disabledBackgroundColor: AppColors.gray3,
                      disabledForegroundColor: AppColors.gray5,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),

                    child: const Text(
                      '확인 및 동의',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
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

  // 쿠폰 리스트 비었을 때도 안 터짐 + null 방어
  double _getSelectedCouponRate() {
    if (_selectedCouponKey == null) return 0.0;
    if (_coupons.isEmpty) return 0.0;

    final selected = _coupons
        .where((c) => c.ucNo.toString() == _selectedCouponKey)
        .toList();

    if (selected.isEmpty) return 0.0;
    return selected.first.bonusRate.toDouble();
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
  // 계약서 동의 체크 추가!
  void _goToStep4() {
    if (!_contractAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('예금상품계약서를 확인하고 동의해주세요.')),
      );
      return;
    }

    final baseRate = widget.request.baseRate ?? 0.0;
    final bonusRate = _getSelectedCouponRate();
    final pointBonus = _selectedPointAmount * 0.001;
    final totalRate = baseRate + bonusRate + pointBonus;

    int? selectedCouponUcNo;
    if (_selectedCouponKey != null) {
      final matches =
      _coupons.where((c) => c.ucNo.toString() == _selectedCouponKey).toList();
      selectedCouponUcNo = matches.isNotEmpty ? matches.first.ucNo : null;
    }

    final updatedRequest = widget.request.copyWith(
      selectedCouponId: selectedCouponUcNo,
      usedPoints: _selectedPointAmount,
      pointBonusRate: pointBonus,
      couponBonusRate: bonusRate,
      applyRate: totalRate,
    );

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
  
  // 공통 섹션 카드 추가 (26/01/04_수빈)
  Widget _sectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  // 단계별 Step 표시 추가 (26/01/04_수빈)
  Widget _buildMiniStepIndicator({required int currentStep}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$currentStep / 4',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }

  // 점선 Divider 추가 (26/01/04_수빈)
  Widget _dashedDivider() {
    return LayoutBuilder(
      builder: (_, constraints) {
        return Row(
          children: List.generate(
            (constraints.maxWidth / 6).floor(),
                (index) => Expanded(
              child: Container(
                height: 1,
                color: index.isEven ? AppColors.gray4 : Colors.transparent,
              ),
            ),
          ),
        );
      },
    );
  }

  // 입력창/선택창 공용 UI 추가 (26/01/04_수빈)
  InputDecoration _inputDecoration({
    required String label,
    String? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      suffixText: suffix,
      labelStyle: const TextStyle(
        color: AppColors.gray5,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: AppColors.gray4,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: AppColors.red,
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: AppColors.red,
          width: 2,
        ),
      ),
    );
  }

  // 다음 버튼 추가 (26/01/04_수빈)
  Widget _buildBottomCTA(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: h * 0.09,
          child: ElevatedButton(
            onPressed: _contractAgreed ? _goToStep4 : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,

              disabledBackgroundColor: AppColors.gray3,
              disabledForegroundColor: AppColors.gray5,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              '다음',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}