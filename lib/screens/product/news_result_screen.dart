import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/news_analysis_result.dart';
import '../product/product_detail_screen.dart';
import '../../models/product.dart';

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
      return Colors.green;
    } else if (result.sentiment.label.contains('부정')) {
      return Colors.red;
    } else {
      return Colors.orange;
    }
  }

  IconData _getSentimentIcon() {
    if (result.sentiment.label.contains('긍정')) {
      return Icons.sentiment_very_satisfied;
    } else if (result.sentiment.label.contains('부정')) {
      return Icons.sentiment_very_dissatisfied;
    } else {
      return Icons.sentiment_neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('분석 결과'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // 🎨 감정 분석 결과 (크게크게!)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
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
            child: Column(
              children: [
                // 초대형 아이콘
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getSentimentIcon(),
                    size: 120,  // 🔥 크게!
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                // 초대형 텍스트
                Text(
                  result.sentiment.label,
                  style: const TextStyle(
                    fontSize: 56,  // 🔥 크게!
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
                // 신뢰도
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
                    '신뢰도: ${(result.sentiment.score * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 28,  // 🔥 크게!
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
                      result.sentiment.explain!,
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

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 기사 정보
                if (result.image != null && result.image!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: _getFullImageUrl(result.image),  // ✅ 수정!
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
                        print('[이미지 로딩 실패] URL: $url');
                        print('[이미지 로딩 실패] Error: $error');
                        return Container(
                          height: 220,
                          color: Colors.grey[200],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.broken_image, size: 64, color: Colors.grey),
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

                // 요약
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

                // 키워드
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

                // 추천 상품
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
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              if (product.maturityRate != null)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.trending_up,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '최고금리: ${product.maturityRate!.toStringAsFixed(2)}%',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              if (product.description != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  product.description!,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ],
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.purple,
                          ),
                          onTap: () {
                            // ✅ 상품 상세로 이동!
                            _navigateToProductDetail(context, product);
                          },
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
  void _navigateToProductDetail(BuildContext context, RecommendedProduct product) {
    final productModel = Product(
      // 기본 정보
      productNo: product.productNo,
      name: product.productName,
      description: product.description ?? '',
      type: '01',  // 예금으로 가정

      // 금리 정보
      baseRate: product.maturityRate ?? 0.0,
      maturityRate: product.maturityRate ?? 0.0,
      earlyTerminateRate: 0.0,

      // 기타 필수 필드 (기본값)
      categoryId: 0,
      savingTerm: 12,
      interestMethod: '단리',
      payCycle: '만기일시지급',
      endDate: '2026-12-31',
      adminId: 1,
      createdAt: DateTime.now().toIso8601String(),
      status: 'A',
      subscriberCount: 0,
      hit: 0,

      // Optional 필드 (null 가능)
      categoryName: null,
      monthlyAmount: null,
      depositAmount: null,
      updatedAt: null,
      joinTypes: null,
      joinTypesStr: null,
      productFeatures: null,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          baseUrl: baseUrl,
          product: productModel,
        ),
      ),
    );
  }



}