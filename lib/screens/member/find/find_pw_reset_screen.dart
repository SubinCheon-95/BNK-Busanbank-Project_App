/*
  날짜 : 2025/12/18
  내용 : 비밀번호 재설정
  작성자 : 오서정
*/
import 'package:flutter/material.dart';
import 'package:tkbank/screens/member/find/find_pw_result_screen.dart';
import 'package:tkbank/services/member_service.dart';
import 'package:tkbank/theme/app_colors.dart';
import 'package:tkbank/utils/validators.dart';

class FindPwResetScreen extends StatefulWidget {
  final String userId;

  const FindPwResetScreen({
    super.key,
    required this.userId,
  });

  @override
  State<FindPwResetScreen> createState() => _FindPwResetScreenState();
}

class _FindPwResetScreenState extends State<FindPwResetScreen>
    with SingleTickerProviderStateMixin {

  // ======================
  // Controller / Focus
  // ======================
  final pwCtrl = TextEditingController();
  final pwConfirmCtrl = TextEditingController();

  final pwFocus = FocusNode();
  final pwConfirmFocus = FocusNode();

  // ======================
  // Error State
  // ======================
  String? pwError;
  String? pwConfirmError;

  bool showPw = false;
  bool showPwConfirm = false;

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
      duration: const Duration(milliseconds: 200),
    );

    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -1, end: 1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut),
    );

    pwFocus.addListener(() {
      if (!pwFocus.hasFocus) _validatePw();
    });

    pwConfirmFocus.addListener(() {
      if (!pwConfirmFocus.hasFocus) _validatePwConfirm();
    });
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    pwCtrl.dispose();
    pwConfirmCtrl.dispose();
    pwFocus.dispose();
    pwConfirmFocus.dispose();
    super.dispose();
  }

  // ======================
  // Validation
  // ======================
  bool _validatePw() {
    final ok = Validators.isValidPassword(pwCtrl.text);
    setState(() => pwError = ok ? null : '영문/숫자/특수문자 포함 8자 이상');
    if (!ok) _shakeCtrl.forward(from: 0);
    return ok;
  }

  bool _validatePwConfirm() {
    final ok = pwCtrl.text == pwConfirmCtrl.text;
    setState(() => pwConfirmError = ok ? null : '비밀번호가 일치하지 않습니다.');
    if (!ok) _shakeCtrl.forward(from: 0);
    return ok;
  }

  Future<void> _changePw() async {
    final ok = _validatePw() & _validatePwConfirm();
    if (!ok) return;

    try {
      await MemberService().resetPassword(
        userId: widget.userId,
        newPw: pwCtrl.text.trim(),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const FindPwResultScreen(),
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
            onPressed: _changePw,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              '비밀번호 변경',
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
                  '비밀번호 재설정',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '새로운 비밀번호를 입력해주세요.',
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 32),

                /// 🔑 새 비밀번호
                _label('새 비밀번호'),
                _input(
                  pwCtrl,
                  focus: pwFocus,
                  obscure: !showPw,
                  showToggle: true,
                  onToggle: () {
                    setState(() => showPw = !showPw);
                  },
                  isError: pwError != null,
                ),
                _hintOrError(
                  pwError,
                  '영문 + 숫자 + 특수문자 포함 8자 이상',
                ),

                /// 🔑 비밀번호 확인
                _label('비밀번호 확인'),
                _input(
                  pwConfirmCtrl,
                  focus: pwConfirmFocus,
                  obscure: !showPwConfirm,
                  showToggle: true,
                  onToggle: () {
                    setState(() => showPwConfirm = !showPwConfirm);
                  },
                  isError: pwConfirmError != null,
                ),
                _error(pwConfirmError),


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
        bool showToggle = false,
        VoidCallback? onToggle,
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
        obscureText: obscure,
        decoration: InputDecoration(
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          suffixIcon: showToggle
              ? IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              size: 20,
            ),
            onPressed: onToggle,
          )
              : null,
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

  Widget _hintOrError(String? error, String hint) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        error ?? hint,
        style: TextStyle(
          fontSize: 12,
          color: error != null ? Colors.red : Colors.grey,
        ),
      ),
    );
  }
}
