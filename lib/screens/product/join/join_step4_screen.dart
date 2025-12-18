import 'package:flutter/material.dart';
import '../../../models/product_join_request.dart';
import '../../../services/flutter_api_service.dart';
import '../../../services/token_storage_service.dart';
import '../../member/login_screen.dart';

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
  bool _finalAgree = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _apiService = FlutterApiService(baseUrl: widget.baseUrl);

    // ✅ 로그인 체크
    _checkLogin();
  }

  /// ✅ 로그인 체크
  Future<void> _checkLogin() async {
    final token = await TokenStorageService().readToken();

    if (token == null) {
      // ❌ 로그인 안 됨
      if (!mounted) return;

      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock, color: Colors.orange, size: 28),
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

  int _calculateInterest() {
    final amount = widget.request.principalAmount ?? 0;
    final months = widget.request.contractTerm ?? 0;
    final rate = widget.request.applyRate ?? 0.0;

    // 단리 계산
    final interest = (amount * (rate / 100) * (months / 12)).toInt();
    return interest;
  }

  Future<void> _submit() async {
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

      // 🔥 최종 동의 플래그 설정
      final finalRequest = widget.request.copyWith(
        finalAgree: true,
      );

      // ✅ API 호출 (joinProduct로 변경!)
      print(await _apiService.joinProduct(finalRequest.toJson()));  // ✅ 수정!

      print('[DEBUG] ✅ 가입 성공!');

      if (!mounted) return;

      // 성공 다이얼로그
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 12),
              Text('가입 완료'),
            ],
          ),
          content: const Text('상품 가입이 정상적으로 완료되었습니다.'),
          actions: [
            TextButton(
              onPressed: () {
                // 홈으로 이동 (모든 스택 제거)
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

      // 실패 다이얼로그
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 32),
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

  @override
  Widget build(BuildContext context) {
    final req = widget.request;

    return Scaffold(
      appBar: AppBar(
        title: const Text('STEP 4/4 - 최종 확인'),
      ),
      body: Column(
        children: [
          // 진행 바
          _buildProgressBar(),

          // 내용
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 타이틀
                const Text(
                  '가입 정보를 확인해주세요',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                // 상품 정보
                _buildSection('상품 정보', [
                  _buildInfoRow('상품명', req.productName),
                ]),

                const SizedBox(height: 16),

                // 가입 정보
                _buildSection('가입 정보', [
                  _buildInfoRow('가입 금액', '${_formatNumber(req.principalAmount ?? 0)}원'),
                  _buildInfoRow('가입 기간', '${req.contractTerm ?? 0}개월'),
                  _buildInfoRow('적용 금리', '${(req.applyRate ?? 0.0).toStringAsFixed(2)}%'),
                ]),

                const SizedBox(height: 16),

                // 예상 수익
                _buildSection('예상 수익', [
                  _buildInfoRow('가입 금액', '${_formatNumber(req.principalAmount ?? 0)}원'),
                  _buildInfoRow(
                    '예상 이자',
                    '${_formatNumber(_calculateInterest())}원',
                    valueColor: Colors.blue,
                  ),
                  _buildInfoRow(
                    '만기 금액',
                    '${_formatNumber((req.principalAmount ?? 0) + _calculateInterest())}원',
                    valueColor: Colors.red,
                    valueBold: true,
                  ),
                ]),

                const SizedBox(height: 24),

                // 최종 동의
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CheckboxListTile(
                    value: _finalAgree,
                    onChanged: (v) => setState(() => _finalAgree = v ?? false),
                    title: const Text(
                      '위 내용을 확인했으며, 상품 가입에 동의합니다.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),

          // 하단 버튼
          _buildBottomButton(),
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
          _buildLine(true),
          _buildStep(3, true),
          _buildLine(true),
          _buildStep(4, true),
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

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Divider(),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      String label,
      String value, {
        Color? valueColor,
        bool valueBold = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
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
}