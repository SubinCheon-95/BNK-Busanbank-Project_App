// lib/models/user_coupon.dart

/// 🔥 사용자 쿠폰 모델
///
/// Backend UserCouponDTO와 매핑
class UserCoupon {
  final int ucNo;              // UCNO (PK)
  final int userNo;            // USERNO
  final int couponNo;          // COUPONNO
  final String couponName;     // COUPONNAME
  final double bonusRate;      // BONUSRATE
  final int? categoryId;       // CATEGORYID ✅ 추가!
  final int? productNo;        // PRODUCTNO
  final DateTime? expireDate;  // EXPIREDATE ✅ 추가!
  final String? status;        // STATUS

  UserCoupon({
    required this.ucNo,
    required this.userNo,
    required this.couponNo,
    required this.couponName,
    required this.bonusRate,
    this.categoryId,           // ✅ 추가!
    this.productNo,
    this.expireDate,           // ✅ 추가!
    this.status,
  });

  /// JSON → UserCoupon
  factory UserCoupon.fromJson(Map<String, dynamic> json) {
    return UserCoupon(
      ucNo: json['ucNo'] ?? json['ucno'] ?? 0,
      userNo: json['userNo'] ?? json['userno'] ?? 0,
      couponNo: json['couponNo'] ?? json['couponno'] ?? 0,
      couponName: json['couponName'] ?? json['couponname'] ?? '',
      bonusRate: (json['bonusRate'] ?? json['bonusrate'] ?? 0.0).toDouble(),
      categoryId: json['categoryId'] ?? json['categoryid'],  // ✅ 추가!
      productNo: json['productNo'] ?? json['productno'],
      expireDate: json['expireDate'] != null             // ✅ 추가!
          ? DateTime.parse(json['expireDate'])
          : (json['expiredate'] != null
          ? DateTime.parse(json['expiredate'])
          : null),
      status: json['status'],
    );
  }

  /// UserCoupon → JSON
  Map<String, dynamic> toJson() {
    return {
      'ucNo': ucNo,
      'userNo': userNo,
      'couponNo': couponNo,
      'couponName': couponName,
      'bonusRate': bonusRate,
      'categoryId': categoryId,     // ✅ 추가!
      'productNo': productNo,
      'expireDate': expireDate?.toIso8601String(),  // ✅ 추가!
      'status': status,
    };
  }
}