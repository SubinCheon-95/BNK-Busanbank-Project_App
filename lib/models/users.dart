/*
  날짜 : 2025/12/15
  내용 : users 모델 추가
  작성자 : 오서정
*/
class Users{

  final String userNo;
  final String userName;
  final String userId;
  final String userPw;
  final String email;
  final String hp;
  String role;

  Users({
    required this.userNo,
    required this.userName,
    required this.userId,
    required this.userPw,
    required this.email,
    required this.hp,
    this.role = 'USER'
  });

  Map<String, dynamic> toJson(){
    return {
      "userNo": userNo,
      "userName": userName,
      "userId": userId,
      "userPw": userPw,
      "email": email,
      "hp": hp,
      "role": role
    };
  }

}