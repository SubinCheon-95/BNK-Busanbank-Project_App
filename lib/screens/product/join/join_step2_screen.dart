import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/product_join_request.dart';
import '../../../models/branch.dart';
import '../../../models/employee.dart';
import '../../../services/flutter_api_service.dart';
import 'join_step3_screen.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import 'package:tkbank/theme/app_colors.dart';

/// 🔥 STEP 2: 지점/직원 선택, 금액/기간 입력
///
/// 기능:
/// - 지점 목록 조회
/// - 지점 선택 시 직원 자동 조회
/// - 계좌 비밀번호 4자리 입력 및 확인
/// - 가입 금액 선택 (ChoiceChip + 직접 입력)
/// - 가입 기간 선택 (ChoiceChip + 직접 입력)
/// - 알림 설정 (SMS/Email)

class JoinStep2Screen extends StatefulWidget {
  final String baseUrl;
  final ProductJoinRequest request;

  const JoinStep2Screen({
    super.key,
    required this.baseUrl,
    required this.request,
  });

  @override
  State<JoinStep2Screen> createState() => _JoinStep2ScreenState();
}

class _JoinStep2ScreenState extends State<JoinStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  late FlutterApiService _apiService;

  // 지점/직원
  List<Branch> _branches = [];
  List<Employee> _employees = [];
  int? _selectedBranchId;
  int? _selectedEmpId;
  bool _loadingBranches = true;
  bool _loadingEmployees = false;

  // 입력 필드
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _termCtrl = TextEditingController();
  final TextEditingController _pwCtrl = TextEditingController();
  final TextEditingController _pwConfirmCtrl = TextEditingController();
  final TextEditingController _hpCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();

  // 알림 설정
  bool _smsNotify = false;
  bool _emailNotify = false;

  @override
  void initState() {
    super.initState();
    _apiService = FlutterApiService(baseUrl: widget.baseUrl);

    // 지점 목록 로드
    _loadBranches();

    // 기존 값 복원
    final req = widget.request;
    if (req.principalAmount != null) {
      _amountCtrl.text = req.principalAmount.toString();
    }
    if (req.contractTerm != null) {
      _termCtrl.text = req.contractTerm.toString();
    }
    if (req.accountPassword != null) {
      _pwCtrl.text = req.accountPassword!;
      _pwConfirmCtrl.text = req.accountPassword!;
    }
    if (req.notificationHp != null) {
      _hpCtrl.text = req.notificationHp!;
    }
    if (req.notificationEmailAddr != null) {
      _emailCtrl.text = req.notificationEmailAddr!;
    }
    _smsNotify = req.notificationSms == 'Y';
    _emailNotify = req.notificationEmail == 'Y';

    // 기존 선택값 복원
    _selectedBranchId = req.branchId;
    _selectedEmpId = req.empId;

    // 지점이 이미 선택되어 있으면 직원 로드
    if (_selectedBranchId != null) {
      _loadEmployees(_selectedBranchId!);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _termCtrl.dispose();
    _pwCtrl.dispose();
    _pwConfirmCtrl.dispose();
    _hpCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBranches() async {
    try {
      final branches = await _apiService.getBranches();
      setState(() {
        _branches = branches;
        _loadingBranches = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingBranches = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('지점 조회 실패: $e')),
        );
      }
    }
  }

  Future<void> _loadEmployees(int branchId) async {
    setState(() => _loadingEmployees = true);
    try {
      final employees = await _apiService.getEmployees(branchId);
      setState(() {
        _employees = employees;
        _selectedEmpId = null; // 초기화
        _loadingEmployees = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingEmployees = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('직원 조회 실패: $e')),
        );
      }
    }
  }

  void _selectAmount(int amount) {
    setState(() {
      _amountCtrl.text = _formatNumber(amount.toString());
    });
  }

  void _selectTerm(int months) {
    setState(() {
      _termCtrl.text = months.toString();
    });
  }

  DateTime _calculateEndDate() {
    final months = int.tryParse(_termCtrl.text) ?? 0;
    final today = DateTime.now();
    return DateTime(today.year, today.month + months, today.day);
  }

  // 버튼 활성화 조건 함수 추가 (26/01/04_수빈)
  bool _canGoNext() {
    // 영업점 / 담당자
    if (_selectedBranchId == null) return false;
    if (_selectedEmpId == null) return false;

    // 계좌 비밀번호
    if (_pwCtrl.text.length != 4) return false;
    if (_pwCtrl.text != _pwConfirmCtrl.text) return false;

    // 가입 금액
    final amount =
        int.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    if (amount <= 0) return false;

    // 가입 기간
    final term = int.tryParse(_termCtrl.text) ?? 0;
    if (term <= 0) return false;

    return true;
  }

  void _goNext() async {  // async 추가
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('입력 항목을 확인해주세요.')),
      );
      return;
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 계좌 비밀번호 검증 추가
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    final accountPassword = _pwCtrl.text;

    if (accountPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('계좌 비밀번호를 입력해주세요.')),
      );
      return;
    }

    // AuthProvider에서 userNo 가져오기
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userNo = authProvider.userNo;

    if (userNo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    // 로딩 표시
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 계좌 비밀번호 검증 API 호출
      print('[DEBUG] 계좌 비밀번호 검증 시작 - userNo: $userNo');

      final response = await _apiService.verifyAccountPassword(
        userNo: userNo,
        accountPassword: accountPassword,
      );

      print('[DEBUG] 계좌 비밀번호 검증 결과: $response');

      // 로딩 닫기
      if (mounted) Navigator.pop(context);

      if (response['success'] != true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? '계좌 비밀번호가 일치하지 않습니다.')),
          );
        }
        return;
      }

      // 검증 성공 → STEP 3으로 이동
      print('[DEBUG] ✅ 계좌 비밀번호 검증 성공!');

    } catch (e) {
      // 로딩 닫기
      if (mounted) Navigator.pop(context);

      print('[ERROR] 계좌 비밀번호 검증 실패: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('계좌 비밀번호 검증 실패: $e')),
        );
      }
      return;
    }
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    final amount = int.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    final term = int.tryParse(_termCtrl.text) ?? 0;

    final updated = widget.request.copyWith(
      branchId: _selectedBranchId,
      empId: _selectedEmpId,
      accountPassword: _pwCtrl.text,
      principalAmount: amount,
      contractTerm: term,
      startDate: DateTime.now(),
      expectedEndDate: _calculateEndDate(),
      notificationSms: _smsNotify ? 'Y' : 'N',
      notificationEmail: _emailNotify ? 'Y' : 'N',
      notificationHp: _hpCtrl.text,
      notificationEmailAddr: _emailCtrl.text,
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JoinStep3Screen(
            request: updated,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.gray1,

      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),

              // 타이틀
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '가입 정보 입력',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    _buildMiniStepIndicator(currentStep: 2),
                  ],
                ),
              ),

              // 상품명 타이틀
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Text(
                  widget.request.productName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray5,
                  ),
                ),
              ),

              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 20),
                    children: [

                      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                      // 지점 선택
                      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                      _sectionCard(
                        title: Row(
                          children: const [
                            Text(
                              '영업점 / 담당자 선택',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.black,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '*',
                              style: TextStyle(
                                color: AppColors.red,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _loadingBranches
                              ? const Center(child: CircularProgressIndicator())
                              : DropdownButtonFormField<int>(
                              value: _selectedBranchId,
                              decoration: _inputDecoration(label: '지점'),

                              isDense: true,
                              icon: const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.gray4,
                                  size: 24,
                                ),
                              ),
                              dropdownColor: AppColors.white,

                              items: _branches
                                  .map((b) => DropdownMenuItem(
                                value: b.branchId,
                                child: Text(b.branchName),
                              ))
                                  .toList(),
                              onChanged: (id) {
                                setState(() => _selectedBranchId = id);
                                if (id != null) _loadEmployees(id);
                              },
                              validator: (v) => v == null ? '지점을 선택하세요' : null,
                            ),

                            const SizedBox(height: 12),

                            _loadingEmployees
                              ? const Center(child: CircularProgressIndicator())
                              : DropdownButtonFormField<int>(
                              value: _selectedEmpId,
                              decoration: _inputDecoration(label: '담당자'),

                              isDense: true,
                              icon: const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.gray4,
                                  size: 24,
                                ),
                              ),
                              dropdownColor: AppColors.white,

                              items: _employees
                                  .map((e) => DropdownMenuItem(
                                value: e.empId,
                                child: Text(e.empName),
                              ))
                                  .toList(),
                              onChanged: (id) => setState(() => _selectedEmpId = id),
                              validator: (v) => v == null ? '담당자를 선택하세요' : null,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                      // 계좌 비밀번호
                      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                      _sectionCard(
                        title: Row(
                          children: const [
                            Text(
                              '계좌 비밀번호',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '*',
                              style: TextStyle(
                                color: AppColors.red,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                          TextFormField(
                            controller: _pwCtrl,
                            obscureText: true,
                            maxLength: 4,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: _inputDecoration(label: '4자리 숫자 비밀번호'),

                            onChanged: (_) => setState(() {}),

                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return '비밀번호를 입력하세요';
                              }
                              if (v.length != 4) {
                                return '4자리 숫자를 입력하세요';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _pwConfirmCtrl,
                            obscureText: true,
                            maxLength: 4,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: _inputDecoration(label: '비밀번호 확인'),

                            onChanged: (_) => setState(() {}),

                            validator: (v) {
                              if (v != _pwCtrl.text) {
                                return '비밀번호가 일치하지 않습니다';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                      // 가입 금액
                      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                      _sectionCard(
                        title: Row(
                          children: const [
                            Text(
                              '가입 금액',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '*',
                              style: TextStyle(
                                color: AppColors.red,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _amountChip('100만원', 1000000),
                                _amountChip('500만원', 5000000),
                                _amountChip('1,000만원', 10000000),
                                _amountChip('3,000만원', 30000000),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _amountCtrl,

                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],

                              decoration: InputDecoration(
                                labelText: '직접 입력(원)',
                                suffixText: '원',

                                // 기본 라벨 색
                                labelStyle: const TextStyle(
                                  color: AppColors.gray5,
                                  fontWeight: FontWeight.w500,
                                ),

                                // 활성화되거나 위로 뜰 때 라벨 색
                                floatingLabelStyle: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),

                                // 기본 테두리
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppColors.gray4,
                                    width: 1,
                                  ),
                                ),

                                // 활성화 시
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                ),

                                // 에러
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppColors.red,
                                    width: 1.5,
                                  ),
                                ),

                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppColors.red,
                                    width: 2,
                                  ),
                                ),
                              ),

                              onChanged: (value) {
                                final formatted = _formatNumber(value);
                                _amountCtrl.value = TextEditingValue(
                                  text: formatted,
                                  selection: TextSelection.collapsed(offset: formatted.length),
                                );

                                setState(() {});
                              },

                              validator: (v) {
                                final val = int.tryParse(v?.replaceAll(',', '') ?? '');
                                if (val == null || val <= 0) {
                                  return '가입 금액을 입력해주세요';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                      // 가입 기간
                      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                      _sectionCard(
                        title: Row(
                          children: const [
                            Text(
                              '가입 기간',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '*',
                              style: TextStyle(
                                color: AppColors.red,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [3, 6, 12, 24, 36]
                                  .map((m) => _termChip(m))
                                  .toList(),
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _termCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],

                              decoration: InputDecoration(
                                labelText: '직접 입력(개월)',
                                suffixText: '개월',

                                // 기본 라벨 색
                                labelStyle: const TextStyle(
                                  color: AppColors.gray5,
                                  fontWeight: FontWeight.w500,
                                ),

                                // 활성화되거나 위로 뜰 때 라벨 색
                                floatingLabelStyle: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),

                                // 기본 테두리
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppColors.gray4,
                                    width: 1,
                                  ),
                                ),

                                // 활성화 시
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                ),

                                // 에러
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppColors.red,
                                    width: 1.5,
                                  ),
                                ),

                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppColors.red,
                                    width: 2,
                                  ),
                                ),
                              ),

                              onChanged: (_) => setState(() {}),

                              validator: (v) {
                                final val = int.tryParse(v ?? '');
                                if (val == null || val <= 0) {
                                  return '가입 기간을 입력해주세요';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                      // 알림 설정
                      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                      _sectionCard(
                        title: Row(
                          children: const [
                            Text(
                              '알림 설정 (선택)',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: const Text('문자(SMS) 알림'),
                              value: _smsNotify,
                              onChanged: (v) => setState(() => _smsNotify = v),

                              activeColor: AppColors.white,
                              activeTrackColor: AppColors.primary,

                              contentPadding: EdgeInsets.zero,
                            ),
                            if (_smsNotify) ...[
                              const SizedBox(height: 8),

                              TextFormField(
                                controller: _hpCtrl,
                                keyboardType: TextInputType.phone,

                                decoration: InputDecoration(
                                  labelText: '휴대폰 번호',

                                  // 기본 라벨
                                  labelStyle: const TextStyle(
                                    color: AppColors.gray5,
                                    fontWeight: FontWeight.w500,
                                  ),

                                  // 포커스 라벨
                                  floatingLabelStyle: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),

                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppColors.gray4,
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppColors.red,
                                      width: 1.5,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppColors.red,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 8),

                            SwitchListTile(
                              title: const Text('이메일 알림'),
                              value: _emailNotify,
                              onChanged: (v) => setState(() => _emailNotify = v),

                              activeColor: AppColors.white,
                              activeTrackColor: AppColors.primary,

                              contentPadding: EdgeInsets.zero,
                            ),

                            if (_emailNotify) ...[
                              const SizedBox(height: 8),

                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,

                                decoration: InputDecoration(
                                  labelText: '이메일 주소',

                                  labelStyle: const TextStyle(
                                    color: AppColors.gray5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  floatingLabelStyle: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),

                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: AppColors.gray4),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.chevron_left, size: 34),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),

      bottomNavigationBar: _buildBottomCTA(h),
    );
  }

  // ==============================
  // 숫자 포맷 유틸
  // ==============================
    String _formatNumber(String value) {
      if (value.isEmpty) return '';

      final number = int.parse(value.replaceAll(',', ''));
      return number.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
            (match) => ',',
      );
    }

  // ==============================
  // 공통 섹션 카드
  // ==============================
  Widget _sectionCard({
    required Widget title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  Widget _amountChip(String label, int value) {
    final currentAmount =
    int.tryParse(_amountCtrl.text.replaceAll(',', ''));

    final bool selected = currentAmount == value;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: selected ? AppColors.white : AppColors.primary,
        ),
      ),
      selected: selected,

      checkmarkColor: AppColors.white,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.primary.withOpacity(0.08),

      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected
              ? AppColors.primary
              : AppColors.primary.withOpacity(0.3),
        ),
      ),

      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),

      onSelected: (_) => _selectAmount(value),
    );
  }

  Widget _termChip(int month) {
    final bool selected = _termCtrl.text == '$month';

    return ChoiceChip(
      label: Text(
        '${month}개월',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: selected ? AppColors.white : AppColors.primary,
        ),
      ),
      selected: selected,

      checkmarkColor: AppColors.white,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.primary.withOpacity(0.08),

      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected
              ? AppColors.primary
              : AppColors.primary.withOpacity(0.3),
        ),
      ),

      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),

      onSelected: (_) => _selectTerm(month),
    );
  }

  Widget _buildMiniStepIndicator({required int currentStep}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$currentStep / 4',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }

  // 점선 Divider
  Widget _dashedDivider() {
    return LayoutBuilder(
      builder: (_, constraints) {
        return Row(
          children: List.generate(
            (constraints.maxWidth / 6).floor(),
                (index) =>
                Expanded(
                  child: Container(
                    height: 1,
                    color:
                    index.isEven ? AppColors.gray4 : Colors.transparent,
                  ),
                ),
          ),
        );
      },
    );
  }

  Widget _buildBottomCTA(double h) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: h * 0.09,
          child: ElevatedButton(
            onPressed: _canGoNext() ? _goNext : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              '다음',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required String label,
  String? suffix,
}) {
  return InputDecoration(
    labelText: label,
    suffixText: suffix,

    labelStyle: const TextStyle(
      color: AppColors.gray5,
      fontWeight: FontWeight.w500,
    ),
    floatingLabelStyle: const TextStyle(
      color: AppColors.primary,
      fontWeight: FontWeight.w700,
    ),

    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(
        color: AppColors.gray4,
        width: 1,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(
        color: AppColors.primary,
        width: 2,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(
        color: AppColors.red,
        width: 1.5,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(
        color: AppColors.red,
        width: 2,
      ),
    ),
  );
}
