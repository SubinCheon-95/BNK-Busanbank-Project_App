// lib/model/branch.dart
// 2025-12-17 - 위도/경도 필드 추가 - 작성자: 진원

class Branch {
  final int branchId;
  final String branchName;
  final String? branchAddr;
  final String? branchTel;
  final double? latitude;   // 위도
  final double? longitude;  // 경도

  Branch({
    required this.branchId,
    required this.branchName,
    this.branchAddr,
    this.branchTel,
    this.latitude,
    this.longitude,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      branchId: json['branchId'] ?? 0,
      branchName: json['branchName'] ?? '',
      branchAddr: json['address'] ?? json['branchAddr'], // 백엔드는 'address' 사용
      branchTel: json['tel'] ?? json['branchTel'], // 백엔드는 'tel' 사용
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'branchId': branchId,
      'branchName': branchName,
      'address': branchAddr,
      'tel': branchTel,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}