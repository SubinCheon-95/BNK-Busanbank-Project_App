/*
  날짜 : 2025/12/15
  내용 : users 모델 추가
  작성자 : 오서정
  수정 : 2025/12/23 - 닉네임/아바타 필드 추가 - 진원
  수정 : 2025/12/26 - 주소 필드 추가- 작성자: 오서정
*/
class Users{

  final String userNo;
  final String userName;
  final String userId;
  final String userPw;
  final String email;
  final String hp;
  String role;
  String? nickname;       // 닉네임 (선택)
  String? avatarImage;    // 아바타 이미지 경로 (선택)
  String? zip;
  String? addr1;
  String? addr2;

  Users({
    required this.userNo,
    required this.userName,
    required this.userId,
    required this.userPw,
    required this.email,
    required this.hp,
    this.role = 'USER',
    this.nickname,
    this.avatarImage,
    this.zip,
    this.addr1,
    this.addr2,
  });

  Map<String, dynamic> toJson(){
    return {
      "userNo": userNo,
      "userName": userName,
      "userId": userId,
      "userPw": userPw,
      "email": email,
      "hp": hp,
      "role": role,
      "nickname": nickname,
      "avatarImage": avatarImage,
      "zip": zip,
      "addr1": addr1,
      "addr2": addr2,
    };
  }

  // JSON에서 Users 객체 생성
  factory Users.fromJson(Map<String, dynamic> json) {
    return Users(
      userNo: json['userNo']?.toString() ?? '',
      userName: json['userName'] ?? '',
      userId: json['userId'] ?? '',
      userPw: json['userPw'] ?? '',
      email: json['email'] ?? '',
      hp: json['hp'] ?? '',
      role: json['role'] ?? 'USER',
      nickname: json['nickname'],
      avatarImage: json['avatarImage'],
      zip: json['zip'],
      addr1: json['addr1'],
      addr2: json['addr2'],
    );
  }

}