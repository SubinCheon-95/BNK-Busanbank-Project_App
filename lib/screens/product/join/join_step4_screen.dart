import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tkbank/services/product_push_service.dart';
import '../../../models/product_join_request.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/flutter_api_service.dart';
import '../../../services/token_storage_service.dart';
import '../../member/login_screen.dart';
import '../../../models/product_terms.dart';
import 'package:tkbank/theme/app_colors.dart';

/// 🔥 STEP 4: 최종 확인 및 가입
///
/// 기능:
/// - 모든 가입 정보 최종 표시
/// - 최종 동의 체크박스
/// - 가입 API 호출
/// - 성공 시 홈으로 이동

class JoinStep4Screen extends StatefulWidget {
  final String baseUrl;
  final ProductJoinRequest request;

  const JoinStep4Screen({
    super.key,
    required this.baseUrl,
    required this.request,
  });

  @override
  State<JoinStep4Screen> createState() => _JoinStep4ScreenState();
}

class _JoinStep4ScreenState extends State<JoinStep4Screen> {
  late FlutterApiService _apiService;
  final ProductPushService _productPushService = ProductPushService();  //가입 완료 푸시 알림 - 작성자: 윤종인 2025.12.31

  bool _finalAgree = false;
  bool _loading = false;

  // 마지막 최종 약관 추가!
  List<ProductTerms> _finalTerms = [];
  final Map<int, bool> _agreedFinal = {};
  bool _loadingTerms = true;

  @override
  void initState() {
    super.initState();
    _apiService = FlutterApiService(baseUrl: widget.baseUrl);

    // 로그인 체크
    _checkLogin();
    // 마지막 최종약관
    _loadFinalTerms();  // 마지막 최종약관
  }

