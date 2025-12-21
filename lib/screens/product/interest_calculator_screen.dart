// lib/screens/product/interest_calculator_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      appBar: AppBar(
        title: const Text('금리 계산기'),
        centerTitle: true,
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상품 유형 선택
            const Text(
              '상품 유형',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTypeButton('예금', '01'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeButton('적금', '02'),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 가입금액 / 월 납입액
            _buildInputField(
              label: _productType == '01' ? '가입 금액' : '월 납입액',
              controller: _principalController,
              hintText: _productType == '01' ? '1,000,000' : '100,000',
              suffix: '원',
            ),

            const SizedBox(height: 24),

            // 연 이율
            _buildInputField(
              label: '연 이율',
              controller: _rateController,
              hintText: '3.5',
              suffix: '%',
            ),

            const SizedBox(height: 24),

            // 가입 기간
            _buildInputField(
              label: '가입 기간',
              controller: _termController,
              hintText: '12',
              suffix: '개월',
            ),

            const SizedBox(height: 32),

            // 계산 버튼
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _calculate,
                    icon: const Icon(Icons.calculate),
                    label: const Text(
                      '계산하기',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A1B9A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('초기화'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 결과
            if (_totalAmount > 0) _buildResultSection(),
          ],
        ),
      ),
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
        backgroundColor: isSelected ? const Color(0xFF6A1B9A) : Colors.white,
        foregroundColor: isSelected ? Colors.white : const Color(0xFF6A1B9A),
        side: BorderSide(
          color: const Color(0xFF6A1B9A),
          width: isSelected ? 2 : 1,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required String suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),  // ✅ 소수점 허용!
          inputFormatters: suffix == '%'
              ? [
            // ✅ 금리는 숫자 + 소수점만 허용
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ]
              : [
            // ✅ 금액/기간은 숫자만 허용
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Colors.black26,  // ✅ 더 연하게!
              fontWeight: FontWeight.normal,
            ),
            suffixText: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
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
        ),
      ],
    );
  }

  Widget _buildResultSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '계산 결과',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
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

          const Divider(color: Colors.white30, height: 32),

          _buildResultRow(
            label: '예상 이자',
            value: _formatNumber(_totalInterest),
            isHighlight: true,
          ),

          const Divider(color: Colors.white30, height: 32),

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
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: Colors.white,
          ),
        ),
        Text(
          '$value원',
          style: TextStyle(
            fontSize: isTotal ? 24 : 18,
            fontWeight: FontWeight.bold,
            color: isHighlight
                ? Colors.yellow
                : (isTotal ? Colors.white : Colors.white),
          ),
        ),
      ],
    );
  }
}