class NewsAnalysisResult {
  final String? url;
  final String? title;
  final String? description;
  final String? image;
  final String? summary;
  final List<String> keywords;
  final SentimentResult sentiment;
  final List<RecommendedProduct> recommendations;

  NewsAnalysisResult({
    this.url,
    this.title,
    this.description,
    this.image,
    this.summary,
    required this.keywords,
    required this.sentiment,
    required this.recommendations,
  });

  factory NewsAnalysisResult.fromJson(Map<String, dynamic> json) {
    return NewsAnalysisResult(
      url: json['url'],
      title: json['title'],
      description: json['description'],
      image: json['image'],
      summary: json['summary'],
      keywords: (json['keywords'] as List?)?.cast<String>() ?? [],
      sentiment: SentimentResult.fromJson(json['sentiment'] ?? {}),
      recommendations: (json['recommendations'] as List?)
          ?.map((e) => RecommendedProduct.fromJson(e))
          .toList() ?? [],
    );
  }
}

class SentimentResult {
  final String label;  // 긍정, 부정, 중립
  final double score;
  final String? explain;

  SentimentResult({
    required this.label,
    required this.score,
    this.explain,
  });

  factory SentimentResult.fromJson(Map<String, dynamic> json) {
    return SentimentResult(
      label: json['label'] ?? '중립',
      score: (json['score'] ?? 0.0).toDouble(),
      explain: json['explain'],
    );
  }
}

class RecommendedProduct {
  final int productNo;
  final String productName;
  final double? maturityRate;
  final String? description;

  RecommendedProduct({
    required this.productNo,
    required this.productName,
    this.maturityRate,
    this.description,
  });

  factory RecommendedProduct.fromJson(Map<String, dynamic> json) {
    return RecommendedProduct(
      productNo: (json['productNo'] ?? 0).toInt(),
      productName: json['productName'] ?? '',
      maturityRate: json['maturityRate']?.toDouble(),
      description: json['description'],
    );
  }
}