// lib/model/product.dart

class Product {
  final int productNo;
  final String name;
  final String type;
  final int categoryId;
  final String? categoryName;
  final String description;
  final double baseRate;
  final double maturityRate;
  final double earlyTerminateRate;
  final int? monthlyAmount;
  final int savingTerm;
  final int? depositAmount;
  final String interestMethod;
  final String payCycle;
  final String endDate;
  final int adminId;
  final String createdAt;
  final String? updatedAt;
  final String status;
  final List<String>? joinTypes;  // ✅ List<String>으로 변경!
  final String? joinTypesStr;
  final int subscriberCount;
  final String? productFeatures;
  final int hit;

  Product({
    required this.productNo,
    required this.name,
    required this.type,
    required this.categoryId,
    this.categoryName,
    required this.description,
    required this.baseRate,
    required this.maturityRate,
    required this.earlyTerminateRate,
    this.monthlyAmount,
    required this.savingTerm,
    this.depositAmount,
    required this.interestMethod,
    required this.payCycle,
    required this.endDate,
    required this.adminId,
    required this.createdAt,
    this.updatedAt,
    required this.status,
    this.joinTypes,  // ✅ List<String>
    this.joinTypesStr,
    required this.subscriberCount,
    this.productFeatures,
    required this.hit,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    num _toNum(dynamic v) => v is num ? v : num.parse(v.toString());
    int? _toIntNullable(dynamic v) =>
        v == null ? null : int.parse(v.toString());

    return Product(
      productNo: json['productNo'] as int,
      name: json['productName'] as String,
      type: json['productType'] as String,
      categoryId: json['categoryId'] as int,
      categoryName: json['categoryName'] as String?,
      description: json['description'] as String? ?? '',
      baseRate: _toNum(json['baseRate']).toDouble(),
      maturityRate: _toNum(json['maturityRate']).toDouble(),
      earlyTerminateRate: _toNum(json['earlyTerminateRate']).toDouble(),
      monthlyAmount: _toIntNullable(json['monthlyAmount']),
      savingTerm: json['savingTerm'] as int? ?? 0,
      depositAmount: _toIntNullable(json['depositAmount']),
      interestMethod: json['interestMethod'] as String? ?? '',
      payCycle: json['payCycle'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      adminId: json['adminId'] as int? ?? 0,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String?,
      status: json['status'] as String? ?? '',
      // ✅ joinTypes 파싱 (List<String>)
      joinTypes: json['joinTypes'] != null
          ? (json['joinTypes'] is List
          ? List<String>.from(json['joinTypes'])
          : null)
          : null,
      joinTypesStr: json['joinTypesStr']?.toString(),
      subscriberCount: json['subscriberCount'] as int? ?? 0,
      productFeatures: json['productFeatures']?.toString(),
      hit: json['hit'] as int? ?? 0,
    );
  }
}