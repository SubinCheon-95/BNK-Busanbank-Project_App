/*
  날짜: 2025/12/29
  내용: 이체한도 변경 화면
  작성자: 오서정
*/
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:tkbank/screens/member/register/account_setup_screen.dart';

import 'package:tkbank/services/transfer_limit_service.dart';
import 'package:tkbank/services/otp_code_service.dart';
import 'package:tkbank/services/otp_pin_storage_service.dart';

import 'package:tkbank/services/biometric_auth_service.dart';
import 'package:tkbank/services/biometric_storage_service.dart';
import 'package:tkbank/services/pin_storage_service.dart';

import 'package:tkbank/utils/formatters/money_formatter.dart';

import 'package:tkbank/screens/member/otp/otp_manage_screen.dart';
import 'package:tkbank/screens/member/otp/otp_issue_intro_screen.dart';

import 'package:tkbank/widgets/otp_input_sheet.dart';
import 'package:tkbank/widgets/pin_dots.dart';
import 'package:tkbank/widgets/pin_keypad_panel.dart';

const Color bnkPrimary = Color(0xFF6A1B9A);

class TransferLimitScreen extends StatefulWidget {
  const TransferLimitScreen({super.key});

  @override
  State<TransferLimitScreen> createState() => _TransferLimitScreenState();
}

class _TransferLimitScreenState extends State<TransferLimitScreen> {
  // 최소
  static const int _minDailyLimit = 10000;
  static const int _minOnceLimit = 10000;

  // 최대
  static const int _maxDailyLimit = 500000000; // 5억원
  static const int _maxOnceLimit = 100000000; // 1억원

  // OTP 없을 때 기본 한도 (요구사항)
  static const int _defaultOnceNoOtp = 5000000; // 500만원
  static const int _defaultDailyNoOtp = 5000000;

  // 정책 기준(500만원)
  static const int _threshold = 5000000;

  String? dailyLimitError;
  String? onceLimitError;

  final dailyLimitFocus = FocusNode();
  final onceLimitFocus = FocusNode();

  final _onceController = TextEditingController();
  final _dailyController = TextEditingController();

  final _service = TransferLimitService();
  final _otpCodeService = OtpCodeService();
  final _otpPinStore = OtpPinStorageService();

  int? currentOnceLimit;
  int? currentDailyLimit;

  bool isLoading = true;
  bool hasDigitalOtp = false;

