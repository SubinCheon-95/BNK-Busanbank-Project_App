// lib/model/branch.dart

class Branch {
  final int branchId;
  final String branchName;
  final String? branchAddr;
  final String? branchTel;

  Branch({
    required this.branchId,
    required this.branchName,
    this.branchAddr,
    this.branchTel,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      branchId: json['branchId'] ?? 0,
      branchName: json['branchName'] ?? '',
      branchAddr: json['branchAddr'],
      branchTel: json['branchTel'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'branchId': branchId,
      'branchName': branchName,
      'branchAddr': branchAddr,
      'branchTel': branchTel,
    };
  }
}