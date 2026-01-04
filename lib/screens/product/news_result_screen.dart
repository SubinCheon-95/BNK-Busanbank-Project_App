import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/news_analysis_result.dart';
import '../../services/product_service.dart';
import '../product/product_detail_screen.dart';
import '../../models/product.dart';
import '../../widgets/floating_words_overlay.dart';
import 'package:tkbank/theme/app_colors.dart';

class NewsResultScreen extends StatelessWidget {
  final String baseUrl;
  final NewsAnalysisResult result;

  const NewsResultScreen({
    super.key,
    required this.baseUrl,
    required this.result,
  });

  Color _getSentimentColor() {
    if (result.sentiment.label.contains('긍정')) {
      return AppColors.blue;
    } else if (result.sentiment.label.contains('부정')) {
      return AppColors.red;
    } else {
      return AppColors.yellowGreen;
    }
  }

  IconData _getSentimentIcon() {
    if (result.sentiment.label.contains('긍정')) {
      return Icons.sentiment_very_satisfied;
    } else if (result.sentiment.label.contains('부정')) {
      return Icons.sentiment_very_dissatisfied;
    } else {
      return Icons.sentiment_satisfied_outlined;
    }
  }

  // ✅ 감정 강도 설명 텍스트
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


  // ✅ 감정 강도(체감) 계산: explain에서 원점수(score=정수)를 파싱해서 사용
  double _getSentimentStrength() {
    // 1) explain에서 "score=-6" 같은 원점수 추출 시도
    final explain = result.sentiment.explain ?? '';
    final match = RegExp(r'score\s*=\s*(-?\d+)').firstMatch(explain);

    if (match != null) {
      final rawScore = int.tryParse(match.group(1) ?? '0') ?? 0;
      final abs = rawScore.abs();

      // 백엔드가 confidence = abs(score)/10 로 만들었으니,
      // abs(score)=10이면 강도 100%로 매핑하는 게 가장 자연스러움
      final percent = (abs / 10.0) * 100.0;

      // 0~100으로 제한
      return percent.clamp(0.0, 100.0);
    }

    // 2) 파싱 실패하면 기존 confidence 기반으로 fallback
    final conf = result.sentiment.score.abs();
    return (conf * 10.0);
  }


  // ✅ 감정 강도 텍스트, 표시할 단어 결정
  List<String> _getDisplayWords() {
    final label = result.sentiment.label;
    final positive = result.sentiment.matchedPositiveWords;
    final negative = result.sentiment.matchedNegativeWords;

    if (label.contains('긍정')) {
      // 긍정: 긍정 단어 10개만
      return positive.take(10).toList();
    } else if (label.contains('부정')) {
      // 부정: 부정 단어 10개만
      return negative.take(10).toList();
    } else {
      // 중립: 긍정 5개 + 부정 5개
      final pos5 = positive.take(5).toList();
      final neg5 = negative.take(5).toList();
      return [...pos5, ...neg5];
    }
  }

  // ✅ 단어 색상 결정! (파란색 + 빨간색)
  Color _getWordColor(String word) {
    if (result.sentiment.matchedPositiveWords.contains(word)) {
      return Colors.cyanAccent;  // 긍정: 파란색!
    } else {
      return Colors.yellow;   // 부정: 빨간바탕에 노란글자색!
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    print('━━━━━━━━━━━━━━━━━━━━━━━━');
    print('[DEBUG] 감정: ${result.sentiment.label}');
    print('[DEBUG] 긍정 단어: ${result.sentiment.matchedPositiveWords}');
    print('[DEBUG] 부정 단어: ${result.sentiment.matchedNegativeWords}');
    print('[DEBUG] 긍정 단어 개수: ${result.sentiment.matchedPositiveWords.length}');
    print('[DEBUG] 부정 단어 개수: ${result.sentiment.matchedNegativeWords.length}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━');

    return Scaffold(
      backgroundColor: AppColors.gray1,
      body: Stack(
        children: [
          // 본문
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),

              // 타이틀만
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

              // 서브 타이틀
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Text(
                  result.title?.isNotEmpty == true
                      ? result.title!
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
                  padding: EdgeInsets.zero,
                  children: [
                    // 감정 분석 큰 컨테이너
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 60,
                        horizontal: 32,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _getSentimentColor(),
                            _getSentimentColor().withOpacity(0.7),
                          ],
                        ),
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
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getSentimentIcon(),
                                    size: 120,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                Text(
                                  result.sentiment.label,
                                  style: const TextStyle(
                                    fontSize: 56,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Text(
                                    '감정 강도: ${_getSentimentStrength().toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                if (result.sentiment.explain != null) ...[
                                  const SizedBox(height: 24),
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      _getStrengthDescription(
                                        _getSentimentStrength(),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
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
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (result.image != null && result.image!.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: _getFullImageUrl(result.image),
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  height: 220,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) {
                                  return Container(
                                    height: 220,
                                    color: Colors.grey[200],
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.broken_image,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '이미지를 불러올 수 없습니다',
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          if (result.title != null) ...[
                            Text(
                              result.title!,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          if (result.description != null) ...[
                            Text(
                              result.description!,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 28),
                          ],

                          if (result.summary != null) ...[
                            _buildSection(
                              '요약',
                              Icons.summarize,
                              Colors.blue,
                              child: Text(
                                result.summary!,
                                style: const TextStyle(
                                  fontSize: 17,
                                  height: 1.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          _buildSection(
                            '주요 키워드',
                            Icons.label,
                            Colors.orange,
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: result.keywords.map((keyword) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.orange[100]!,
                                        Colors.orange[50]!,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Colors.orange[300]!,
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    keyword,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[900],
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
                            child: result.recommendations.isEmpty
                                ? const Text(
                              '추천 상품이 없습니다.',
                              style: TextStyle(fontSize: 16),
                            )
                                : Column(
                              children: result.recommendations.map((product) {
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  elevation: 4,
                                  clipBehavior: Clip.antiAlias,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.purple[300]!,
                                            Colors.purple[500]!,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.account_balance,
                                        color: Colors.white,
                                        size: 32,
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
    );
  }

  Widget _buildJoinStyleHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 80),

          // 뒤로가기 (상품가입 흐름처럼 상단에 고정)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: IconButton(
              icon: const Icon(
                Icons.chevron_left,
                color: AppColors.black,
                size: 34,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // 타이틀 Row (좌 타이틀 / 우 미니 스텝)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'AI 분석 결과',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 서브 타이틀(상품명 위치에 기사 제목/설명)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: Text(
              (result.title?.isNotEmpty == true)
                  ? result.title!
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
        ],
      ),
    );
  }

  Widget _buildSection(
      String title,
      IconData icon,
      Color color, {
        required Widget child,
      }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
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
                        color.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 32, thickness: 2),
            child,
          ],
        ),
      ),
    );
  }

  // ✅ 이미지 URL 보정
  String _getFullImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';

    // 이미 완전한 URL이면 그대로 반환
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    // 상대 경로면 baseUrl과 합치기
    final serverBase = baseUrl.replaceAll('/api', '');
    return '$serverBase$imageUrl';
  }

// ✅ 상품 상세 화면으로 이동
  void _navigateToProductDetail(
      BuildContext context,
      RecommendedProduct product,
      ) async {
    final service = ProductService(baseUrl);

    try {
      final detail = await service.fetchProductDetail(product.productNo);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(
            baseUrl: baseUrl,
            product: detail, // ✅ joinTypes 포함
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('상품 정보를 불러오지 못했습니다')),
      );
    }
  }



}