  final formatter = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => isLoading = true);

    try {
      // 1) 디지털OTP 등록 여부(핀 존재 여부로 판단) -> 정책/안내용
      final hasOtp = await _otpPinStore.hasOtpPin();

      // 2) 현재 이체한도는 "항상 서버에서 조회"
      final data = await _service.getTransferLimit();

      setState(() {
        hasDigitalOtp = hasOtp;
        currentOnceLimit = data['onceLimit'];
        currentDailyLimit = data['dailyLimit'];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
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
    final once = int.tryParse(_onceController.text.replaceAll(',', ''));
    final daily = int.tryParse(_dailyController.text.replaceAll(',', ''));

    if (_dailyController.text.isEmpty || _onceController.text.isEmpty) {
      _showSnackBar('변경할 한도를 입력해주세요.');
      return;
    }

    if (daily == null || daily < _minDailyLimit) {
      setState(() => dailyLimitError = '1일 이체한도를 확인해주세요.');
      dailyLimitFocus.requestFocus();
      return;
    } else {
      setState(() => dailyLimitError = null);
    }

    if (once == null || once < _minOnceLimit) {
      setState(() => onceLimitError = '1회 이체한도를 확인해주세요.');
      onceLimitFocus.requestFocus();
      return;
    } else {
      setState(() => onceLimitError = null);
    }

    final onceLimit = int.parse(_onceController.text.replaceAll(',', ''));
    final dailyLimit = int.parse(_dailyController.text.replaceAll(',', ''));

    // ✅ 인증 정책 적용
    final verified = await _verifyByPolicy(
      newOnce: onceLimit,
      newDaily: dailyLimit,
    );
    if (!verified) return;

    // ✅ 서버 요청
    try {
      await _service.updateTransferLimit(onceLimit, dailyLimit);
      _showSnackBar('이체한도가 변경되었습니다.');
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('이체한도 변경에 실패했습니다.');
    }
  }

  // ================== 인증 정책 ==================
  Future<bool> _verifyByPolicy({
    required int newOnce,
    required int newDaily,
  }) async {
    final curOnce = currentOnceLimit ?? 0;
    final curDaily = currentDailyLimit ?? 0;

    final isIncrease = newOnce > curOnce || newDaily > curDaily;
    final needsOtp = isIncrease; // 증액이면 무조건 OTP

    if (needsOtp) {
      // OTP 등록 자체가 없으면 등록 유도
      if (!hasDigitalOtp) {
        final go = await _showConfirmDialog(
          title: '디지털OTP가 필요합니다',
          message: '이체한도를 증액하려면 보안을 위해 디지털OTP 인증이 필요합니다.\n디지털OTP 등록 화면으로 이동할까요?',
          okText: '등록하기',
          cancelText: '취소',
        );
        if (go != true) return false;

        if (!mounted) return false;
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const OtpIssueIntroScreen()),
        );
        if (result == true && mounted) await _init();
        return false;
      }

      // OTP 생성되어 있어야 입력 가능
      if (!_otpCodeService.hasValidOtp) {
        final go = await _showConfirmDialog(
          title: 'OTP 인증번호가 필요합니다',
          message: '인증센터에서 OTP 인증번호를 생성한 뒤 입력해주세요.\n인증센터로 이동할까요?',
          okText: '이동',
          cancelText: '취소',
        );
        if (go != true) return false;

        if (!mounted) return false;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OtpManageScreen()),
        );
        return false;
      }

      // OTP 입력/검증
      return await showOtpInputSheet(context);
    }

    // ✅ 여기부터는: 감액 or 500만원 이하 증액 => 생체/간편
    final bioEnabled = await BiometricStorageService().isEnabled();
    final canBio = await BiometricAuthService().canUseBiometrics();

    if (bioEnabled && canBio) {
      final ok = await BiometricAuthService().authenticate();
      if (ok) return true;
      // 생체 실패하면 간편으로 fallback
    }

    final pinStore = PinStorageService();
    final hasPin = await pinStore.hasPin();

    if (hasPin) {
      final pinOk = await showSimplePinVerifySheet(
        context,
        verify: (input) => pinStore.verifyPin(input),
        title: '간편 비밀번호 입력',
        subtitle: '이체한도 변경을 위해\n간편 비밀번호를 입력해주세요.',
      );
      return pinOk;
    }

    // ✅ 둘 다 없으면: 인증센터로 유도(로그인 비번까지는 생략)
    final go = await _showConfirmDialog(
      title: '추가 인증이 필요합니다',
      message: '이체한도 변경을 위해 생체 인증 또는 간편 비밀번호 등록이 필요합니다.\n인증센터로 이동할까요?',
      okText: '이동',
      cancelText: '취소',
    );
    if (go != true) return false;

    // 네 프로젝트 구조상 인증센터 screen으로 이동시키고 싶으면 여기서 push하면 됨.
    // 지금 파일엔 인증센터 import가 없어서 일단 false 반환만.
    // TODO: SecurityCenterScreen import 후 이동 처리
    _showSnackBar('인증센터에서 생체/간편 비밀번호를 등록해주세요.');
    return false;
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    String okText = '확인',
    String cancelText = '취소',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(cancelText)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: bnkPrimary),
            onPressed: () => Navigator.pop(context, true),
            child: Text(okText),
          ),
        ],
      ),
    );
  }

  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    final onceText = formatter.format(currentOnceLimit ?? 0);
    final dailyText = formatter.format(currentDailyLimit ?? 0);

    final maxDailyByPolicy = hasDigitalOtp ? _maxDailyLimit : _threshold; // 5억 or 500만
    final maxOnceByPolicy  = hasDigitalOtp ? _maxOnceLimit  : _threshold; // 1억 or 500만


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
                foregroundColor: Colors.white,
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
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('현재 보안매체'),
          _card(
            children: [
              _kvRow('보안등급', hasDigitalOtp ? '1 등급' : '2등급'),
              _divider(),
              _kvRow('보안매체', hasDigitalOtp ? '디지털OTP' : '없음'),
            ],
          ),
          const SizedBox(height: 18),

          _sectionTitle('현재 이체한도'),
          _card(
              children: [
                _kvRow(
                  '1일 이체한도',
                  '$dailyText 원 ${hasDigitalOtp ? '(최대 5억원)' : '(최대 500만원)'}',
                ),
                _divider(),
                _kvRow(
                  '1회 이체한도',
                  '$onceText 원 ${hasDigitalOtp ? '(최대 1억원)' : '(최대 500만원)'}',
                ),
              ],
          ),

          if (!hasDigitalOtp) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: bnkPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OtpIssueIntroScreen(),
                    ),
                  );
                  if (result == true && mounted) {
                    await _init();
                  }
                },
                child: const Text(
                  '디지털OTP 등록하기',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '디지털OTP를 신청하고, 최대 이체한도를 1회 1억원 / 1일 5억원까지 설정합니다.',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],

          const SizedBox(height: 28),
          _sectionTitle('변경할 이체한도'),

          _limitInputRow(
            label: '1일 이체 한도',
            controller: _dailyController,
            focusNode: dailyLimitFocus,
            minLimit: _minDailyLimit,
            maxLimit: maxDailyByPolicy,
            error: dailyLimitError,
            onMax: () {
              _dailyController.text = formatter.format(maxDailyByPolicy);
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
            maxLimit: maxOnceByPolicy,
            error: onceLimitError,
            onMax: () {
              _onceController.text = formatter.format(maxOnceByPolicy);
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
    );
  }

  // ---------- UI Helpers ----------
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(children: children),
    );
  }

  Widget _kvRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            v,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, color: Colors.grey.shade300);

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
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
                            setState(() {});
                            final value = int.tryParse(text.replaceAll(',', ''));
                            onChanged(value);

                            // ✅ 입력이 지워졌을 때 에러도 초기화하고 싶으면 여기서 처리 가능
                            if (text.isEmpty) {
                              setState(() {
                                if (label.contains('1일')) {
                                  dailyLimitError = null;
                                } else {
                                  onceLimitError = null;
                                }
                              });
                            }
                          },
                        ),
                      ),

                      // ✅ "원" + X 버튼 영역
                      Row(
                        children: [
                          const Text('원'),

                          // ✅ 입력값 있을 때만 X 보여주기
                          if (controller.text.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  controller.clear();

                                  // 값이 사라졌으니 콜백도 null로 날려주기
                                  onChanged(null);

                                  // 에러 처리(원하는 스타일로)
                                  if (label.contains('1일')) {
                                    dailyLimitError = '금액을 입력해주세요.';
                                  } else {
                                    onceLimitError = '금액을 입력해주세요.';
                                  }
                                });
                              },
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade400,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
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
            '※ 최소 ${formatLimitLabel(minLimit)} ~ 최대 ${formatLimitLabel(maxLimit)}',
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
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Text(
          '최대',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// =========================
/// 간편비밀번호 입력 BottomSheet
/// (PinDots / PinKeypadPanel 재사용)
/// =========================
Future<bool> showSimplePinVerifySheet(
    BuildContext context, {
      required Future<bool> Function(String pin) verify,
      String title = '간편 비밀번호 입력',
      String subtitle = '인증을 위해\n간편 비밀번호를 입력해주세요.',
    }) async {
  return await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SimplePinVerifySheet(
      verify: verify,
      title: title,
      subtitle: subtitle,
    ),
  ) ??
      false;
}

