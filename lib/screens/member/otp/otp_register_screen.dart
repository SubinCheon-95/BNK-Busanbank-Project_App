/*
  날짜: 2025/12/29
  내용: otp등록 화면
  작성자: 오서정
  수정: 2025/01/04 - UI 수정 - 작성자: 오서정
*/
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tkbank/screens/member/otp/id_verify_screen.dart';
import 'package:tkbank/screens/member/otp/id_verify_screen.dart';
import 'package:tkbank/screens/member/otp/otp_issue_complete_screen.dart';
import 'package:tkbank/screens/member/otp/otp_pin_register_screen.dart';
import 'package:tkbank/services/member_service.dart';
import 'package:tkbank/theme/app_colors.dart';
import 'package:tkbank/utils/formatters/phone_number_formatter.dart';
import 'package:tkbank/utils/validators.dart';

const Color bnkPrimary = Color(0xFF6A1B9A);
const Color bnkGrayText = Color(0xFF6B7280);

const DEV_PHONE = '010-1111-1111';
const DEV_PHONE_DIGITS = '01011111111';
const bool DEV_ID_BYPASS = true;
String _digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

class OtpRegisterScreen extends StatefulWidget {
  const OtpRegisterScreen({super.key});

  @override
  State<OtpRegisterScreen> createState() => _OtpRegisterScreenState();
}

class _OtpRegisterScreenState extends State<OtpRegisterScreen> {
  bool phoneVerified = false;
  bool idVerified = false;

  // ✅ 휴대폰 인증 UI 펼침 상태
  bool phoneStepExpanded = false;

  // ✅ 휴대폰 인증 상태/입력
  final phoneCtrl = TextEditingController();
  final codeCtrl = TextEditingController();
  final phoneFocus = FocusNode();

  String? phoneError;
  bool codeRequested = false;
  bool codeError = false;

  @override
  void dispose() {
    phoneCtrl.dispose();
    codeCtrl.dispose();
    phoneFocus.dispose();
    super.dispose();
  }

  // ======================
  // Validation
  // ======================
  bool _validatePhoneOnly() {
    final raw = phoneCtrl.text.trim();
    final digits = _digitsOnly(raw);

    // ✅ 개발용 우회: 하이픈 유무 상관없이 통과
    if (digits == DEV_PHONE_DIGITS) {
      setState(() {
        phoneError = null;
        phoneVerified = true;
        codeRequested = false;
        codeError = false;
        phoneStepExpanded = false; // 원하면 닫기
      });
      FocusScope.of(context).unfocus();
      return true;
    }

    // ✅ 실제 검증도 digits 기준으로
    final ok = Validators.isValidHp(raw); // 여기 Validators가 하이픈 포함 허용이면 raw
    // 만약 Validators가 digits만 받는다면 Validators.isValidHp(digits)로 바꿔줘.
    setState(() => phoneError = ok ? null : '휴대폰 번호를 확인해주세요.');
    return ok;
  }

  // ======================
  // 휴대폰 인증
  // ======================
  Future<void> _sendCode() async {
    final ok = _validatePhoneOnly();
    if (!ok) return;

    final digits = _digitsOnly(phoneCtrl.text.trim());

    // ✅ DEV 우회
    if (digits == DEV_PHONE_DIGITS) return;

    await MemberService().sendOtpHpCode(hp: digits);

    setState(() {
      codeRequested = true;
      codeError = false;
    });
  }

