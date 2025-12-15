import 'package:flutter/material.dart';
import '../../../models/product_join_request.dart';
import '../../../models/product_terms.dart';
import '../../../services/product_join_service.dart';
import 'join_step2_screen.dart';

/// 🔥 STEP 1: 약관 동의
///
/// 기능:
/// - DB에서 약관 조회
/// - 필수/선택 약관 구분
/// - 전체 동의 토글
/// - 약관 상세 보기

class JoinStep1Screen extends StatefulWidget {
  final String baseUrl;
  final ProductJoinRequest request;

  const JoinStep1Screen({
    super.key,
    required this.baseUrl,
    required this.request,
  });

  @override
  State<JoinStep1Screen> createState() => _JoinStep1ScreenState();
}

class _JoinStep1ScreenState extends State<JoinStep1Screen> {
  late ProductJoinService _joinService;

  List<ProductTerms> _terms = [];
  final Map<int, bool> _agreed = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _joinService = ProductJoinService(widget.baseUrl);
    _loadTerms();
  }

  Future<void> _loadTerms() async {
    try {
      final terms = await _joinService.getTerms(widget.request.productNo!);

      // ✅ 디버깅 로그 추가!
      print('📋 약관 조회 완료: ${terms.length}개');
      for (var term in terms) {
        print('   - termsId: ${term.termsId}');
        print('   - termsTitle: ${term.termsTitle}');
        print('   - termsContent 길이: ${term.termsContent.length}');
        print('   - isRequired: ${term.isRequired}');
      }

      setState(() {
        _terms = terms;
        for (final term in terms) {
          _agreed[term.termsId] = false;
        }
        _loading = false;
      });
    } catch (e) {
      print('❌ 약관 조회 실패: $e');
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('약관 조회 실패: $e')),
        );
      }
    }
  }

  bool get _allAgreed {
    if (_terms.isEmpty) return false;
    return _terms.every((t) => _agreed[t.termsId] == true);
  }

  bool _areRequiredTermsAgreed() {
    final required = _terms.where((t) => t.isRequired);
    return required.every((t) => _agreed[t.termsId] == true);
  }

  void _toggleAll(bool? value) {
    setState(() {
      for (final term in _terms) {
        _agreed[term.termsId] = value ?? false;
      }
    });
  }

  void _goNext() {
    if (!_areRequiredTermsAgreed()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필수 약관에 모두 동의해주세요.')),
      );
      return;
    }

    final agreedIds = _agreed.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    final updated = widget.request.copyWith(
      agreedTermIds: agreedIds,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JoinStep2Screen(
          baseUrl: widget.baseUrl,
          request: updated,
        ),
      ),
    );
  }

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
                          term.termsTitle,
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
                        term.termsContent.isNotEmpty
                            ? term.termsContent
                            : '약관 내용이 없습니다.',  // ✅ null 체크!
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('STEP 1/4 - 약관 동의'),
      ),
      body: Column(
        children: [
          // 진행 바
          _buildProgressBar(),

          // 상품명
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.request.productName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 약관 목록
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _terms.isEmpty
                ? const Center(
              child: Text(
                '약관 정보가 없습니다.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView(
              children: [
                // ✅ 전체 동의 (유지!)
                Container(
                  color: Colors.grey[100],
                  child: CheckboxListTile(
                    value: _allAgreed,
                    onChanged: _toggleAll,
                    title: const Text(
                      '전체 동의',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    controlAffinity:
                    ListTileControlAffinity.leading,
                  ),
                ),

                const Divider(height: 1),

                // ✅ 개별 약관 (수정!)
                ..._terms.map((term) {
                  return Column(
                    children: [
                      CheckboxListTile(
                        value: _agreed[term.termsId],
                        onChanged: (v) {
                          setState(() {
                            _agreed[term.termsId] = v ?? false;
                          });
                        },
                        title: Row(
                          children: [
                            // ✅ 필수/선택 표시
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: term.isRequired
                                    ? Colors.red
                                    : Colors.grey,
                                borderRadius:
                                BorderRadius.circular(4),
                              ),
                              child: Text(
                                term.isRequired ? '필수' : '선택',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // ✅ 약관 제목 표시 (핵심 수정!)
                            Expanded(
                              child: Text(
                                term.termsTitle,  // ← 이게 중요!
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        secondary: IconButton(
                          icon: const Icon(
                            Icons.description_outlined,
                            size: 20,
                          ),
                          onPressed: () => _showTermDetail(term),
                        ),
                        controlAffinity:
                        ListTileControlAffinity.leading,
                      ),
                      const Divider(height: 1),
                    ],
                  );
                }).toList(),
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
          _buildLine(false),
          _buildStep(2, false),
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
          onPressed: _areRequiredTermsAgreed() ? _goNext : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
          ),
          child: const Text(
            '다음 (STEP 2)',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}