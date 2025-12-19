// 2025/12/18 - 사용자 상품 모델 - 작성자: 진원
class UserProduct {
  final int productNo;
  final String productName;
  final String startDate;
  final String? expectedEndDate;
  final int principalAmount;
  final double applyRate;
  final String? status; // Y: 활성, N: 비활성/해지
  final int? contractTerm; // 계약 기간 (개월)
  final String? accountNo; // 계좌번호

  UserProduct({
    required this.productNo,
    required this.productName,
    required this.startDate,
    this.expectedEndDate,
    required this.principalAmount,
    required this.applyRate,
    this.status,
    this.contractTerm,
    this.accountNo,
  });

  factory UserProduct.fromJson(Map<String, dynamic> json) {
    return UserProduct(
      productNo: json['productNo'] ?? 0,
      productName: json['productName'] ?? '',
      startDate: json['startDate'] ?? '',
      expectedEndDate: json['expectedEndDate'],
      principalAmount: json['principalAmount'] ?? 0,
      applyRate: (json['applyRate'] ?? 0).toDouble(),
      status: json['status'],
      contractTerm: json['contractTerm'],
      accountNo: json['accountNo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productNo': productNo,
      'productName': productName,
      'startDate': startDate,
      'expectedEndDate': expectedEndDate,
      'principalAmount': principalAmount,
      'applyRate': applyRate,
      'status': status,
      'contractTerm': contractTerm,
      'accountNo': accountNo,
    };
  }

  bool get isActive => status == 'Y';
}
