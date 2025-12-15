import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../model/product_join_request.dart';
import '../../../model/branch.dart';
import '../../../model/employee.dart';
import '../../../service/flutter_api_service.dart';
import 'join_step3_screen.dart';

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
    _apiService = FlutterApiService(widget.baseUrl);
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
      _amountCtrl.text = amount.toString();
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

  void _goNext() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 필수 항목을 입력해주세요.')),
      );
      return;
    }

    if (_selectedBranchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지점을 선택해주세요.')),
      );
      return;
    }

    if (_selectedEmpId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('담당자를 선택해주세요.')),
      );
      return;
    }

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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JoinStep3Screen(
          baseUrl: widget.baseUrl,
          request: updated,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('STEP 2/4 - 가입 정보 입력'),
      ),
      body: Column(
        children: [
          // 진행 바
          _buildProgressBar(),

          // 폼
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 상품명
                  Text(
                    widget.request.productName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  // 지점 선택
                  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  const Text(
                    '영업점 선택',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  _loadingBranches
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownButtonFormField<int>(
                    value: _selectedBranchId,
                    decoration: const InputDecoration(
                      labelText: '지점',
                      border: OutlineInputBorder(),
                    ),
                    items: _branches
                        .map((b) => DropdownMenuItem(
                      value: b.branchId,
                      child: Text(b.branchName),
                    ))
                        .toList(),
                    onChanged: (id) {
                      setState(() => _selectedBranchId = id);
                      if (id != null) {
                        _loadEmployees(id);
                      }
                    },
                    validator: (v) => v == null ? '지점을 선택하세요' : null,
                  ),

                  const SizedBox(height: 16),

                  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  // 직원 선택
                  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  _loadingEmployees
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownButtonFormField<int>(
                    value: _selectedEmpId,
                    decoration: const InputDecoration(
                      labelText: '담당자',
                      border: OutlineInputBorder(),
                    ),
                    items: _employees
                        .map((e) => DropdownMenuItem(
                      value: e.empId,
                      child: Text(e.empName),
                    ))
                        .toList(),
                    onChanged: (id) {
                      setState(() => _selectedEmpId = id);
                    },
                    validator: (v) => v == null ? '담당자를 선택하세요' : null,
                  ),

                  const SizedBox(height: 24),

                  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  // 계좌 비밀번호
                  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  const Text(
                    '계좌 비밀번호',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _pwCtrl,
                    obscureText: true,
                    maxLength: 4,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: '4자리 숫자 비밀번호',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return '비밀번호를 입력하세요';
                      }
                      if (v.length != 4) {
                        return '4자리 숫자를 입력하세요';
                      }
                      if (int.tryParse(v) == null) {
                        return '숫자만 입력 가능합니다';
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
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: '비밀번호 확인',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    validator: (v) {
                      if (v != _pwCtrl.text) {
                        return '비밀번호가 일치하지 않습니다';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  // 가입 금액
                  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  const Text(
                    '가입 금액',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('100만원'),
                        selected: _amountCtrl.text == '1000000',
                        onSelected: (_) => _selectAmount(1000000),
                      ),
                      ChoiceChip(
                        label: const Text('500만원'),
                        selected: _amountCtrl.text == '5000000',
                        onSelected: (_) => _selectAmount(5000000),
                      ),
                      ChoiceChip(
                        label: const Text('1,000만원'),
                        selected: _amountCtrl.text == '10000000',
                        onSelected: (_) => _selectAmount(10000000),
                      ),
                      ChoiceChip(
                        label: const Text('3,000만원'),
                        selected: _amountCtrl.text == '30000000',
                        onSelected: (_) => _selectAmount(30000000),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: '직접 입력 (원)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final val = int.tryParse(v?.replaceAll(',', '') ?? '');
                      if (val == null || val <= 0) {
                        return '가입 금액을 입력해주세요';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  // 가입 기간
                  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  const Text(
                    '가입 기간',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [3, 6, 12, 24, 36].map((m) {
                      return ChoiceChip(
                        label: Text('${m}개월'),
                        selected: _termCtrl.text == '$m',
                        onSelected: (_) => _selectTerm(m),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _termCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: '직접 입력 (개월)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final val = int.tryParse(v ?? '');
                      if (val == null || val <= 0) {
                        return '가입 기간을 입력해주세요';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  // 알림 설정
                  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  const Text(
                    '알림 설정 (선택)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  SwitchListTile(
                    title: const Text('문자(SMS) 알림 받기'),
                    value: _smsNotify,
                    onChanged: (v) => setState(() => _smsNotify = v),
                    contentPadding: EdgeInsets.zero,
                  ),

                  if (_smsNotify) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _hpCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: '휴대폰 번호 (010-1234-5678)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (_smsNotify && (v == null || v.isEmpty)) {
                          return '휴대폰 번호를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 8),

                  SwitchListTile(
                    title: const Text('이메일 알림 받기'),
                    value: _emailNotify,
                    onChanged: (v) => setState(() => _emailNotify = v),
                    contentPadding: EdgeInsets.zero,
                  ),

                  if (_emailNotify) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: '이메일 주소',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (_emailNotify && (v == null || v.isEmpty)) {
                          return '이메일 주소를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // 하단 버튼
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStep(1, true),
          _buildLine(true),
          _buildStep(2, true),
          _buildLine(false),
          _buildStep(3, false),
          _buildLine(false),
          _buildStep(4, false),
        ],
      ),
    );
  }

  Widget _buildStep(int step, bool active) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? Theme.of(context).primaryColor : Colors.grey[300],
      ),
      child: Center(
        child: Text(
          '$step',
          style: TextStyle(
            color: active ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLine(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        color: active ? Theme.of(context).primaryColor : Colors.grey[300],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 56),
                ),
                child: const Text('이전'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _goNext,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 56),
                ),
                child: const Text('다음 (STEP 3)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}