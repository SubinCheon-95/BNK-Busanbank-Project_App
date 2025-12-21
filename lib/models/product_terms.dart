// lib/model/product_terms.dart

class ProductTerms {
  final int termId;
  final int productNo;
  final String termType;      // ESSENTIAL/OPTIONAL
  final String termTitle;
  final String termContent;
  final bool isRequired;
  final int displayOrder;     // ✅ 추가!

  ProductTerms({
    required this.termId,
    required this.productNo,
    required this.termType,
    required this.termTitle,
    required this.termContent,
    required this.isRequired,
    required this.displayOrder,  // ✅ 추가!
  });

  factory ProductTerms.fromJson(Map<String, dynamic> json) {
    final termType = json['termType'] as String? ?? '';
    final isRequired = termType.toUpperCase() == 'ESSENTIAL' ||
        json['isRequired'] == 1 ||
        json['isRequired'] == true;

    return ProductTerms(
      termId: json['termId'] ?? 0,
      productNo: json['productNo'] ?? 0,
      termType: termType,
      termTitle: json['termTitle'] ?? '',
      termContent: json['termContent'] ?? '',
      isRequired: isRequired,
      displayOrder: json['displayOrder'] ?? 0,  // ✅ 추가!
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'termId': termId,
      'productNo': productNo,
      'termType': termType,
      'termTitle': termTitle,
      'termContent': termContent,
      'isRequired': isRequired,
      'displayOrder': displayOrder,  // ✅ 추가!
    };
  }
}