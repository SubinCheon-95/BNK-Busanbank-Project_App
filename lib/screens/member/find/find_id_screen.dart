/*
  날짜 : 2025/12/18
  내용 : 아이디 찾기 (휴대폰 인증)
  작성자 : 오서정
*/
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tkbank/screens/member/find/find_id_result_screen.dart';
import 'package:tkbank/services/member_service.dart';
import 'package:tkbank/theme/app_colors.dart';
import 'package:tkbank/utils/formatters/phone_number_formatter.dart';
import 'package:tkbank/utils/validators.dart';

const DEV_PHONE = '010-8902-3754';

class FindIdScreen extends StatefulWidget {
  const FindIdScreen({super.key});

  @override
  State<FindIdScreen> createState() => _FindIdScreenState();
}

class _FindIdScreenState extends State<FindIdScreen>
    with SingleTickerProviderStateMixin {

  // ======================
  // Controller / Focus
  // ======================
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final codeCtrl = TextEditingController();

  final nameFocus = FocusNode();
  final phoneFocus = FocusNode();

  // ======================
  // State
  // ======================
  String? nameError;
  String? phoneError;

  bool codeRequested = false;
  bool codeError = false;
  bool isPhoneVerified = false;

  // ======================
  // Shake Animation
  // ======================
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -1, end: 1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut),
    );

    nameFocus.addListener(() {
      if (!nameFocus.hasFocus) _validateName();
    });

    phoneFocus.addListener(() {
      if (!phoneFocus.hasFocus) _validatePhoneOnly();
    });
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    nameCtrl.dispose();
    phoneCtrl.dispose();
    codeCtrl.dispose();
    nameFocus.dispose();
    phoneFocus.dispose();
    super.dispose();
  }

  // ======================
  // Validation
  // ======================
  bool _validateName() {
    final ok = Validators.isValidName(nameCtrl.text.trim());
    setState(() => nameError = ok ? null : '이름을 정확히 입력해주세요.');
    if (!ok) _shakeCtrl.forward(from: 0);
    return ok;
  }

  bool _validatePhoneOnly() {
    if (phoneCtrl.text.trim() == DEV_PHONE) {
      setState(() {
        phoneError = null;
        isPhoneVerified = true;   // 🔥 핵심
        codeRequested = false;
        codeError = false;
      });
      return true;
    }

    final ok = Validators.isValidHp(phoneCtrl.text.trim());
    setState(() => phoneError = ok ? null : '휴대폰 번호를 확인해주세요.');
    if (!ok) _shakeCtrl.forward(from: 0);
    return ok;
  }

  // ======================
  // 휴대폰 인증
  // ======================
  Future<void> _sendCode() async {
    final ok = _validatePhoneOnly();
    if (!ok) return;

    // ✅ 개발용 우회
    if (phoneCtrl.text.trim() == DEV_PHONE) {
      setState(() {
        isPhoneVerified = true;
        codeRequested = false;
        codeError = false;
      });
      FocusScope.of(context).unfocus();
      return;
    }

    await MemberService().sendHpCode(phoneCtrl.text.trim());

    setState(() {
      codeRequested = true;
      codeError = false;
    });
  }

  Future<void> _verifyCode(String code) async {
    final ok = await MemberService().verifyHpCode(
      hp: phoneCtrl.text.trim(),
      code: code,
    );

    if (ok) {
      setState(() {
        isPhoneVerified = true;
        codeRequested = false;
        codeError = false;
      });
      FocusScope.of(context).unfocus();
    } else {
      setState(() => codeError = true);
      _shakeCtrl.forward(from: 0);
    }
  }

  // ======================
  // 아이디 찾기
  // ======================
  Future<void> _findId() async {
    final nameOk = _validateName();
    if (!nameOk || !isPhoneVerified) return;

    try {
      final result = await MemberService().findUserIdByHp(
        userName: nameCtrl.text.trim(),
        hp: phoneCtrl.text.trim(),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FindIdResultScreen(
            userId: result['userId'], userName: result['userName'],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  // ======================
  // UI
  // ======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24), // ✅ 통일
        child: SizedBox(
          height: 56, // ✅ 통일
          child: ElevatedButton(
            onPressed: _findId, // 필요하면 여기 조건부로 바꿔도 됨
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              '아이디 찾기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AnimatedBuilder(
            animation: _shakeAnim,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_shakeAnim.value, 0),
                child: child,
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '아이디 찾기',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),

                _label('이름'),
                _input(nameCtrl, focus: nameFocus),
                _error(nameError),

                _label('휴대폰 번호'),
                Row(
                  children: [
                    Expanded(
                      child: _input(
                        phoneCtrl,
                        focus: phoneFocus,
                        enabled: !isPhoneVerified,
                        keyboard: TextInputType.phone,
                        formatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(13),
                          PhoneNumberFormatter(),
                        ],
                        isError: phoneError != null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPhoneVerified ? AppColors.gray3 : AppColors.primary,
                          disabledBackgroundColor: AppColors.gray3, // ✅ 비활성도 회색
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          elevation: 0,
                        ),
                        onPressed: isPhoneVerified ? null : _sendCode,
                        child: Text(isPhoneVerified ? '완료' : '인증하기'),
                      ),
                    ),
                  ],
                ),
                _error(phoneError),

                if (codeRequested && !isPhoneVerified) ...[
                  const SizedBox(height: 12),
                  _label('인증번호'),
                  _input(
                    codeCtrl,
                    maxLength: 4,
                    keyboard: TextInputType.number,
                    formatters: [FilteringTextInputFormatter.digitsOnly],
                    isError: codeError,
                    onChanged: (v) {
                      if (v.length == 4) {
                        _verifyCode(v);
                      }
                    },
                  ),
                  if (codeError)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        '인증번호가 올바르지 않습니다.',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],

                if (isPhoneVerified)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 6),
                        Text(
                          '휴대폰 인증이 완료되었습니다.',
                          style: TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ======================
  // Components
  // ======================
  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Text(text),
    );
  }

  Widget _input(
      TextEditingController ctrl, {
        FocusNode? focus,
        bool obscure = false,
        bool enabled = true,
        TextInputType keyboard = TextInputType.text,
        int? maxLength,
        List<TextInputFormatter>? formatters,
        ValueChanged<String>? onChanged,
        bool isError = false,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? Colors.red : Colors.transparent,
          width: 1.3,
        ),
      ),
      child: TextField(
        controller: ctrl,
        focusNode: focus,
        enabled: enabled,
        obscureText: obscure,
        keyboardType: keyboard,
        maxLength: maxLength,
        inputFormatters: formatters,
        onChanged: onChanged,
        decoration: const InputDecoration(
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          counterText: '',
        ),
      ),
    );
  }

  Widget _error(String? msg) {
    if (msg == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        msg,
        style: const TextStyle(color: Colors.red, fontSize: 12),
      ),
    );
  }
}
