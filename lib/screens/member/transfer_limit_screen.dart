import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:tkbank/screens/member/account_setup_screen.dart';
import 'package:tkbank/services/transfer_limit_service.dart';
import 'package:tkbank/services/otp_pin_storage_service.dart';
import 'package:tkbank/utils/formatters/money_formatter.dart';

const Color bnkPrimary = Color(0xFF6A1B9A);

class TransferLimitScreen extends StatefulWidget {
  const TransferLimitScreen({super.key});

  @override
  State<TransferLimitScreen> createState() => _TransferLimitScreenState();
}

class _TransferLimitScreenState extends State<TransferLimitScreen> {
  // 최소
  static const int _minDailyLimit = 10000;     // 1만원
  static const int _minOnceLimit  = 10000;

  // 최대
  static const int _maxDailyLimit = 500000000; // 5억원
  static const int _maxOnceLimit  = 100000000; // 1억원

  String? dailyLimitError;
  String? onceLimitError;

  final dailyLimitFocus = FocusNode();
  final onceLimitFocus = FocusNode();

  final _onceController = TextEditingController();
  final _dailyController = TextEditingController();

  final _service = TransferLimitService();
  final _otpPinService = OtpPinStorageService();

  int? currentOnceLimit;
  int? currentDailyLimit;

  bool isLoading = true;

  final formatter = NumberFormat('#,###');

  String? _generatedOtp;

  @override
  void initState() {
    super.initState();
    _loadTransferLimit();
  }

  Future<void> _loadTransferLimit() async {
    try {
      final data = await _service.getTransferLimit();
      setState(() {
        currentOnceLimit = data['onceLimit'];
        currentDailyLimit = data['dailyLimit'];
        isLoading = false;
      });
    } catch (e) {
      _showSnackBar('이체한도 조회에 실패했습니다.');
    }
  }

  @override
  void dispose() {
    _onceController.dispose();
    _dailyController.dispose();
    dailyLimitFocus.dispose();
    onceLimitFocus.dispose();
    super.dispose();
  }

  // ================== 변경 버튼 ==================

  Future<void> _onSubmit() async {
    final once =
    int.tryParse(_onceController.text.replaceAll(',', ''));
    final daily =
    int.tryParse(_dailyController.text.replaceAll(',', ''));

    if (daily == null || daily < _minDailyLimit) {
      setState(() => dailyLimitError = '1일 이체한도를 확인해주세요.');
      dailyLimitFocus.requestFocus();
      return;
    }

    if (once == null || once < _minOnceLimit) {
      setState(() => onceLimitError = '1회 이체한도를 확인해주세요.');
      onceLimitFocus.requestFocus();
      return;
    }

    if (_onceController.text.isEmpty || _dailyController.text.isEmpty) {
      _showSnackBar('변경할 한도를 입력해주세요.');
      return;
    }

    final onceLimit = int.parse(_onceController.text.replaceAll(',', ''));
    final dailyLimit = int.parse(_dailyController.text.replaceAll(',', ''));


    // 🔐 STEP 1. OTP PIN 인증
    final hasPin = await _otpPinService.hasOtpPin();
    if (!hasPin) {
      _showSnackBar('OTP 비밀번호가 등록되어 있지 않습니다.');
      return;
    }

    final pinVerified = await _showOtpPinDialog();
    if (!pinVerified) return;

    // 🔐 STEP 2. OTP 인증 (임시 성공 처리)
    final generated = await _showOtpGenerateDialog();
    if (!generated) return;

    final otpVerified = await _showOtpDialog();
    if (!otpVerified) return;


    // ✅ STEP 3. 서버에 이체한도 변경 요청
    try {
      await _service.updateTransferLimit(onceLimit, dailyLimit);
      _showSnackBar('이체한도가 변경되었습니다.');
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('이체한도 변경에 실패했습니다.');
    }
  }

