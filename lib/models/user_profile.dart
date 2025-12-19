// 2025/12/18 - 사용자 프로필 모델 - 작성자: 진원
class UserProfile {
  final int userNo;
  final String userId;
  final String? userName;
  final String? email;
  final String? hp;
  final String? zip;
  final String? addr1;
  final String? addr2;
  final String? lastConnectTime;
  final int? totalPoints;
  final int? countUserItems;

  UserProfile({
    required this.userNo,
    required this.userId,
    this.userName,
    this.email,
    this.hp,
    this.zip,
    this.addr1,
    this.addr2,
    this.lastConnectTime,
    this.totalPoints,
    this.countUserItems,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userNo: json['userNo'] ?? 0,
      userId: json['userId'] ?? '',
      userName: json['userName'],
      email: json['email'],
      hp: json['hp'],
      zip: json['zip'],
      addr1: json['addr1'],
      addr2: json['addr2'],
      lastConnectTime: json['lastConnectTime'] ?? json['connectTime'],
      totalPoints: json['totalPoints'] ?? json['remainPoints'],
      countUserItems: json['countUserItems'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userNo': userNo,
      'userId': userId,
      'userName': userName,
      'email': email,
      'hp': hp,
      'zip': zip,
      'addr1': addr1,
      'addr2': addr2,
      'lastConnectTime': lastConnectTime,
      'totalPoints': totalPoints,
      'countUserItems': countUserItems,
    };
  }
}