  Future<void> _verifyCode(String code) async {
    final hp = _digitsOnly(phoneCtrl.text.trim());

    // ✅ DEV 우회 방어
    if (hp == DEV_PHONE_DIGITS) return;

    final ok = await MemberService().verifyOtpHpCode(
      hp: hp,
      code: code,
    );

    if (ok) {
      setState(() {
        phoneVerified = true;
        codeRequested = false;
        codeError = false;
        phoneStepExpanded = false;
      });
      FocusScope.of(context).unfocus();
    } else {
      setState(() => codeError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canGoNext = phoneVerified && idVerified;

    return Scaffold(
        resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('OTP 등록'),
        backgroundColor: bnkPrimary,
        foregroundColor: Colors.white,
      ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ✅ 위쪽만 스크롤
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'OTP는 이체 및 이체 한도 변경 시 사용하는\n추가 보안 수단입니다.',
                          style: TextStyle(fontSize: 14, color: bnkGrayText),
                        ),
                        const SizedBox(height: 32),

                        _stepTile(
                          title: '휴대폰 본인인증',
                          verified: phoneVerified,
                          onTap: () {
                            setState(() => phoneStepExpanded = !phoneStepExpanded);
                          },
                        ),

                        if (phoneStepExpanded && !phoneVerified) ...[
                          const SizedBox(height: 12),
                          _phoneVerifyPanel(),
                        ],

                        const SizedBox(height: 12),

                        _stepTile(
                          title: '신분증 인증',
                          verified: idVerified,
                          onTap: phoneVerified
                              ? () async {
                            final hpDigits = _digitsOnly(phoneCtrl.text.trim());

                            // ✅ DEV 우회: 개발용 번호일 때 신분증 인증 완료 처리
                            if (DEV_ID_BYPASS && hpDigits == DEV_PHONE_DIGITS) {
                              setState(() => idVerified = true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('DEV: 신분증 인증을 완료 처리했어요.')),
                              );
                              return;
                            }

                            // ✅ 정상 플로우
                            final ok = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(builder: (_) => const IdVerifyScreen()),
                            );
                            if (ok == true) setState(() => idVerified = true);
                          }
                              : null,
                        ),


                        // ✅ 스크롤 영역 끝에 약간 여백(버튼과 겹침 방지)
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: (phoneVerified && idVerified)
                ? () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const OtpPinRegisterScreen(),
                ),
              );

              if (result == true && mounted) {
                final ok = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OtpIssueCompleteScreen(
                      oneLimit: 100000000,
                      dayLimit: 500000000,
                    ),
                  ),
                );

                if (ok == true && mounted) {
                  Navigator.pop(context, true); // ✅ 상위로 성공 전달
                }
              }
            }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor:
              AppColors.primary.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              '다음',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ======================
  // 휴대폰 인증 패널 UI
  // ======================
  Widget _phoneVerifyPanel() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('휴대폰 번호', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _input(
                  phoneCtrl,
                  focus: phoneFocus,
                  enabled: !phoneVerified,
                  keyboard: TextInputType.phone,
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(13),
                    PhoneNumberFormatter(),
                  ],
                  isError: phoneError != null,
                  hint: '010-1234-5678',
                  onChanged: (_) {
                    final digits = _digitsOnly(phoneCtrl.text);
                    if (digits == DEV_PHONE_DIGITS && !phoneVerified) {
                      _validatePhoneOnly(); // setState 포함
                    } else {
                      if (codeRequested || codeError) {
                        setState(() {
                          codeRequested = false;
                          codeError = false;
                        });
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: phoneVerified ? null : _sendCode,
                  child: Text(phoneVerified ? '완료' : '인증'),
                ),
              ),
            ],
          ),
          if (phoneError != null) ...[
            const SizedBox(height: 6),
            Text(phoneError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],

          if (codeRequested && !phoneVerified) ...[
            const SizedBox(height: 12),
            const Text('인증번호', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            _input(
              codeCtrl,
              maxLength: 4,
              keyboard: TextInputType.number,
              formatters: [FilteringTextInputFormatter.digitsOnly],
              isError: codeError,
              hint: '4자리',
              onChanged: (v) {
                if (v.length == 4) _verifyCode(v);
              },
            ),
            if (codeError)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('인증번호가 올바르지 않습니다.', style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
          ],
        ],
      ),
    );
  }

  // ======================
  // 기존 타일 UI
  // ======================
  Widget _stepTile({
    required String title,
    required bool verified,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: verified ? bnkPrimary : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              verified ? Icons.check_circle : Icons.radio_button_unchecked,
              color: verified ? bnkPrimary : Colors.grey,
            ),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _input(
      TextEditingController ctrl, {
        FocusNode? focus,
        bool enabled = true,
        TextInputType keyboard = TextInputType.text,
        int? maxLength,
        List<TextInputFormatter>? formatters,
        ValueChanged<String>? onChanged,
        bool isError = false,
        String? hint,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? Colors.red : Colors.grey.shade200,
          width: 1.2,
        ),
      ),
      child: TextField(
        controller: ctrl,
        focusNode: focus,
        enabled: enabled,
        keyboardType: keyboard,
        maxLength: maxLength,
        inputFormatters: formatters,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          counterText: '',
        ),
      ),
    );
  }
}
