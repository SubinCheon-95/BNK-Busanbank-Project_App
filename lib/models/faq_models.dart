class FaqItem {
  final int faqId;
  final String faqCategory;
  final String question;
  final String answer;

  FaqItem({
    required this.faqId,
    required this.faqCategory,
    required this.question,
    required this.answer,
  });

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      faqId: (json['faqId'] ?? 0) as int,
      faqCategory: (json['faqCategory'] ?? '') as String,
      question: (json['question'] ?? '') as String,
      answer: (json['answer'] ?? '') as String,
    );
  }
}

class FaqCategory {
  final String code;
  final String codeName;

  FaqCategory({
    required this.code,
    required this.codeName,
  });

  factory FaqCategory.fromJson(Map<String, dynamic> json) {
    return FaqCategory(
      code: (json['code'] ?? '') as String,
      codeName: (json['codeName'] ?? '') as String,
    );
  }
}

class PageResponse<T> {
  final List<T> dtoList;
  final int total;

  PageResponse({
    required this.dtoList,
    required this.total,
  });

  factory PageResponse.fromJson(
      Map<String, dynamic> json,
      T Function(Map<String, dynamic>) fromItem,
      ) {
    final list = (json['dtoList'] as List<dynamic>? ?? [])
        .map((e) => fromItem(e as Map<String, dynamic>))
        .toList();

    return PageResponse(
      dtoList: list,
      total: (json['total'] ?? 0) as int,
    );
  }
}
