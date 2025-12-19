// 2025/12/18 - 포인트 모델 - 작성자: 진원
class Point {
  final int userNo;
  final int totalPoints;
  final int availablePoints;
  final int usedPoints;

  Point({
    required this.userNo,
    required this.totalPoints,
    required this.availablePoints,
    required this.usedPoints,
  });

  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(
      userNo: json['userNo'] ?? 0,
      totalPoints: json['totalPoints'] ?? 0,
      availablePoints: json['availablePoints'] ?? 0,
      usedPoints: json['usedPoints'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userNo': userNo,
      'totalPoints': totalPoints,
      'availablePoints': availablePoints,
      'usedPoints': usedPoints,
    };
  }
}
