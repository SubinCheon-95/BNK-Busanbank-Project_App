import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/news_analysis_result.dart';
import '../../../config/routes.dart';

class NewsResultScreen extends StatelessWidget {
  final NewsAnalysisResult result;

  const NewsResultScreen({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('분석 결과'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // 공유 기능
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 기사 이미지 & 제목
            if (result.image != null) _buildHeaderImage(),

            // 기사 제목
            if (result.title != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  result.title!,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const Divider(height: 1),

            // 감정 분석
            _buildSentimentSection(context),

            const Divider(height: 1),

            // 요약
            _buildSummarySection(context),

            const Divider(height: 1),

            // 키워드
            _buildKeywordsSection(context),

            const Divider(height: 1),

            // 추천 상품
            _buildRecommendationsSection(context),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderImage() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: CachedNetworkImage(
        imageUrl: result.image!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[200],
          child: const Icon(Icons.error, size: 48),
        ),
      ),
    );
  }

  Widget _buildSentimentSection(BuildContext context) {
    final color = _getSentimentColor(result.sentiment);
    final icon = _getSentimentIcon(result.sentiment);

    return Container(
      padding: const EdgeInsets.all(16),
      color: color.withOpacity(0.1),
      child: Row(
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '감정 분석',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.sentiment,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '점수: ${(result.sentimentScore * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.summarize, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                '요약',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.summary,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeywordsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.key, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                '키워드',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: result.keywords.map((keyword) {
              return Chip(
                label: Text(keyword),
                backgroundColor: Colors.blue[50],
                labelStyle: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(BuildContext context) {
    if (result.recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.recommend, color: Colors.green),
              SizedBox(width: 8),
              Text(
                '추천 상품',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...result.recommendations.map((product) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(
                  product.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(product.description),
                    const SizedBox(height: 4),
                    Text(
                      '최고 ${product.maturityRate.toStringAsFixed(2)}%',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    Routes.productDetail,
                    arguments: product.productNo,
                  );
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Color _getSentimentColor(String sentiment) {
    switch (sentiment) {
      case '긍정':
        return Colors.green;
      case '부정':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getSentimentIcon(String sentiment) {
    switch (sentiment) {
      case '긍정':
        return Icons.sentiment_very_satisfied;
      case '부정':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }
}