// 2025/12/18 - 쿠폰 모델 - 작성자: 진원
class Coupon {
  final int userCouponId;
  final int userId;
  final int couponId;
  final String couponCode;
  final String couponName;
  final double rateIncrease;
  final String status; // UNUSED, USED
  final String issuedDate;
  final String validTo;
  final String? productName;

  Coupon({
    required this.userCouponId,
    required this.userId,
    required this.couponId,
    required this.couponCode,
    required this.couponName,
    required this.rateIncrease,
    required this.status,
    required this.issuedDate,
    required this.validTo,
    this.productName,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      userCouponId: json['userCouponId'] ?? 0,
      userId: json['userId'] ?? 0,
      couponId: json['couponId'] ?? 0,
      couponCode: json['couponCode'] ?? '',
      couponName: json['couponName'] ?? '',
      rateIncrease: (json['rateIncrease'] ?? 0).toDouble(),
      status: json['status'] ?? 'UNUSED',
      issuedDate: json['issuedDate'] ?? '',
      validTo: json['validTo'] ?? '',
      productName: json['productName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userCouponId': userCouponId,
      'userId': userId,
      'couponId': couponId,
      'couponCode': couponCode,
      'couponName': couponName,
      'rateIncrease': rateIncrease,
      'status': status,
      'issuedDate': issuedDate,
      'validTo': validTo,
      'productName': productName,
    };
  }

  bool get isUsed => status == 'USED';
  bool get isAvailable => status == 'UNUSED';
}
