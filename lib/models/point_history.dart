// 2025/12/16 - 포인트 이력 모델 - 작성자: 진원
class PointHistory {
  final int pointId;
  final int userNo;
  final int pointAmount;
  final String pointType; // 'EARN' or 'USE'
  final String description;
  final DateTime createdAt;

  PointHistory({
    required this.pointId,
    required this.userNo,
    required this.pointAmount,
    required this.pointType,
    required this.description,
    required this.createdAt,
  });

  factory PointHistory.fromJson(Map<String, dynamic> json) {
    return PointHistory(
      pointId: json['pointId'] ?? 0,
      userNo: json['userNo'] ?? 0,
      pointAmount: json['pointAmount'] ?? 0,
      pointType: json['pointType'] ?? 'EARN',
      description: json['description'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pointId': pointId,
      'userNo': userNo,
      'pointAmount': pointAmount,
      'pointType': pointType,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