  // ================== UI ==================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이체한도 변경'),
        centerTitle: true,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: bnkPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isLoading ? null : _onSubmit,
              child: const Text(
                '변경하기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('현재 이체한도'),
            _limitInfo('1회 이체 한도', currentOnceLimit!),
            _limitInfo('1일 이체 한도', currentDailyLimit!),

            const SizedBox(height: 32),

            _sectionTitle('변경할 이체한도'),

            _limitInputRow(
              label: '1일 이체 한도',
              controller: _dailyController,
              focusNode: dailyLimitFocus,
              minLimit: _minDailyLimit,
              maxLimit: _maxDailyLimit,
              error: dailyLimitError,
              onMax: () {
                _dailyController.text = formatter.format(_maxDailyLimit);
                setState(() => dailyLimitError = null);
              },
              onChanged: (value) {
                setState(() {
                  if (value == null || value < _minDailyLimit) {
                    dailyLimitError = '최소 1만원 이상 입력해주세요.';
                  } else {
                    dailyLimitError = null;
                  }
                });
              },
            ),

            _limitInputRow(
              label: '1회 이체 한도',
              controller: _onceController,
              focusNode: onceLimitFocus,
              minLimit: _minOnceLimit,
              maxLimit: _maxOnceLimit,
              error: onceLimitError,
              onMax: () {
                _onceController.text = formatter.format(_maxOnceLimit);
                setState(() => onceLimitError = null);
              },
              onChanged: (value) {
                setState(() {
                  if (value == null || value < _minOnceLimit) {
                    onceLimitError = '최소 1만원 이상 입력해주세요.';
                  } else {
                    onceLimitError = null;
                  }
                });
              },
            ),

          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _limitInfo(String label, int value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '${formatter.format(value)}원',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }


  // ================== 인증 ==================

  Future<bool> _showOtpPinDialog() async {
    final controller = TextEditingController();

    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('OTP 비밀번호 입력'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          decoration: const InputDecoration(hintText: 'OTP 비밀번호 6자리'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final verified =
              await _otpPinService.verifyOtpPin(controller.text);
              Navigator.pop(context, verified);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<bool> _showOtpDialog() async {
    final controllers =
    List.generate(6, (_) => TextEditingController());
    final focusNodes =
    List.generate(6, (_) => FocusNode());

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('OTP 인증'),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            return SizedBox(
              width: 40,
              child: TextField(
                controller: controllers[i],
                focusNode: focusNodes[i],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  counterText: '',
                ),
                onChanged: (v) {
                  if (v.isNotEmpty && i < 5) {
                    focusNodes[i + 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final otp = controllers.map((c) => c.text).join();

              if (otp.length != 6) {
                _showSnackBar('OTP 6자리를 입력해주세요.');
                return;
              }

              if (otp != _generatedOtp) {
                _showSnackBar('OTP가 올바르지 않습니다.');
                return;
              }

              Navigator.pop(context, true);
            },
            child: const Text('인증'),
          ),
        ],
      ),
    ) ?? false;
  }


  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }


  Widget _limitInputRow({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required int minLimit,
    required int maxLimit,
    required VoidCallback onMax,
    String? error,
    required ValueChanged<int?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              Expanded(
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: error != null ? Colors.red : Colors.transparent,
                      width: 1.3,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            MaxValueFormatter(maxLimit),
                            MoneyFormatter(),
                          ],
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '금액 입력',
                          ),
                          onChanged: (text) {
                            final value =
                            int.tryParse(text.replaceAll(',', ''));
                            onChanged(value);
                          },
                        ),
                      ),
                      const Text('원'),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              _maxButton(onMax),
            ],
          ),

          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                error,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ),

          const SizedBox(height: 6),
          Text(
            '※ 최소 ${(minLimit ~/ 10000)}만원 ~ 최대 ${(maxLimit ~/ 10000)}만원',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _maxButton(VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),
        child: const Text(
          '최대',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<bool> _showOtpGenerateDialog() async {
    _generatedOtp = (100000 + DateTime.now().millisecondsSinceEpoch % 900000)
        .toString();

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        int remain = 30;
        Timer? timer;

        return StatefulBuilder(
          builder: (context, setState) {
            timer ??= Timer.periodic(
              const Duration(seconds: 1),
                  (t) {
                if (remain == 0) {
                  t.cancel();
                  Navigator.pop(context, false);
                } else {
                  setState(() => remain--);
                }
              },
            );

            return AlertDialog(
              title: const Text('OTP 생성'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '아래 OTP를 입력해주세요',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // 🔥 OTP 표시 (데모용)
                  Text(
                    _generatedOtp!,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text(
                    '유효시간 $remain초',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    timer?.cancel();
                    Navigator.pop(context, true);
                  },
                  child: const Text('OTP 입력'),
                ),
              ],
            );
          },
        );
      },
    ) ?? false;
  }



}

