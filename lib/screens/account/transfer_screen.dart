// 2025/12/29 - 계좌 이체 화면 - 작성자: 진원
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/account_service.dart';
import 'package:intl/intl.dart';

class TransferScreen extends StatefulWidget {
  final String fromAccountNo;

  const TransferScreen({super.key, required this.fromAccountNo});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final AccountService _accountService = AccountService();
  final NumberFormat _currencyFormat = NumberFormat('#,###');
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _toAccountController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  int? _currentBalance;
  bool _isLoading = false;
  bool _isLoadingBalance = true;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  @override
  void dispose() {
    _toAccountController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    try {
      setState(() => _isLoadingBalance = true);

      final result = await _accountService.getBalance(widget.fromAccountNo);

      if (mounted) {
        setState(() {
          _currentBalance = result['balance'];
          _isLoadingBalance = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBalance = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('잔액 조회 실패: $e')),
        );
      }
    }
  }

  Future<void> _performTransfer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userNo;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다')),
      );
      return;
    }

    // 금액 파싱
    final amountStr = _amountController.text.replaceAll(',', '');
    final amount = int.tryParse(amountStr);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 금액을 입력해주세요')),
      );
      return;
    }

    // 잔액 확인
    if (_currentBalance != null && amount > _currentBalance!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('잔액이 부족합니다')),
      );
      return;
    }

    // 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이체 확인'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('받는 계좌: ${_toAccountController.text}'),
            const SizedBox(height: 8),
            Text('이체 금액: ${_currencyFormat.format(amount)}원'),
            if (_descriptionController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('메모: ${_descriptionController.text}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
            ),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isLoading = true);

      final result = await _accountService.transferMoney(
        userId: userId,
        fromAccountNo: widget.fromAccountNo,
        toAccountNo: _toAccountController.text,
        amount: amount,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (result['success'] == true) {
          // 성공 다이얼로그
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  const SizedBox(width: 8),
                  const Text('이체 완료'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('이체 금액: ${_currencyFormat.format(amount)}원'),
                  const SizedBox(height: 8),
                  Text(
                      '남은 잔액: ${_currencyFormat.format(result['balanceAfter'])}원'),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // 다이얼로그 닫기
                    Navigator.pop(context, true); // 이체 화면 닫기
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? '이체 실패')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이체 실패: $e')),
        );
      }
    }
  }

  // 금액 입력시 천단위 콤마 자동 추가
  void _formatAmount(String value) {
    final numStr = value.replaceAll(',', '');
    if (numStr.isEmpty) return;

    final num = int.tryParse(numStr);
    if (num != null) {
      final formatted = _currencyFormat.format(num);
      _amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('계좌 이체'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: _isLoadingBalance
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 출금 계좌 정보
                        _buildFromAccountCard(),
                        const SizedBox(height: 24),

                        // 받는 계좌번호 입력
                        _buildTextField(
                          controller: _toAccountController,
                          label: '받는 계좌번호',
                          hint: '계좌번호를 입력하세요',
                          keyboardType: TextInputType.text,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '계좌번호를 입력해주세요';
                            }
                            if (value == widget.fromAccountNo) {
                              return '같은 계좌로는 이체할 수 없습니다';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // 이체 금액 입력
                        _buildTextField(
                          controller: _amountController,
                          label: '이체 금액',
                          hint: '금액을 입력하세요',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: _formatAmount,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '금액을 입력해주세요';
                            }
                            final amount =
                                int.tryParse(value.replaceAll(',', ''));
                            if (amount == null || amount <= 0) {
                              return '올바른 금액을 입력해주세요';
                            }
                            if (_currentBalance != null &&
                                amount > _currentBalance!) {
                              return '잔액이 부족합니다';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // 메모 입력
                        _buildTextField(
                          controller: _descriptionController,
                          label: '메모 (선택사항)',
                          hint: '이체 메모를 입력하세요',
                          maxLines: 2,
                        ),
                        const SizedBox(height: 24),

                        // 이체 버튼
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _performTransfer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text(
                                    '이체하기',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 안내사항
                        _buildInfoBox(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFromAccountCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '출금 계좌',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.fromAccountNo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '잔액: ${_currencyFormat.format(_currentBalance ?? 0)}원',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF2196F3),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          validator: validator,
          maxLines: maxLines,
        ),
      ],
    );
  }

  Widget _buildInfoBox() {
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
            children: [
              Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                '안내사항',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• 이체 금액은 본인 계좌의 잔액 내에서만 가능합니다.\n'
            '• 잘못된 계좌로 이체한 경우 고객센터로 문의하세요.\n'
            '• 이체는 즉시 처리되며, 취소가 불가능합니다.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