  // 로그인 체크
  Future<void> _checkLogin() async {
    final token = await TokenStorageService().readToken();

    if (token == null) {
      // 로그인 안 됨
      if (!mounted) return;

      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock, color: AppColors.red, size: 28),
              SizedBox(width: 12),
              Text('로그인 필요'),
            ],
          ),
          content: const Text('상품 가입을 완료하려면 로그인이 필요합니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('로그인하기'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('취소'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      if (result == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        Navigator.pop(context);
      }
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 3. displayOrder 9,10,11 약관 로드 메서드 추가
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> _loadFinalTerms() async {
    try {
      print('📋 STEP4 약관 조회 시작...');

      final allTerms = await _apiService.getTerms(widget.request.productNo!);

      // displayOrder 9, 10, 11만 필터링
      final step4Terms = allTerms
          .where((term) =>
      term.displayOrder == 9 ||
          term.displayOrder == 10 ||
          term.displayOrder == 11)
          .toList();

      print('📋 STEP4 약관 조회 완료: ${step4Terms.length}개');
      for (var term in step4Terms) {
        print('   - displayOrder: ${term.displayOrder}, title: ${term.termTitle}');
      }

      setState(() {
        _finalTerms = step4Terms;
        for (final term in step4Terms) {
          _agreedFinal[term.termId] = false;
        }
        _loadingTerms = false;
      });
    } catch (e) {
      print('❌ STEP4 약관 조회 실패: $e');
      setState(() => _loadingTerms = false);
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 4. 필수 약관 체크 메서드 추가
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  bool _areRequiredTermsAgreed() {
    if (_finalTerms.isEmpty) return true;

    final required = _finalTerms.where((t) => t.isRequired);
    return required.every((t) => _agreedFinal[t.termId] == true);
  }

  bool _canSubmit() {
    return _areRequiredTermsAgreed() && _finalAgree && !_loading;
  }

  int _calculateInterest() {
    final amount = widget.request.principalAmount ?? 0;
    final months = widget.request.contractTerm ?? 0;
    final rate = widget.request.applyRate ?? 0.0;

    // 단리 계산
    final interest = (amount * (rate / 100) * (months / 12)).toInt();
    return interest;
  }

  Future<void> _submit() async {
    // 1. 필수 약관 체크
    if (!_areRequiredTermsAgreed()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필수 서류를 모두 확인해주세요.')),
      );
      return;
    }

    // 2. 최종 동의 체크
    if (!_finalAgree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최종 동의를 체크해주세요.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      print('[DEBUG] ===== 최종 가입 요청 =====');
      print('[DEBUG] productNo: ${widget.request.productNo}');
      print('[DEBUG] productName: ${widget.request.productName}');
      print('[DEBUG] principalAmount: ${widget.request.principalAmount}');
      print('[DEBUG] contractTerm: ${widget.request.contractTerm}');
      print('[DEBUG] applyRate: ${widget.request.applyRate}');
      print('[DEBUG] branchId: ${widget.request.branchId}');
      print('[DEBUG] empId: ${widget.request.empId}');
      print('[DEBUG] usedPoints: ${widget.request.usedPoints}');
      print('[DEBUG] selectedCouponId: ${widget.request.selectedCouponId}');

      final finalRequest = widget.request.copyWith(
        finalAgree: true,
      );

      print(await _apiService.joinProduct(finalRequest.toJson()));
      print('[DEBUG] 가입 성공!');

      if (!mounted) return;

      //가입 완료 푸시 알림 - 작성자: 윤종인 2025.12.31
      await _joinProductNotification(widget.request);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.primary, size: 32),
              SizedBox(width: 12),
              Text('가입 완료'),
            ],
          ),
          content: const Text('상품 가입이 정상적으로 완료되었습니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('[ERROR] 가입 실패: $e');

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: AppColors.red, size: 32),
              SizedBox(width: 12),
              Text('가입 실패'),
            ],
          ),
          content: Text('상품 가입에 실패했습니다.\n\n오류: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _joinProductNotification(ProductJoinRequest request) async { //가입 완료 푸시 알림 - 작성자: 윤종인 2025.12.31
    try {
      final authProvider = context.read<AuthProvider>();
      final userNo = authProvider.userNo;
      print('userNo 테스트: $userNo');

      if (userNo == null) {
        print('사용자 정보가 없습니다.');
        return;
      }

      print('[PUSH] 알림 전송 시작 (productName: ${request.productName})');

      await _productPushService.productPush(
          request.productName,
          userNo.toString(),
          needsAuth: true
      );
      print('[PUSH] 알림 전송 성공');
    } catch (e) {
      print('[PUSH] 알림 전송 실패: $e');
    }
  }

  // 본문 콘텐츠 UI 수정 (26/01/04_수빈)
  @override
  Widget build(BuildContext context) {
    final req = widget.request;

    return Scaffold(
      backgroundColor: AppColors.gray1,

      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),

              // 타이틀 + 스텝
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '최종 가입 확인',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    _buildMiniStepIndicator(currentStep: 4),
                  ],
                ),
              ),

              // 본문 (26/01/04_수빈)
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    // 타이틀
                    const Text(
                      '가입 정보를 확인해주세요',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 상품 정보 (26/01/04_수빈)
                    _sectionCard(
                      title: '상품 정보',
                      child: _buildProductInfoCard(),
                    ),

                    const SizedBox(height: 20),

                    // 가입 정보 (26/01/04_수빈)
                    _sectionCard(
                      title: '가입 정보',
                      child: _buildJoinSummaryCard(),
                    ),

                    const SizedBox(height: 20),

                    // 예상 수익 (26/01/04_수빈)
                    _sectionCard(
                      title: '예상 수익',
                      child: _buildExpectedProfitCard(),
                    ),

                    const SizedBox(height: 20),

                    // 필수 확인 서류 수정 (26/01/04_수빈)
                    if (_finalTerms.isNotEmpty) ...[
                      _buildFinalTermsCard(),
                      const SizedBox(height: 20),
                    ],

                    // 최종 동의
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: CheckboxListTile(
                        value: _finalAgree,
                        onChanged: (v) => setState(() => _finalAgree = v ?? false),

                        activeColor: AppColors.primary, // 체크 시 배경
                        checkColor: Colors.white,       // 체크 표시
                        side: const BorderSide(         // 미체크 테두리
                          color: AppColors.gray4,
                          width: 1.5,
                        ),

                        title: const Text(
                          '본인은 위 내용을 충분히 확인하였으며, \n상품 가입에 동의합니다.',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.black),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),

                    const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),

            // 뒤로가기 버튼
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

      // 하단 CTA
      bottomNavigationBar: _buildBottomCTA(context),
    );
  }

  // 상품 정보 카드 (26/01/04_수빈)
  Widget _buildProductInfoCard() {
    final req = widget.request;

    return Column(
      children: [
        _rateRow('상품명', req.productName ?? ''),
      ],
    );
  }

  // 가입 정보 카드 (26/01/04_수빈)
  Widget _buildJoinSummaryCard() {
    final req = widget.request;

    return Column(
      children: [
        _rateRow('가입 금액', '${_formatNumber(req.principalAmount ?? 0)}원'),
        const SizedBox(height: 10),
        _rateRow('가입 기간', '${req.contractTerm ?? 0}개월'),
        const SizedBox(height: 10),
        _rateRow(
          '적용 금리',
          '${(req.applyRate ?? 0.0).toStringAsFixed(2)}%',
          valueColor: AppColors.primary,
        ),
      ],
    );
  }

  // 예상 수익 카드 (26/01/04_수빈)
  Widget _buildExpectedProfitCard() {
    final principal = widget.request.principalAmount ?? 0;
    final term = widget.request.contractTerm ?? 0;
    final rate = widget.request.applyRate ?? 0.0;

    final expectedProfit = _calculateInterest();
    final maturity = principal + expectedProfit;

    return Column(
      children: [
        _rateRow('가입 금액', '${_formatNumber(principal)}원'),
        const SizedBox(height: 10),
        _rateRow('가입 기간', '$term개월'),
        const SizedBox(height: 10),
        _rateRow('적용 금리', '${rate.toStringAsFixed(2)}%'),
        const SizedBox(height: 10),
        _rateRow(
          '예상 이자',
          '${_formatNumber(expectedProfit)}원',
          valueColor: AppColors.primary,
        ),
        const SizedBox(height: 14),
        _dashedDivider(),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '만기 금액',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.black,
              ),
            ),
            Text(
              '${_formatNumber(maturity)}원',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinalTermsCard() {
    return _sectionCard(
      title: '필수 확인 서류',
      child: Column(
        children: _finalTerms
            .asMap()
            .entries
            .map((entry) {
          final index = entry.key;
          final term = entry.value;

          return Column(
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _agreedFinal[term.termId] ?? false,
                    onChanged: (v) {
                      setState(() {
                        _agreedFinal[term.termId] = v ?? false;
                      });
                    },

                    activeColor: AppColors.primary,   // 체크 시 배경색
                    checkColor: AppColors.white,      // 체크 아이콘 색
                    side: const BorderSide(           // 미체크 테두리
                      color: AppColors.gray4,
                      width: 1.5,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // 필수 / 선택 배지
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: term.isRequired
                          ? AppColors.red
                          : AppColors.gray4,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      term.isRequired ? '필수' : '선택',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // 약관 제목
                  Expanded(
                    child: Text(
                      term.termTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // 약관 상세 보기
                  IconButton(
                    icon: const Icon(
                      Icons.description_outlined,
                      size: 22,
                    ),
                    onPressed: () => _showTermDetail(term),
                  ),
                ],
              ),

              if (index != _finalTerms.length - 1) ...[
                const SizedBox(height: 15),
                _dashedDivider(),
                const SizedBox(height: 15),
              ],
            ],
          );
        }).toList(),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 6. 약관 상세 보기 메서드 추가
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  void _showTermDetail(ProductTerms term) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          term.termTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: controller,
                      child: Text(
                        term.termContent.isNotEmpty
                            ? term.termContent
                            : '약관 내용이 없습니다.',
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _rateRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.gray5,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: valueColor ?? AppColors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
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
        child: ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
          ),
          child: _loading
              ? const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : const Text(
            '가입 완료',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }

  // 공통 섹션 카드 추가 (26/01/04_수빈)
  Widget _sectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  // 단계별 Step 표시 추가 (26/01/04_수빈)
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

  // 점선 Divider 추가 (26/01/04_수빈)
  Widget _dashedDivider() {
    return LayoutBuilder(
      builder: (_, constraints) {
        return Row(
          children: List.generate(
            (constraints.maxWidth / 6).floor(),
                (index) => Expanded(
              child: Container(
                height: 1,
                color: index.isEven ? AppColors.gray4 : Colors.transparent,
              ),
            ),
          ),
        );
      },
    );
  }

  // 입력창/선택창 공용 UI 추가 (26/01/04_수빈)
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

  // 다음 버튼 추가 (26/01/04_수빈)
  Widget _buildBottomCTA(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    bool _canSubmit() {
      return _areRequiredTermsAgreed() && _finalAgree && !_loading;
    }

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
            onPressed: _canSubmit() ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.gray4.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: _loading
                ? const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Text(
              '가입 완료',
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