class NewsAnalysisResult {
  final String? url;
  final String? title;
  final String? description;
  final String? image;
  final String summary;
  final List<String> keywords;
  final String sentiment;
  final double sentimentScore;
  final List<RecommendedProduct> recommendations;

  NewsAnalysisResult({
    this.url,
    this.title,
    this.description,
    this.image,
    required this.summary,
    required this.keywords,
    required this.sentiment,
    required this.sentimentScore,
    required this.recommendations,
  });

  factory NewsAnalysisResult.fromJson(Map<String, dynamic> json) {
    return NewsAnalysisResult(
      url: json['url'],
      title: json['title'],
      description: json['description'],
      image: json['image'],
      summary: json['summary'] ?? '',
      keywords: List<String>.from(json['keywords'] ?? []),
      sentiment: json['sentiment']?['label'] ?? '중립',
      sentimentScore: json['sentiment']?['score']?.toDouble() ?? 0.0,
      recommendations: (json['recommendations'] as List?)
          ?.map((e) => RecommendedProduct.fromJson(e))
          .toList() ?? [],
    );
  }
}

class RecommendedProduct {
  final int productNo;
  final String productName;
  final String description;
  final double maturityRate;

  RecommendedProduct({
    required this.productNo,
    required this.productName,
    required this.description,
    required this.maturityRate,
  });

  factory RecommendedProduct.fromJson(Map<String, dynamic> json) {
    return RecommendedProduct(
      productNo: json['productNo'] ?? 0,
      productName: json['productName'] ?? '',
      description: json['description'] ?? '',
      maturityRate: json['maturityRate']?.toDouble() ?? 0.0,
    );
  }
}