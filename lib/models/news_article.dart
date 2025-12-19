class NewsArticle {
  final int? articleId;
  final String title;
  final String? content;
  final String? imageUrl;
  final DateTime? publishedAt;
  final String? source;
  final String? analysisResult;

  NewsArticle({
    this.articleId,
    required this.title,
    this.content,
    this.imageUrl,
    this.publishedAt,
    this.source,
    this.analysisResult,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      articleId: json['articleId'],
      title: json['title'] ?? '',
      content: json['content'],
      imageUrl: json['imageUrl'],
      publishedAt: json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'])
          : null,
      source: json['source'],
      analysisResult: json['analysisResult'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'articleId': articleId,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'publishedAt': publishedAt?.toIso8601String(),
      'source': source,
      'analysisResult': analysisResult,
    };
  }
}