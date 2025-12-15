// lib/model/product_join_request.dart

class ProductJoinRequest {
  // 상품 정보
  final int? productNo;
  final String productName;
  final String? productType;

  // 사용자 정보
  final int? userId;

  // 가입 정보
  final int? principalAmount;
  final int? contractTerm;
  final DateTime? startDate;
  final DateTime? expectedEndDate;

  // 지점/직원 정보
  final int? branchId;
  final int? empId;

  // 계좌 비밀번호
  final String? accountPassword;
  final String? accountPasswordConfirm;
  final String? accountPasswordOriginal;

  // 약관 동의
  final List<int>? agreedTermIds;

  // 포인트/쿠폰
  final int? usedPoints;
  final int? selectedCouponId;

  // 금리 정보
  final double? baseRate;
  final double? pointBonusRate;
  final double? couponBonusRate;
  final double? applyRate;

  // 알림 설정
  final String? notificationSms;
  final String? notificationEmail;
  final String? notificationHp;
  final String? notificationEmailAddr;

  // 최종 동의
  final bool? finalAgree;

  ProductJoinRequest({
    this.productNo,
    required this.productName,
    this.productType,
    this.userId,
    this.principalAmount,
    this.contractTerm,
    this.startDate,
    this.expectedEndDate,
    this.branchId,
    this.empId,
    this.accountPassword,
    this.accountPasswordConfirm,
    this.accountPasswordOriginal,
    this.agreedTermIds,
    this.usedPoints,
    this.selectedCouponId,
    this.baseRate,
    this.pointBonusRate,
    this.couponBonusRate,
    this.applyRate,
    this.notificationSms,
    this.notificationEmail,
    this.notificationHp,
    this.notificationEmailAddr,
    this.finalAgree,
  });

  // copyWith 메서드 (불변성 유지)
  ProductJoinRequest copyWith({
    int? productNo,
    String? productName,
    String? productType,
    int? userId,
    int? principalAmount,
    int? contractTerm,
    DateTime? startDate,
    DateTime? expectedEndDate,
    int? branchId,
    int? empId,
    String? accountPassword,
    String? accountPasswordConfirm,
    String? accountPasswordOriginal,
    List<int>? agreedTermIds,
    int? usedPoints,
    int? selectedCouponId,
    double? baseRate,
    double? pointBonusRate,
    double? couponBonusRate,
    double? applyRate,
    String? notificationSms,
    String? notificationEmail,
    String? notificationHp,
    String? notificationEmailAddr,
    bool? finalAgree,
  }) {
    return ProductJoinRequest(
      productNo: productNo ?? this.productNo,
      productName: productName ?? this.productName,
      productType: productType ?? this.productType,
      userId: userId ?? this.userId,
      principalAmount: principalAmount ?? this.principalAmount,
      contractTerm: contractTerm ?? this.contractTerm,
      startDate: startDate ?? this.startDate,
      expectedEndDate: expectedEndDate ?? this.expectedEndDate,
      branchId: branchId ?? this.branchId,
      empId: empId ?? this.empId,
      accountPassword: accountPassword ?? this.accountPassword,
      accountPasswordConfirm: accountPasswordConfirm ?? this.accountPasswordConfirm,
      accountPasswordOriginal: accountPasswordOriginal ?? this.accountPasswordOriginal,
      agreedTermIds: agreedTermIds ?? this.agreedTermIds,
      usedPoints: usedPoints ?? this.usedPoints,
      selectedCouponId: selectedCouponId ?? this.selectedCouponId,
      baseRate: baseRate ?? this.baseRate,
      pointBonusRate: pointBonusRate ?? this.pointBonusRate,
      couponBonusRate: couponBonusRate ?? this.couponBonusRate,
      applyRate: applyRate ?? this.applyRate,
      notificationSms: notificationSms ?? this.notificationSms,
      notificationEmail: notificationEmail ?? this.notificationEmail,
      notificationHp: notificationHp ?? this.notificationHp,
      notificationEmailAddr: notificationEmailAddr ?? this.notificationEmailAddr,
      finalAgree: finalAgree ?? this.finalAgree,
    );
  }

  // JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'productNo': productNo,
      'productName': productName,
      'productType': productType,
      'userId': userId,
      'principalAmount': principalAmount,
      'contractTerm': contractTerm,
      'startDate': startDate?.toIso8601String(),
      'expectedEndDate': expectedEndDate?.toIso8601String(),
      'branchId': branchId,
      'empId': empId,
      'accountPassword': accountPassword,
      'accountPasswordConfirm': accountPasswordConfirm,
      'accountPasswordOriginal': accountPasswordOriginal,
      'agreedTermIds': agreedTermIds,
      'usedPoints': usedPoints,
      'selectedCouponId': selectedCouponId,
      'baseRate': baseRate,
      'pointBonusRate': pointBonusRate,
      'couponBonusRate': couponBonusRate,
      'applyRate': applyRate,
      'notificationSms': notificationSms,
      'notificationEmail': notificationEmail,
      'notificationHp': notificationHp,
      'notificationEmailAddr': notificationEmailAddr,
      'finalAgree': finalAgree,
    };
  }

  factory ProductJoinRequest.fromJson(Map<String, dynamic> json) {
    return ProductJoinRequest(
      productNo: json['productNo'],
      productName: json['productName'] ?? '',
      productType: json['productType'],
      userId: json['userId'],
      principalAmount: json['principalAmount'],
      contractTerm: json['contractTerm'],
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      expectedEndDate: json['expectedEndDate'] != null ? DateTime.parse(json['expectedEndDate']) : null,
      branchId: json['branchId'],
      empId: json['empId'],
      accountPassword: json['accountPassword'],
      accountPasswordConfirm: json['accountPasswordConfirm'],
      accountPasswordOriginal: json['accountPasswordOriginal'],
      agreedTermIds: json['agreedTermIds'] != null ? List<int>.from(json['agreedTermIds']) : null,
      usedPoints: json['usedPoints'],
      selectedCouponId: json['selectedCouponId'],
      baseRate: json['baseRate']?.toDouble(),
      pointBonusRate: json['pointBonusRate']?.toDouble(),
      couponBonusRate: json['couponBonusRate']?.toDouble(),
      applyRate: json['applyRate']?.toDouble(),
      notificationSms: json['notificationSms'],
      notificationEmail: json['notificationEmail'],
      notificationHp: json['notificationHp'],
      notificationEmailAddr: json['notificationEmailAddr'],
      finalAgree: json['finalAgree'],
    );
  }
}