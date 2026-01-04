/*
  날짜 : 2025/12/17
  내용 : 회원가입 계정 설정 구현
  작성자 : 오서정
  수정: 2025/12/29 - 이체 한도 추가 - 작성자: 오서정
  수정: 2025/01/04 - UI 수정 - 작성자: 오서정
*/
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tkbank/providers/register_provider.dart';
import 'package:tkbank/screens/member/register/register_welcome_screen.dart';
import 'package:tkbank/services/member_service.dart';
import 'package:tkbank/theme/app_colors.dart';
import 'package:tkbank/utils/formatters/money_formatter.dart';
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

  final TextEditingController dailyLimitCtrl = TextEditingController();
  final TextEditingController onceLimitCtrl = TextEditingController();

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
  String? dailyLimitError;
  String? onceLimitError;


  final FocusNode dailyLimitFocus = FocusNode();
  final FocusNode onceLimitFocus = FocusNode();
  // ======================
  // Shake Animation
  // ======================
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;


  // ======================
  // Transfer Limit
  // ======================
  int? onceLimit;
  int? dailyLimit;

  // 최소
  static const int _minDailyLimit = 10000;     // 1만원
  static const int _minOnceLimit  = 10000;     // 1만원

  // 최대
  static const int _maxDailyLimit = 5000000; // 500만원
  static const int _maxOnceLimit  = 5000000; // 500만원



  bool showPw = false;
  bool showPwConfirm = false;

  bool _validateLimits() {
    bool ok = true;

    final daily =
    int.tryParse(dailyLimitCtrl.text.replaceAll(',', ''));
    final once =
    int.tryParse(onceLimitCtrl.text.replaceAll(',', ''));

    setState(() {
      dailyLimitError = null;
      onceLimitError = null;
    });

    // 1일 한도
    if (daily == null) {
      dailyLimitError = '1일 이체한도를 입력해주세요.';
      dailyLimitFocus.requestFocus();
      ok = false;
    } else if (daily < _minDailyLimit) {
      dailyLimitError = '최소 ${_minDailyLimit ~/ 10000}만원 이상 입력해주세요.';
      dailyLimitFocus.requestFocus();
      ok = false;
    } else {
      dailyLimit = daily;
    }

    // 1회 한도
    if (once == null) {
      onceLimitError = '1회 이체한도를 입력해주세요.';
      if (ok) onceLimitFocus.requestFocus();
      ok = false;
    } else if (once < _minOnceLimit) {
      onceLimitError = '최소 ${_minOnceLimit ~/ 10000}만원 이상 입력해주세요.';
      if (ok) onceLimitFocus.requestFocus();
      ok = false;
    } else {
      onceLimit = once;
    }

    return ok;
  }


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

    void refresh() => setState(() {});
    idCtrl.addListener(refresh);
    pwCtrl.addListener(refresh);
    pwConfirmCtrl.addListener(refresh);
    accountPwCtrl.addListener(refresh);
    accountPwConfirmCtrl.addListener(refresh);
    dailyLimitCtrl.addListener(refresh);
    onceLimitCtrl.addListener(refresh);
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    idCtrl.dispose();
    pwCtrl.dispose();
    pwConfirmCtrl.dispose();
    accountPwCtrl.dispose();
    accountPwConfirmCtrl.dispose();
    dailyLimitCtrl.dispose();
    onceLimitCtrl.dispose();
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

  bool get _canSubmit {
    // ✅ 아이디: 형식 OK + 중복검사 완료 + 중복 아님
    final idOk = Validators.isValidUserId(idCtrl.text.trim()) && idChecked && !idDuplicated;

    // ✅ 비밀번호: 정책 OK + 확인 일치
    final pwOk = Validators.isValidPassword(pwCtrl.text.trim()) &&
        pwCtrl.text.trim() == pwConfirmCtrl.text.trim();

    // ✅ 계좌 비밀번호: 숫자 4자리 + 확인 일치
    final accPwOk = RegExp(r'^\d{4}$').hasMatch(accountPwCtrl.text.trim()) &&
        accountPwCtrl.text.trim() == accountPwConfirmCtrl.text.trim();

    // ✅ 이체한도: 숫자 변환 가능 + 최소/최대 범위 만족
    final daily = int.tryParse(dailyLimitCtrl.text.replaceAll(',', '').trim());
    final once  = int.tryParse(onceLimitCtrl.text.replaceAll(',', '').trim());

    final dailyOk = daily != null && daily >= _minDailyLimit && daily <= _maxDailyLimit;
    final onceOk  = once  != null && once  >= _minOnceLimit  && once  <= _maxOnceLimit;

    return idOk && pwOk && accPwOk && dailyOk && onceOk;
  }

  Future<bool> _validateAll() async {
    final idOk = await _validateId();
    final pwOk = _validatePw();
    final pwConfirmOk = _validatePwConfirm();
    final accPwOk = _validateAccountPw();
    final accPwConfirmOk = _validateAccountPwConfirm();

    return idOk && pwOk && pwConfirmOk && accPwOk && accPwConfirmOk;
  }

  Future<bool> _validateAllWithLimits() async {
    final accountOk = await _validateAll();
    final limitOk = _validateLimits();

    return accountOk && limitOk;
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
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24), // ✅ 통일
        child: SizedBox(
          height: 56, // ✅ 통일
          child: ElevatedButton(
            onPressed: _canSubmit
                ? () async {
              final ok = await _validateAllWithLimits();
              if (!ok) return;

              provider.setAccountInfo(
                userId: idCtrl.text.trim(),
                userPw: pwCtrl.text.trim(),
                accountPassword: accountPwCtrl.text.trim(),
                email: provider.email,
                onceLimit: onceLimit,
                dailyLimit: dailyLimit,
              );

              await MemberService().register(provider.toJson());
              provider.clear();

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const RegisterWelcomeScreen(),
                ),
              );
            }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              '회원가입 완료',
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
                  obscure: !showPw,
                  showToggle: true,
                  onToggle: () {
                    setState(() => showPw = !showPw);
                  },
                  error: pwError,
                  required: true,
                ),

                _field(
                  label: '비밀번호 확인',
                  ctrl: pwConfirmCtrl,
                  focus: pwConfirmFocus,
                  obscure: true,
                  error: pwConfirmError,
                ),

                // ✅ 계좌 비밀번호 (컴팩트 버전)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _accountPwLabel(context),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: accountPwError != null ? Colors.red : Colors.transparent,
                            width: 1.3,
                          ),
                        ),
                        child: TextField(
                          controller: accountPwCtrl,
                          focusNode: accountPwFocus,
                          obscureText: true,
                          maxLength: 4,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            counterText: '',
                            hintText: '숫자 4자리 입력',
                          ),
                        ),
                      ),

                      // ✅ 에러 메시지(필요 시만 표시) → 아래 확인 입력과 간격 깔끔
                      if (accountPwError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            accountPwError!,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),

                _field(
                  label: '계좌 비밀번호 확인',
                  ctrl: accountPwConfirmCtrl,
                  focus: accountPwConfirmFocus,
                  obscure: true,
                  maxLength: 4,
                  keyboard: TextInputType.number,
                  error: accountPwConfirmError,
                ),
                const Text('이체한도 설정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '디지털OTP 미등록 시 이체한도는 1회/1일 최대 500만원입니다.\n'
                              '디지털OTP 등록 후 최대 1회 1억원 / 1일 5억원까지 설정할 수 있습니다.',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),


                _limitInputRow(
                  label: '1일 이체한도',
                  required: true,
                  controller: dailyLimitCtrl,
                  focusNode: dailyLimitFocus,
                  minLimit: _minDailyLimit,
                  maxLimit: _maxDailyLimit,
                  error: dailyLimitError,
                  onMax: () {
                    dailyLimitCtrl.text = _maxDailyLimit.toString();
                    setState(() => dailyLimit = _maxDailyLimit);
                  },
                  onValueChanged: (v) {
                    setState(() => dailyLimit = v);
                  },
                ),

                _limitInputRow(
                  label: '1회 이체한도',
                  required: true,
                  controller: onceLimitCtrl,
                  focusNode: onceLimitFocus,
                  minLimit: _minOnceLimit,
                  maxLimit: _maxOnceLimit,
                  error: onceLimitError,
                  onMax: () {
                    onceLimitCtrl.text = _maxOnceLimit.toString();
                    setState(() => onceLimit = _maxOnceLimit);
                  },
                  onValueChanged: (v) {
                    setState(() => onceLimit = v);
                  },
                ),




              ],
            ),
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
    bool showToggle = false,
    VoidCallback? onToggle,
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
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                counterText: '',
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
          ),

          /// 🔴 에러 메시지
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              error ??
                  (label == '아이디'
                      ? '영문 소문자 시작, 영문 + 숫자 조합, 5~20자 이내'
                      : label == '비밀번호'
                      ? '영문 + 숫자 + 특수문자 포함 8~16자 이내'
                      : ''),
              style: TextStyle(
                fontSize: 12,
                color: error != null ? Colors.red : Colors.grey.shade600,
              ),
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

  Widget _accountPwLabel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Text(
            '계좌 비밀번호 (숫자 4자리)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.circle, size: 6, color: Colors.red),

          const SizedBox(width: 6),

          /// ❓ 아이콘
          GestureDetector(
            onTap: () => _showAccountPwGuide(context),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: const Center(
                child: Text(
                  '?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAccountPwGuide(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true, // 바깥 눌러도 닫힘
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '계좌 비밀번호',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            '본 회원 정보로 가입하는 모든 금융상품의\n'
                '계좌 비밀번호로 자동 설정됩니다.\n\n'
                '숫자 4자리를 입력해주세요.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ),
          ],
        );
      },
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

  Widget _limitInputRow({
    required String label,
    bool required = false,
    required TextEditingController controller,
    required FocusNode focusNode,
    required int minLimit,
    required int maxLimit,
    required VoidCallback onMax,
    required ValueChanged<int?> onValueChanged,
    String? error,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (required) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.circle,
                  size: 6,
                  color: Colors.red,
                ),
              ],
            ],
          ),

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
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '금액 입력',
                          ),
                          onChanged: (text) {
                            final value = int.tryParse(text.replaceAll(',', ''));

                            setState(() {
                              if (label.contains('1일')) {
                                if (value == null || value < minLimit) {
                                  dailyLimitError = '최소 ${minLimit ~/ 10000}만원 이상 입력해주세요.';
                                } else {
                                  dailyLimitError = null;
                                  dailyLimit = value;
                                }
                              } else {
                                if (value == null || value < minLimit) {
                                  onceLimitError = '최소 ${minLimit ~/ 10000}만원 이상 입력해주세요.';
                                } else {
                                  onceLimitError = null;
                                  onceLimit = value;
                                }
                              }
                            });
                          },

                          onEditingComplete: () {
                            final value =
                            int.tryParse(controller.text.replaceAll(',', ''));

                            setState(() {
                              if (label.contains('1일')) {
                                if (value == null || value < minLimit) {
                                  dailyLimitError = '최소 ${minLimit ~/ 10000}만원 이상 입력해주세요.';
                                }
                              } else {
                                if (value == null || value < minLimit) {
                                  onceLimitError = '최소 ${minLimit ~/ 10000}만원 이상 입력해주세요.';
                                }
                              }
                            });
                          },


                        )
                      ),
                      Row(
                        children: [
                          const Text('원'),

                          if (controller.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  controller.clear();

                                  if (label.contains('1일')) {
                                    dailyLimit = null;
                                    dailyLimitError = '금액을 입력해주세요.';
                                  } else {
                                    onceLimit = null;
                                    onceLimitError = '금액을 입력해주세요.';
                                  }
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(left: 8),
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
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                ),
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


}


class MaxValueFormatter extends TextInputFormatter {
  final int max;
  MaxValueFormatter(this.max);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    if (newValue.text.isEmpty) return newValue;

    final value = int.tryParse(newValue.text);
    if (value == null) return oldValue;

    if (value > max) return oldValue; // ✅ 초과 입력 차단
    return newValue;
  }
}
