import 'package:flutter/material.dart';
import 'package:tkbank/theme/app_colors.dart';
import '../../../models/product_join_request.dart';
import '../../../models/product_terms.dart';
import '../../../services/product_join_service.dart';
import 'join_step2_screen.dart';

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
      setState(() {
        _terms = terms;
        for (final term in terms) {
          _agreed[term.termId] = false;
        }
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  bool get _allAgreed =>
      _terms.isNotEmpty && _terms.every((t) => _agreed[t.termId] == true);

  bool _areRequiredTermsAgreed() {
    return _terms
        .where((t) => t.isRequired)
        .every((t) => _agreed[t.termId] == true);
  }

  void _toggleAll(bool? value) {
    setState(() {
      for (final term in _terms) {
        _agreed[term.termId] = value ?? false;
      }
    });
  }

  void _goNext() {
    if (!_areRequiredTermsAgreed()) return;

    final agreedIds = _agreed.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JoinStep2Screen(
          baseUrl: widget.baseUrl,
          request: widget.request.copyWith(agreedTermIds: agreedIds),
        ),
      ),
    );
  }

  void _showTermDetail(ProductTerms term) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                child: Text(
                  term.termContent.isNotEmpty
                      ? term.termContent
                      : '약관 내용이 없습니다.',
                  style: const TextStyle(fontSize: 14, height: 1.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.gray1,
      body: Stack(
        children: [
          // 본문
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 왼쪽 타이틀
                    const Expanded(
                      child: Text(
                        '약관 동의',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),

                    // 오른쪽 STEP 표시
                    _buildMiniStepIndicator(currentStep: 1),
                  ],
                ),
              ),

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

              // 약관 리스트
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                  children: [
                    // 전체 동의
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _allAgreed,
                              onChanged: _toggleAll,

                              activeColor: AppColors.primary,
                              checkColor: AppColors.white,
                              side: const BorderSide(
                                color: AppColors.gray4,
                                width: 1.5,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                '전체 동의',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // 개별 약관
                    Container(
                      margin:
                      const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          children: _terms
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
                                      value:
                                      _agreed[term.termId],
                                      onChanged: (v) {
                                        setState(() {
                                          _agreed[term.termId] =
                                              v ?? false;
                                        });
                                      },

                                      activeColor: AppColors.primary,
                                      checkColor: AppColors.white,
                                      side: const BorderSide(
                                        color: AppColors.gray4,
                                        width: 1.5,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding:
                                      const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: term.isRequired
                                            ? AppColors.red
                                            : AppColors.gray4,
                                        borderRadius:
                                        BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        term.isRequired
                                            ? '필수'
                                            : '선택',
                                        style: const TextStyle(
                                          color: AppColors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        term.termTitle,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow:
                                        TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.description_outlined,
                                        size: 22,
                                      ),
                                      onPressed: () =>
                                          _showTermDetail(term),
                                    ),
                                  ],
                                ),
                                if (index !=
                                    _terms.length - 1) ...[
                                  const SizedBox(height: 15),
                                  _dashedDivider(),
                                  const SizedBox(height: 15),
                                ],
                              ],
                            );
                          }).toList(),
                        ),
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
              icon: const Icon(
                Icons.chevron_left,
                size: 34,
                color: AppColors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),

      // 하단 버튼
      bottomNavigationBar: Container(
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
              onPressed: _areRequiredTermsAgreed() ? _goNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
                disabledBackgroundColor:
                AppColors.gray4.withOpacity(0.3),
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
      ),
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
}
