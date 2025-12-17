import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tkbank/providers/register_provider.dart';
import 'package:tkbank/services/member_service.dart';
import 'package:tkbank/utils/validators.dart';
import 'package:tkbank/widgets/register_step_indicator.dart';

class AccountSetupScreen extends StatefulWidget {
  const AccountSetupScreen({super.key});

  @override
  State<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends State<AccountSetupScreen>
    with SingleTickerProviderStateMixin {

  // ======================
  // Controller
  // ======================
  final idCtrl = TextEditingController();
  final pwCtrl = TextEditingController();
  final pwConfirmCtrl = TextEditingController();
  final accountPwCtrl = TextEditingController();
  final accountPwConfirmCtrl = TextEditingController();

  bool idChecked = false;
  bool idDuplicated = false;

  // ======================
  // Focus
  // ======================
  final idFocus = FocusNode();
  final pwFocus = FocusNode();
  final pwConfirmFocus = FocusNode();
  final accountPwFocus = FocusNode();
  final accountPwConfirmFocus = FocusNode();

  // ======================
  // Error State
  // ======================
  String? idError;
  String? pwError;
  String? pwConfirmError;
  String? accountPwError;
  String? accountPwConfirmError;

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
      duration: const Duration(milliseconds: 120),
    );

    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -1, end: 1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut),
    );

    idFocus.addListener(() {
      if (!idFocus.hasFocus) _validateId();
    });
    pwFocus.addListener(() {
      if (!pwFocus.hasFocus) _validatePw();
    });
    pwConfirmFocus.addListener(() {
      if (!pwConfirmFocus.hasFocus) _validatePwConfirm();
    });
    accountPwFocus.addListener(() {
      if (!accountPwFocus.hasFocus) _validateAccountPw();
    });
    accountPwConfirmFocus.addListener(() {
      if (!accountPwConfirmFocus.hasFocus) _validateAccountPwConfirm();
    });
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    idCtrl.dispose();
    pwCtrl.dispose();
    pwConfirmCtrl.dispose();
    accountPwCtrl.dispose();
    accountPwConfirmCtrl.dispose();
    super.dispose();
  }

  // ======================
  // Validation
  // ======================
  Future<bool> _validateId() async {
    if (!Validators.isValidUserId(idCtrl.text)) {
      setState(() {
        idError = '사용할 수 없는 아이디입니다.';
        idChecked = false;
      });
      _shakeCtrl.forward(from: 0);
      return false;
    }

    final duplicated = await MemberService().isDuplicated(
      type: 'userId',
      value: idCtrl.text,
    );

    setState(() {
      idDuplicated = duplicated;
      idChecked = true;
      idError = duplicated ? '이미 사용 중인 아이디입니다.' : null;
    });

    if (duplicated) _shakeCtrl.forward(from: 0);

    return !duplicated;
  }

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

  bool _validateAccountPw() {
    final ok = RegExp(r'^\d{4}$').hasMatch(accountPwCtrl.text);
    setState(() => accountPwError = ok ? null : '숫자 4자리를 입력해주세요.');
    if (!ok) _shakeCtrl.forward(from: 0);
    return ok;
  }

  bool _validateAccountPwConfirm() {
    final ok = accountPwCtrl.text == accountPwConfirmCtrl.text;
    setState(() =>
    accountPwConfirmError = ok ? null : '계좌 비밀번호가 일치하지 않습니다.');
    if (!ok) _shakeCtrl.forward(from: 0);
    return ok;
  }

  Future<bool> _validateAll() async {
    final idOk = await _validateId();
    final pwOk = _validatePw();
    final pwConfirmOk = _validatePwConfirm();
    final accPwOk = _validateAccountPw();
    final accPwConfirmOk = _validateAccountPwConfirm();

    return idOk && pwOk && pwConfirmOk && accPwOk && accPwConfirmOk;
  }

  // ======================
  // UI
  // ======================
  @override
  Widget build(BuildContext context) {
    final provider = context.read<RegisterProvider>();

    return Scaffold(
      backgroundColor: Colors.white,

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: () async {
              final ok = await _validateAll();
              if (!ok) return;

              provider.setAccountInfo(
                userId: idCtrl.text.trim(),
                userPw: pwCtrl.text.trim(),
                accountPassword: accountPwCtrl.text.trim(),
              );

              await MemberService().register(provider.toJson());
              provider.clear();

              Navigator.pushReplacementNamed(context, '/register/finish');
            },
            child: const Text('회원가입 완료'),
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
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
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new),
                  onPressed: () => Navigator.pop(context),
                ),

                RegisterStepIndicator(step: 3),
                const SizedBox(height: 32),

                const Text(
                  '인터넷뱅킹 가입',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),

                _field(
                  label: '아이디',
                  ctrl: idCtrl,
                  focus: idFocus,
                  error: idError,
                  required: true,
                ),

                _field(
                  label: '비밀번호',
                  ctrl: pwCtrl,
                  focus: pwFocus,
                  obscure: true,
                  error: pwError,
                  required: true,
                ),

                _field(
                  label: '비밀번호 확인',
                  ctrl: pwConfirmCtrl,
                  focus: pwConfirmFocus,
                  obscure: true,
                  error: pwConfirmError,
                  required: true,
                ),

                _field(
                  label: '계좌 비밀번호 (숫자 4자리)',
                  ctrl: accountPwCtrl,
                  focus: accountPwFocus,
                  obscure: true,
                  maxLength: 4,
                  keyboard: TextInputType.number,
                  error: accountPwError,
                  required: true,
                ),

                _field(
                  label: '계좌 비밀번호 확인',
                  ctrl: accountPwConfirmCtrl,
                  focus: accountPwConfirmFocus,
                  obscure: true,
                  maxLength: 4,
                  keyboard: TextInputType.number,
                  error: accountPwConfirmError,
                  required: true,
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
  Widget _label(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          if (required)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.circle, size: 6, color: Colors.red),
            ),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController ctrl,
    required FocusNode focus,
    String? error,
    bool obscure = false,
    int? maxLength,
    TextInputType keyboard = TextInputType.text,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label, required: required),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: error != null ? Colors.red : Colors.transparent,
                width: 1.3,
              ),
            ),
            child: TextField(
              controller: ctrl,
              focusNode: focus,
              obscureText: obscure,
              keyboardType: keyboard,
              maxLength: maxLength,
              decoration: const InputDecoration(
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                counterText: '',
              ),
            ),
          ),

          /// 🔴 에러 메시지
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                error,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),

          /// 🟢 아이디 중복 통과 메시지
          if (label == '아이디' && idChecked && !idDuplicated && error == null)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                '사용 가능한 아이디입니다.',
                style: TextStyle(color: Colors.green, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
