import 'package:flutter/material.dart';
import '../../../models/product_join_request.dart';
import '../../../services/flutter_api_service.dart';

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
      // 🔥 최종 동의 플래그 설정
      final finalRequest = widget.request.copyWith(
        finalAgree: true,
      );

      // API 호출
      await _apiService.joinAsGuest(finalRequest.toJson());

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
                  '가입 정보 최종 확인',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  '가입을 완료하기 전, 정보와 조건을 다시 한 번 확인해 주세요.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 24),

                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                // 상품 정보
                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                _buildSection(
                  '상품 정보',
                  [
                    _infoRow('상품명', req.productName),
                  ],
                ),

                const SizedBox(height: 16),

                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                // 가입 정보
                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                _buildSection(
                  '가입 정보',
                  [
                    _infoRow('가입 금액', '${_formatNumber(req.principalAmount ?? 0)}원'),
                    _infoRow('가입 기간', '${req.contractTerm}개월'),
                    _infoRow('가입일', _formatDate(req.startDate!)),
                    _infoRow('만기일', _formatDate(req.expectedEndDate!)),
                  ],
                ),

                const SizedBox(height: 16),

                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                // 금리 정보
                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                _buildSection(
                  '금리 정보',
                  [
                    _infoRow('기본 금리', '연 ${req.baseRate?.toStringAsFixed(2)}%'),
                    if ((req.pointBonusRate ?? 0) > 0)
                      _infoRow(
                        '포인트 보너스',
                        '+${req.pointBonusRate?.toStringAsFixed(2)}%',
                        valueColor: Colors.blue,
                      ),
                    if ((req.couponBonusRate ?? 0) > 0)
                      _infoRow(
                        '쿠폰 보너스',
                        '+${req.couponBonusRate?.toStringAsFixed(2)}%',
                        valueColor: Colors.red,
                      ),
                    const Divider(),
                    _infoRow(
                      '최종 적용 금리',
                      '연 ${req.applyRate?.toStringAsFixed(2)}%',
                      isBold: true,
                      valueColor: Colors.green,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                // 예상 수익
                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '예상 이자',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_formatNumber(_calculateInterest())}원',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '만기 수령액',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_formatNumber((req.principalAmount ?? 0) + _calculateInterest())}원',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                // 최종 동의
                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CheckboxListTile(
                    value: _finalAgree,
                    onChanged: (v) => setState(() => _finalAgree = v ?? false),
                    title: const Text(
                      '위 내용을 확인하였으며, 상품 가입에 동의합니다.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        '• 중도해지 시 불이익이 있을 수 있습니다.\n'
                            '• 예금자보호법에 따라 보호됩니다.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),

          // 하단 버튼
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
      String label,
      String value, {
        bool isBold = false,
        Color? valueColor,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor,
            ),
          ),
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
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
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
            '가입하기',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}