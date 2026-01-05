import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/news_analysis_result.dart';
import '../../services/product_service.dart';
import '../product/product_detail_screen.dart';
import '../../models/product.dart';
import '../../widgets/floating_words_overlay.dart';
import 'package:tkbank/theme/app_colors.dart';

class NewsResultScreen extends StatefulWidget {
  final String baseUrl;
  final NewsAnalysisResult result;

  const NewsResultScreen({
    super.key,
    required this.baseUrl,
    required this.result,
  });

  @override
  State<NewsResultScreen> createState() => _NewsResultScreenState();
}

class _NewsResultScreenState extends State<NewsResultScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showTopButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >= 200) {
      if (!_showTopButton) {
        setState(() => _showTopButton = true);
      }
    } else {
      if (_showTopButton) {
        setState(() => _showTopButton = false);
      }
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Color _getSentimentColor() {
    if (result.sentiment.label.contains('긍정')) {
      return Colors.blue.shade900;
    } else if (result.sentiment.label.contains('부정')) {
      return Colors.red.shade900;
    } else {
      return Colors.green.shade900;
    }
  }

  IconData _getSentimentIcon() {
    if (widget.result.sentiment.label.contains('긍정')) {
      return Icons.sentiment_very_satisfied;
    } else if (widget.result.sentiment.label.contains('부정')) {
      return Icons.sentiment_very_dissatisfied;
    } else {
      return Icons.sentiment_satisfied_outlined;
    }
  }

  String _getStrengthDescription(double percentage) {
    if (percentage >= 80) {
      return '매우 강한 감정 (80~100%)';
    } else if (percentage >= 60) {
      return '강한 감정 (60~80%)';
    } else if (percentage >= 40) {
      return '보통 감정 (40~60%)';
    } else if (percentage >= 20) {
      return '약한 감정 (20~40%)';
    } else {
      return '매우 중립적인 감정 (0~20%)';
    }
  }

  double _getSentimentStrength() {
    final explain = widget.result.sentiment.explain ?? '';
    final match = RegExp(r'score\s*=\s*(-?\d+)').firstMatch(explain);

    if (match != null) {
      final rawScore = int.tryParse(match.group(1) ?? '0') ?? 0;
      final abs = rawScore.abs();
      final percent = (abs / 10.0) * 100.0;
      return percent.clamp(0.0, 100.0);
    }

    final conf = widget.result.sentiment.score.abs();
    return (conf * 10.0);
  }

  List<String> _getDisplayWords() {
    final label = widget.result.sentiment.label;
    final positive = widget.result.sentiment.matchedPositiveWords;
    final negative = widget.result.sentiment.matchedNegativeWords;

    if (label.contains('긍정')) {
      return positive.take(10).toList();
    } else if (label.contains('부정')) {
      return negative.take(10).toList();
    } else {
      final pos5 = positive.take(5).toList();
      final neg5 = negative.take(5).toList();
      return [...pos5, ...neg5];
    }
  }

  Color _getWordColor(String word) {
    if (widget.result.sentiment.matchedPositiveWords.contains(word)) {
      return Colors.cyanAccent;
    } else {
      return Colors.yellow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    print('━━━━━━━━━━━━━━━━━━━━━━━━');
    print('[DEBUG] 감정: ${widget.result.sentiment.label}');
    print('[DEBUG] 긍정 단어: ${widget.result.sentiment.matchedPositiveWords}');
    print('[DEBUG] 부정 단어: ${widget.result.sentiment.matchedNegativeWords}');
    print('[DEBUG] 긍정 단어 개수: ${widget.result.sentiment.matchedPositiveWords.length}');
    print('[DEBUG] 부정 단어 개수: ${widget.result.sentiment.matchedNegativeWords.length}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━');

    return Scaffold(
      backgroundColor: AppColors.gray1,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),

              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text(
                  'AI 분석 결과',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Text(
                  widget.result.title?.isNotEmpty == true
                      ? widget.result.title!
                      : '기사 감정 · 요약 · 키워드 분석',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray5,
                  ),
                ),
              ),

              Expanded(
                child: ListView(
                  controller: _scrollController,  // ScrollController 추가
                  padding: EdgeInsets.zero,
                  children: [
                    // 감정 분석 큰 컨테이너
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.fromLTRB(30, 50, 30, 50),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _getSentimentColor(),
                            _getSentimentColor().withOpacity(0.9),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_getDisplayWords().isNotEmpty)
                            SizedBox(
                              width: double.infinity,
                              height: 450,
                              child: Stack(
                                children: _getDisplayWords()
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final index = entry.key;
                                  final word = entry.value;
                                  return FloatingWordsOverlay(
                                    words: [word],
                                    color: _getWordColor(word),
                                    maxWords: 1,
                                    startIndex: index,
                                  );
                                }).toList(),
                              ),
                            ),

                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(25),
                                  decoration: BoxDecoration(
                                    color: AppColors.white.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getSentimentIcon(),
                                    size: 130,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 25),
                                Text(
                                  widget.result.sentiment.label,
                                  style: const TextStyle(
                                    fontSize: 64,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 30,
                                    vertical: 15,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                  child: Text(
                                    '감정 강도: ${_getSentimentStrength().toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                                if (widget.result.sentiment.explain != null) ...[
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.fromLTRB(25, 20, 25, 20),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: Text(
                                      _getStrengthDescription(
                                        _getSentimentStrength(),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.white,
                                        height: 1.6,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 본문
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.result.image != null && widget.result.image!.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: _getFullImageUrl(widget.result.image),
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  height: 220,
                                  color: AppColors.gray3,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) {
                                  return Container(
                                    height: 220,
                                    color: AppColors.gray3,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.broken_image,
                                          size: 64,
                                          color: AppColors.gray5,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '이미지를 불러올 수 없습니다',
                                          style: TextStyle(color: AppColors.gray5),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          if (widget.result.title != null) ...[
                            Text(
                              widget.result.title!,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                height: 1.5,
                              ),
                            ),
                          ],

                          if (widget.result.description != null) ...[
                            Text(
                              widget.result.description!,
                              style: TextStyle(
                                fontSize: 20,
                                color: AppColors.gray5,
                                height: 1.5,
                              ),
                            ),
                          ],

                          if (widget.result.summary != null) ...[
                            _buildSection(
                              '요약',
                              Icons.summarize,
                              AppColors.blue,
                              child: Text(
                                widget.result.summary!,
                                style: const TextStyle(
                                  fontSize: 20,
                                  height: 1.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          _buildSection(
                            '주요 키워드',
                            Icons.label,
                            AppColors.pink,
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: widget.result.keywords.map((keyword) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: AppColors.pink,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    keyword,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.pink,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          const SizedBox(height: 20),

                          _buildSection(
                            '추천 상품',
                            Icons.shopping_bag,
                            Colors.purple,
                            child: widget.result.recommendations.isEmpty
                                ? const Text(
                              '추천 상품이 없습니다.',
                              style: TextStyle(fontSize: 16),
                            )
                                : Column(
                              children: widget.result.recommendations.map((product) {
                                return Card(
                                  color: AppColors.gray1,
                                  margin: const EdgeInsets.only(bottom: 15),
                                  elevation: 0,
                                  clipBehavior: Clip.antiAlias,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(15),
                                    leading: Container(
                                      width: 45,
                                      height: 45,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.purple[300]!,
                                            Colors.purple[500]!,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.account_balance,
                                        color: AppColors.white,
                                        size: 25,
                                      ),
                                    ),
                                    title: Text(
                                      product.productName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.purple,
                                      size: 20,
                                    ),
                                    onTap: () => _navigateToProductDetail(
                                      context,
                                      product,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 50),
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
      // TOP 버튼 추가
      floatingActionButton: _showTopButton
          ? Container(
        width: screenWidth * 0.14,
        height: screenWidth * 0.14,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          onPressed: _scrollToTop,
          icon: const Icon(
            Icons.keyboard_double_arrow_up,
            color: AppColors.white,
            size: 32,
          ),
        ),
      )
          : null,
    );
  }

  Widget _buildSection(
      String title,
      IconData icon,
      Color color, {
        required Widget child,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.2),
                        color.withOpacity(0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 15),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _dashedDivider(),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  String _getFullImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    final serverBase = widget.baseUrl.replaceAll('/api', '');
    return '$serverBase$imageUrl';
  }

  void _navigateToProductDetail(
      BuildContext context,
      RecommendedProduct product,
      ) async {
    final service = ProductService(widget.baseUrl);

    try {
      final detail = await service.fetchProductDetail(product.productNo);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(
            baseUrl: widget.baseUrl,
            product: detail,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('상품 정보를 불러오지 못했습니다')),
      );
    }
  }

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
}