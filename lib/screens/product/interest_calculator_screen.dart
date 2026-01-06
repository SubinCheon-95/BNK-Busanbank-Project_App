// lib/screens/product/interest_calculator_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tkbank/theme/app_colors.dart';

/// 💰 금리계산기 화면
class InterestCalculatorScreen extends StatefulWidget {
  const InterestCalculatorScreen({super.key});

  @override
  State<InterestCalculatorScreen> createState() => _InterestCalculatorScreenState();
}

class _InterestCalculatorScreenState extends State<InterestCalculatorScreen> {
  final _principalController = TextEditingController();
  final _rateController = TextEditingController();
  final _termController = TextEditingController();

  String _productType = '01'; // 01: 예금, 02: 적금
  double _totalInterest = 0.0;
  double _totalAmount = 0.0;

  @override
  void dispose() {
    _principalController.dispose();
    _rateController.dispose();
    _termController.dispose();
    super.dispose();
  }

  void _calculate() {
    final principal = double.tryParse(_principalController.text.replaceAll(',', '')) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;
    final term = int.tryParse(_termController.text) ?? 0;

    if (principal == 0 || rate == 0 || term == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 항목을 입력해주세요.')),
      );
      return;
    }

    double interest = 0;

    if (_productType == '01') {
      // 예금: 원금 × 금리 × (기간/12)
      interest = principal * (rate / 100) * (term / 12);
    } else {
      // 적금: 월 납입액 × 기간 × (기간+1) / 24 × 금리
      interest = principal * term * (term + 1) / 24 * (rate / 100);
    }

    setState(() {
      _totalInterest = interest;
      _totalAmount = principal * (_productType == '01' ? 1 : term) + interest;
    });
  }

  void _reset() {
    setState(() {
      _principalController.clear();
      _rateController.clear();
      _termController.clear();
      _totalInterest = 0.0;
      _totalAmount = 0.0;
    });
  }

  String _formatNumber(double number) {
    return number.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.gray1,
      // backgroundColor: Color.alphaBlend(
        // AppColors.white.withOpacity(0.9),
        // AppColors.gray1,
      // ),

      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),

              // 타이틀
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Semantics(
                  label: '금리계산기',
                  child: Image.asset(
                    'assets/images/title_calculator.png',
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // 본문 (26/01/04_수빈)
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    // 타이틀
                    _sectionCard(
                      title: const Text(
                        '상품 유형',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: _buildTypeButton('예금', '01')),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTypeButton('적금', '02')),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    _sectionCard(
                      title: Text(
                        _productType == '01' ? '가입 금액' : '월 납입액',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: _buildInputField(
                        label: '',
                        controller: _principalController,
                        hintText: _productType == '01' ? '직접 입력(원)' : '직접 입력(원)',
                        suffix: '원',
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 연 이율
                    _sectionCard(
                      title: const Text(
                        '연 이율',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: _buildInputField(
                        label: '',
                        controller: _rateController,
                        hintText: '연 이율(%)',
                        suffix: '%',
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 가입 기간
                    _sectionCard(
                      title: const Text(
                        '가입 기간',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: _buildInputField(
                        label: '',
                        controller: _termController,
                        hintText: '가입 기간(개월)',
                        suffix: '개월',
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 결과
                    if (_totalAmount > 0) _buildResultSection(),
                  ],
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
              color: AppColors.gray4,
            ),
          ),
        ],
      ),

      // 하단 CTA
      bottomNavigationBar: _buildBottomCTA(context),
    );
  }

  Widget _buildTypeButton(String label, String type) {
    final isSelected = _productType == type;
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _productType = type;
          _reset();
        });
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.blue : AppColors.white,
        foregroundColor: isSelected ? AppColors.white : AppColors.blue,
        side: BorderSide(
          color: AppColors.blue,
          width: isSelected ? 2 : 1,
        ),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 18,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  // 입력창 UI 수정 (26/01/04_수빈)
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required String suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true), // 소수점 허용
      inputFormatters: suffix == '%'
          ? [
        // 금리는 숫자 + 소수점만 허용
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ]
          : [
        // 금액/기간은 숫자만 허용
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: _inputDecoration(
        label: hintText.isNotEmpty ? hintText : label,
        suffix: suffix,
      ),
      onChanged: (value) {
        // 천 단위 콤마 자동 추가 (금액만)
        if (suffix == '원' && value.isNotEmpty) {
          final number = int.tryParse(value.replaceAll(',', ''));
          if (number != null) {
            final formatted = _formatNumber(number.toDouble());
            controller.value = TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
            );
          }
        }
      },
    );
  }

  // 결과창 UI 수정 (26/01/04_수빈)
  Widget _buildResultSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.yellow, AppColors.deepRed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.white,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          const Text(
            '계산 결과',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 20),

          _buildResultRow(
            label: _productType == '01' ? '예치 금액' : '총 납입액',
            value: _formatNumber(
              double.parse(_principalController.text.replaceAll(',', '')) *
                  (_productType == '01' ? 1 : int.parse(_termController.text)),
            ),
          ),

          const SizedBox(height: 20),
          _dashedDivider(),
          const SizedBox(height: 20),

          _buildResultRow(
            label: '예상 이자',
            value: _formatNumber(_totalInterest),
            isHighlight: true,
          ),

          const SizedBox(height: 20),
          _dashedDivider(),
          const SizedBox(height: 20),

          _buildResultRow(
            label: '만기 금액',
            value: _formatNumber(_totalAmount),
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow({
    required String label,
    required String value,
    bool isHighlight = false,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: Colors.white,
          ),
        ),
        Text(
          '$value원',
          style: TextStyle(
            fontSize: isTotal ? 24 : 18,
            fontWeight: FontWeight.w800,
            color: isHighlight
                ? AppColors.yellowGreen
                : (isTotal ? AppColors.white : AppColors.white),
          ),
        ),
      ],
    );
  }

  // 공통 섹션 카드 추가 (26/01/04_수빈)
  Widget _sectionCard({
    required Widget title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 15),
          child,
        ],
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
                color: index.isEven ? AppColors.white : Colors.transparent,
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
        color: AppColors.blue,
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
          color: AppColors.blue,
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

  // 계산하기/초기화 버튼 추가 (26/01/04_수빈)
  Widget _buildBottomCTA(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final btnHeight = h * 0.09;

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
          height: btnHeight,
          child: Row(
            children: [
              // 왼쪽(보조): 초기화
              Expanded(
                child: OutlinedButton(
                  onPressed: _reset,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gray4,
                    side: BorderSide(color: AppColors.gray4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    minimumSize: Size(double.infinity, btnHeight),
                  ),
                  child: const Text(
                    '초기화',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 오른쪽(메인): 계산하기
              Expanded(
                child: ElevatedButton(
                  onPressed: _calculate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.gray4.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    minimumSize: Size(double.infinity, btnHeight),
                  ),
                  child: const Text(
                    '계산하기',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}