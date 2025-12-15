// lib/model/product_terms.dart

class ProductTerms {
  final int termsId;
  final int productNo;
  final String termsTitle;
  final String termsContent;
  final bool isRequired;

  ProductTerms({
    required this.termsId,
    required this.productNo,
    required this.termsTitle,
    required this.termsContent,
    required this.isRequired,
  });

  factory ProductTerms.fromJson(Map<String, dynamic> json) {
    return ProductTerms(
      termsId: json['termsId'] ?? 0,
      productNo: json['productNo'] ?? 0,
      termsTitle: json['termsTitle'] ?? '',
      termsContent: json['termsContent'] ?? '',
      isRequired: json['isRequired'] == 1 || json['isRequired'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'termsId': termsId,
      'productNo': productNo,
      'termsTitle': termsTitle,
      'termsContent': termsContent,
      'isRequired': isRequired,
    };
  }
}