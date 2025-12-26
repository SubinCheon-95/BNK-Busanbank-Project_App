/*
  날짜 : 2025/12/17
  내용 : 회원가입 개인정보 구현
  작성자 : 오서정
  수정: 2025/12/26 - 주소 추가 - 오서정
*/
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tkbank/providers/register_provider.dart';
import 'package:tkbank/screens/member/account_setup_screen.dart';
import 'package:tkbank/services/member_service.dart';
import 'package:tkbank/utils/formatters/phone_number_formatter.dart';
import 'package:tkbank/utils/validators.dart';
import 'package:tkbank/widgets/register_step_indicator.dart';
import 'package:kpostal/kpostal.dart';


const DEV_PHONE = '010-1111-1111';


class PhoneVerifyScreen extends StatefulWidget {
  const PhoneVerifyScreen({super.key});

  @override
  State<PhoneVerifyScreen> createState() => _PhoneVerifyScreenState();
}

class _PhoneVerifyScreenState extends State<PhoneVerifyScreen>
    with SingleTickerProviderStateMixin {

  // 2025/12/22 - 이메일 도메인 추천 기능 추가 - 작성자: 오서정
  final List<String> _emailDomains = [
    'gmail.com',
    'naver.com',
    'daum.net',
    'kakao.com',
    'hanmail.net',
  ];

  bool _showDomainSuggestion = false;
  List<String> _filteredDomains = [];

  // ======================
  // Controller / Focus
  // ======================
  final nameCtrl = TextEditingController();
  final rrnFrontCtrl = TextEditingController();
  final rrnBackCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final codeCtrl = TextEditingController();

  final nameFocus = FocusNode();
  final rrnFrontFocus = FocusNode();
  final rrnBackFocus = FocusNode();
  final emailFocus = FocusNode();
  final phoneFocus = FocusNode();


  // ======================
// Address Controller
// ======================
  final zipCtrl = TextEditingController();
  final addr1Ctrl = TextEditingController();
  final addr2Ctrl = TextEditingController();

  final addr2Focus = FocusNode();


  // ======================
  // Error State
  // ======================
  String? nameError;
  String? juminError;
  String? emailError;
  String? phoneError;

  bool codeRequested = false;
  bool codeError = false;
  bool isPhoneVerified = false;

  bool emailChecked = false;
  bool emailDuplicated = false;

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
      duration: const Duration(milliseconds: 300),
    );

    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -1),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -1, end: 1),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1, end: 0.0),
        weight: 1,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _shakeCtrl,
        curve: Curves.easeInOut,
      ),
    );

    // focus 벗어날 때 검증
    nameFocus.addListener(() {
      if (!nameFocus.hasFocus) _validateName();
    });
    rrnBackFocus.addListener(() {
      if (!rrnBackFocus.hasFocus) {
        _validateJumin();
      }
    });
    emailFocus.addListener(() async {
      if (!emailFocus.hasFocus) {
        setState(() => _showDomainSuggestion = false);
        await _validateEmail();
      }
    });
    phoneFocus.addListener(() {
      if (!phoneFocus.hasFocus) _validatePhone();
    });
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();

    nameCtrl.dispose();
    rrnFrontCtrl.dispose();
    rrnBackCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    codeCtrl.dispose();

    nameFocus.dispose();
    rrnFrontFocus.dispose();
    rrnBackFocus.dispose();
    emailFocus.dispose();
    phoneFocus.dispose();


    zipCtrl.dispose();
    addr1Ctrl.dispose();
    addr2Ctrl.dispose();

    addr2Focus.dispose();

    super.dispose();
  }

  // ======================
  // Validation Functions
  // ======================
  bool _validateName() {
    final ok = Validators.isValidName(nameCtrl.text);
    setState(() => nameError = ok ? null : '이름이 유효하지 않습니다.');
    if (!ok) _shakeCtrl.forward(from: 0);
    return ok;
  }

  bool _validateJumin() {
    final ok = Validators.isValidJumin(rrnFrontCtrl.text, rrnBackCtrl.text);
    setState(() => juminError = ok ? null : '주민등록번호가 올바르지 않습니다.');
    if (!ok) _shakeCtrl.forward(from: 0);
    return ok;
  }

  Future<bool> _validateEmail() async {
    if (!Validators.isValidEmail(emailCtrl.text)) {
      setState(() {
        emailError = '이메일 형식이 올바르지 않습니다.';
        emailChecked = false;
      });
      _shakeCtrl.forward(from: 0);
      return false;
    }

    final duplicated = await MemberService().isDuplicated(
      type: 'email',
      value: emailCtrl.text.trim(),
    );

    setState(() {
      emailDuplicated = duplicated;
      emailChecked = true;
      emailError = duplicated ? '이미 사용 중인 이메일입니다.' : null;
    });

    if (duplicated) _shakeCtrl.forward(from: 0);

    return !duplicated;
  }

  Future<bool> _validatePhone() async {
    // ✅ 개발용 번호는 무조건 통과 + 인증 처리
    if (phoneCtrl.text.trim() == DEV_PHONE) {
      setState(() {
        phoneError = null;
        isPhoneVerified = true;   // 🔥 핵심
        codeRequested = false;
        codeError = false;
      });
      return true;
    }
    if (!Validators.isValidHp(phoneCtrl.text)) {
      setState(() => phoneError = '휴대폰 번호를 확인해주세요.');
      _shakeCtrl.forward(from: 0);
      return false;
    }

    final duplicated = await MemberService().isDuplicated(
      type: 'hp',
      value: phoneCtrl.text.trim(),
    );

    if (duplicated) {
      setState(() => phoneError = '이미 가입된 휴대폰 번호입니다.');
      _shakeCtrl.forward(from: 0);
      return false;
    }

    setState(() => phoneError = null);
    return true;
  }

  Future<bool> _validateAll() async {
    final nameOk  = _validateName();
    final juminOk = _validateJumin();
    final emailOk = await _validateEmail();
    final phoneOk = await _validatePhone();

    return nameOk && juminOk && emailOk && phoneOk && isPhoneVerified;
  }

  // ======================
  // UI
  // ======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () async {
              final ok = await _validateAll();
              if (!ok) return;

              final provider = context.read<RegisterProvider>();

              provider.setPhoneInfo(
                hp: phoneCtrl.text.trim(),
                userName: nameCtrl.text.trim(),
              );

              provider.setUserInfo(
                rrn: rrnFrontCtrl.text + rrnBackCtrl.text,
                zip: zipCtrl.text.trim().isEmpty ? null : zipCtrl.text.trim(),
                addr1: addr1Ctrl.text.trim().isEmpty ? null : addr1Ctrl.text.trim(),
                addr2: addr2Ctrl.text.trim().isEmpty ? null : addr2Ctrl.text.trim(),
              );

              provider.email = emailCtrl.text.trim();

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AccountSetupScreen()),
              );
            },
            child: const Text('다음'),
          ),
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
                /// 🔙 뒤로가기
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),

                const SizedBox(height: 12),
                RegisterStepIndicator(step: 2),
                const SizedBox(height: 32),

                const Text(
                  '정보등록',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                _label('이름', required: true),
                _input(nameCtrl, focus: nameFocus, isError: nameError != null, ),
                _errorText(nameError),

                _label('주민등록번호', required: true),
                Row(
                  children: [
                    Expanded(
                      child: _input(
                        rrnFrontCtrl,
                        focus: rrnFrontFocus,
                        isError: juminError != null,
                        maxLength: 6,
                        keyboard: TextInputType.number,
                        onChanged: (v) {
                          if (v.length == 6) {
                            FocusScope.of(context).requestFocus(rrnBackFocus);
                          }
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('-'),
                    ),
                    Expanded(
                      child: _input(
                        rrnBackCtrl,
                        focus: rrnBackFocus,
                        isError: juminError != null,
                        maxLength: 7,
                        obscure: true,
                        keyboard: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                _errorText(juminError),

                _label('이메일', required: true),
                _input(emailCtrl,
                  focus: emailFocus,
                  isError: emailError != null,
                  // 2025/12/22 - 이메일 도메인 추천 기능 추가 - 작성자: 오서정
                  onChanged: (value) {
                    // @가 없으면 추천 안 함
                    if (!value.contains('@')) {
                      setState(() => _showDomainSuggestion = false);
                      return;
                    }

                    final parts = value.split('@');

                    // @가 2개 이상이면 비정상 → 숨김
                    if (parts.length != 2) {
                      setState(() => _showDomainSuggestion = false);
                      return;
                    }

                    final domainPart = parts[1];

                    // 이미 도메인이 완성된 경우 ('.' 포함 + 후보에 존재)
                    if (_emailDomains.contains(domainPart)) {
                      setState(() => _showDomainSuggestion = false);
                      return;
                    }

                    // 도메인 입력 중일 때만 필터링
                    final matched = _emailDomains
                        .where((d) => d.startsWith(domainPart))
                        .toList();

                    setState(() {
                      _filteredDomains = matched;
                      _showDomainSuggestion = matched.isNotEmpty;
                    });
                  },
                ),
                _errorText(emailError),
                if (emailChecked && !emailDuplicated && emailError == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      '사용 가능한 이메일입니다.',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ),
                if (_showDomainSuggestion)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: _filteredDomains.map((domain) {
                        return ListTile(
                          dense: true,
                          title: Text(domain),
                          onTap: () {
                            final id = emailCtrl.text.split('@')[0];

                            setState(() {
                              emailCtrl.text = '$id@$domain';
                              _showDomainSuggestion = false;
                            });

                            FocusScope.of(context).unfocus();
                          },
                        );
                      }).toList(),
                    ),
                  ),

                _label('휴대폰 번호', required: true),
                Row(
                  children: [
                    Expanded(
                      child: _input(
                        phoneCtrl,
                        focus: phoneFocus,
                        enabled: !isPhoneVerified,
                        isError: phoneError != null,
                        keyboard: TextInputType.phone,
                        formatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(13),
                          PhoneNumberFormatter(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isPhoneVerified
                            ? null
                            : () async {
                          final ok = await _validatePhone();
                          if (!ok) return;

                          // ✅ 개발용 우회 인증
                          if (phoneCtrl.text.trim() == DEV_PHONE) {
                            setState(() {
                              isPhoneVerified = true;
                              codeRequested = false;
                              codeError = false;
                            });

                            FocusScope.of(context).unfocus();
                            return;
                          }
                          //여기까지 개발용 우회 인증임

                          final provider = context.read<RegisterProvider>();

                          await provider.sendHpCode(
                            hp: phoneCtrl.text.trim(),
                          );

                          setState(() {
                            codeRequested = true;
                          });
                        },
                        child: Text(
                          isPhoneVerified ? '완료' : (codeRequested ? '재전송' : '인증하기'),
                        ),
                      ),
                    ),
                  ],
                ),
                /// 🔐 인증번호 입력 (조건부 표시)
                if (codeRequested && !isPhoneVerified) ...[
                  const SizedBox(height: 12),
                  _label('인증번호'),
                  _input(
                    codeCtrl,
                    keyboard: TextInputType.number,
                    maxLength: 4,
                    formatters: [
                      FilteringTextInputFormatter.digitsOnly, // ⭐ 여기
                    ],
                    onChanged: (v) async {
                      final code = v.trim();

                      if (code.length == 4) {
                        final provider = context.read<RegisterProvider>();

                        final ok = await provider.verifyHpCode(
                          hp: phoneCtrl.text.trim(),
                          code: code,
                        );

                        if (ok) {

                          setState(() {
                            codeError = false;
                            isPhoneVerified = true;
                            codeRequested = false; // 🔥 이거 중요
                          });

                          // 🔒 인증 성공 시 phone 입력 잠그고 싶으면 여기서 처리
                          FocusScope.of(context).unfocus();
                        } else {
                          setState(() {
                            codeError = true;
                          });
                          _shakeCtrl.forward(from: 0);
                        }
                      }
                    },
                    isError: codeError,
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
                          style: TextStyle(color: Colors.green, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                _errorText(phoneError),

                _label('주소 (선택)'),

                Row(
                  children: [
                    Expanded(
                      child: _input(
                        zipCtrl,
                        enabled: false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _searchAddress,
                        child: const Text('주소 검색'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _input(
                  addr1Ctrl,
                  enabled: false,
                ),
                const SizedBox(height: 8),
                _input(
                  addr2Ctrl,
                  focus: addr2Focus,
                ),


                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AccountSetupScreen()),
                    );
                  },
                  child: const Text('다음 (개발용)'),
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
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Row(
        children: [
          Text(text),
          if (required)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.circle, size: 6, color: Colors.red),
            ),
        ],
      ),
    );
  }

  Widget _input(
      TextEditingController ctrl, {
        FocusNode? focus,
        bool obscure = false,
        TextInputType keyboard = TextInputType.text,
        int? maxLength,
        List<TextInputFormatter>? formatters,
        ValueChanged<String>? onChanged,
        bool isError = false,
        bool enabled = true,
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
        onChanged: onChanged,
        inputFormatters: formatters,
        decoration: const InputDecoration(
          border: InputBorder.none,        // 🔥 핵심
          focusedBorder: InputBorder.none, // 🔥 핵심
          enabledBorder: InputBorder.none, // 🔥 핵심
          counterText: '',
        ),
      ),
    );
  }

  Widget _errorText(String? msg) {
    if (msg == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        msg,
        style: const TextStyle(color: Colors.red, fontSize: 12),
      ),
    );
  }
  bool _isSearchingAddress = false;
  Future<void> _searchAddress() async {
    if (_isSearchingAddress) return;
    _isSearchingAddress = true;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KpostalView(
          callback: (Kpostal result) {
            setState(() {
              zipCtrl.text = result.postCode;
              addr1Ctrl.text = result.address;
            });

            // ⭐ 주소 선택 직후 상세주소로 포커스 이동
            Future.delayed(const Duration(milliseconds: 100), () {
              FocusScope.of(context).requestFocus(addr2Focus);
            });
          },
        ),
      ),
    );

    _isSearchingAddress = false;
  }

}
