// lib/models/user_coupon.dart

/// 🔥 사용자 쿠폰 모델
/// Backend UserCouponDTO / DB USERCOUPON 테이블과 매핑
class UserCoupon {
  final int ucNo;              // ✅ USERCOUPONID (PK)
  final int userNo;            // ✅ USERID 또는 USERNO
  final int couponNo;          // ✅ COUPONID 또는 COUPONNO
  final String couponName;     // COUPONNAME
  final double bonusRate;      // BONUSRATE / RATEINCREASE / rateIncrease
  final int? categoryId;       // CATEGORYID
  final int? productNo;        // PRODUCTNO
  final DateTime? expireDate;  // VALIDTO / EXPIREDATE
  final String? status;        // UNUSED / USED

  UserCoupon({
    required this.ucNo,
    required this.userNo,
    required this.couponNo,
    required this.couponName,
    required this.bonusRate,
    this.categoryId,
    this.productNo,
    this.expireDate,
    this.status,
  });

  /// JSON → UserCoupon
  factory UserCoupon.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    double _toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    DateTime? _toDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    // ✅ 핵심: USERCOUPONID를 ucNo로 잡는다 (여러 키 대응)
    final parsedUcNo = _toInt(
      json['ucNo'] ??
          json['ucno'] ??
          json['userCouponId'] ??
          json['usercouponid'] ??
          json['USERCOUPONID'],
    );

    // ✅ USERID/USERNO 대응
    final parsedUserNo = _toInt(
      json['userNo'] ??
          json['userno'] ??
          json['userId'] ??
          json['userid'] ??
          json['USERID'],
    );

    // ✅ COUPONID/COUPONNO 대응
    final parsedCouponNo = _toInt(
      json['couponNo'] ??
          json['couponno'] ??
          json['couponId'] ??
          json['couponid'] ??
          json['COUPONID'],
    );

    // ✅ 만료일: expireDate / expiredate / validTo / VALIDTO 등 대응
    final parsedExpire = _toDate(
      json['expireDate'] ??
          json['expiredate'] ??
          json['validTo'] ??
          json['validto'] ??
          json['VALIDTO'],
    );

    // ✅ bonusRate: bonusRate / bonusrate / rateIncrease / RATEINCREASE 대응
    final parsedBonusRate = _toDouble(
      json['bonusRate'] ??
          json['bonusrate'] ??
          json['rateIncrease'] ??
          json['rateincrease'] ??
          json['RATEINCREASE'],
    );

    return UserCoupon(
      ucNo: parsedUcNo,
      userNo: parsedUserNo,
      couponNo: parsedCouponNo,
      couponName: (json['couponName'] ?? json['couponname'] ?? json['COUPONNAME'] ?? '').toString(),
      bonusRate: parsedBonusRate,
      categoryId: (json['categoryId'] ?? json['categoryid'] ?? json['CATEGORYID']) as int?,
      productNo: (json['productNo'] ?? json['productno'] ?? json['PRODUCTNO']) as int?,
      expireDate: parsedExpire,
      status: (json['status'] ?? json['STATUS'])?.toString(),
    );
  }

  /// UserCoupon → JSON
  Map<String, dynamic> toJson() {
    return {
      // ✅ joinRequest.selectedCouponId로 보낼 값은 "유저쿠폰 PK"가 되어야 USED 처리 가능
      'userCouponId': ucNo, // (필요시)
      'ucNo': ucNo,

      'userNo': userNo,
      'couponNo': couponNo,
      'couponName': couponName,
      'bonusRate': bonusRate,

      'categoryId': categoryId,
      'productNo': productNo,
      'expireDate': expireDate?.toIso8601String(),
      'status': status,
    };
  }
}