class _SimplePinVerifySheet extends StatefulWidget {
  final Future<bool> Function(String pin) verify;
  final String title;
  final String subtitle;

  const _SimplePinVerifySheet({
    required this.verify,
    required this.title,
    required this.subtitle,
  });

  @override
  State<_SimplePinVerifySheet> createState() => _SimplePinVerifySheetState();
}

class _SimplePinVerifySheetState extends State<_SimplePinVerifySheet> {
  String _pin = '';
  String? _error;
  bool _loading = false;

  void _onNumber(String v) async {
    if (_loading) return;
    if (_pin.length >= 6) return;

    setState(() {
      _pin += v;
      _error = null;
    });

    if (_pin.length == 6) {
      setState(() => _loading = true);
      final ok = await widget.verify(_pin);
      if (!mounted) return;

      if (ok) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _error = '비밀번호가 일치하지 않습니다.';
          _pin = '';
          _loading = false;
        });
      }
    }
  }

  void _onDelete() {
    if (_loading) return;
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Text(
              widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              widget.subtitle,
              style: TextStyle(color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            PinDots(length: _pin.length),

            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],

            const SizedBox(height: 14),

            PinKeypadPanel(
              onNumber: _onNumber,
              onDelete: _onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
String formatLimitLabel(int amount) {
  if (amount >= 100000000) {
    final eok = amount ~/ 100000000;
    return '$eok억원';
  } else {
    final man = amount ~/ 10000;
    return '${man}만원';
  }
}