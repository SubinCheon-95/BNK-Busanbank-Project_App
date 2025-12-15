// lib/model/user_coupon.dart

class UserCoupon {
  final int couponId;
  final String couponName;
  final double bonusRate;
  final bool isUsed;
  final DateTime? expiryDate;

  UserCoupon({
    required this.couponId,
    required this.couponName,
    required this.bonusRate,
    required this.isUsed,
    this.expiryDate,
  });

  factory UserCoupon.fromJson(Map<String, dynamic> json) {
    return UserCoupon(
      couponId: json['couponId'] ?? 0,
      couponName: json['couponName'] ?? '',
      bonusRate: (json['bonusRate'] ?? 0.0).toDouble(),
      isUsed: json['isUsed'] == 1 || json['isUsed'] == true,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'couponId': couponId,
      'couponName': couponName,
      'bonusRate': bonusRate,
      'isUsed': isUsed,
      'expiryDate': expiryDate?.toIso8601String(),
    };
  }
}