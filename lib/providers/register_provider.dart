/*
  날짜: 2025/12/26
  내용: 회원가입 주소 입력 추가
  작성자: 오서정
  수정: 2025/12/26 - 주소 추가 - 오서정
 */
import 'package:flutter/material.dart';
import 'package:tkbank/services/member_service.dart';

class RegisterProvider with ChangeNotifier {
  final MemberService _memberService = MemberService();

  // STEP 2
  String? hp;
  String? userName;

  // STEP 3
  String? rrn;
  String? zip;
  String? addr1;
  String? addr2;

  // STEP 4
  String? userId;
  String? userPw;
  String? accountPassword;
  String? email;

  /* =======================
     🔥 휴대폰 인증 로직
     ======================= */

  Future<String> sendHpCode({required String hp}) async {
    return await _memberService.sendHpCode(hp);
  }

  Future<bool> verifyHpCode({
    required String hp,
    required String code,
  }) async {
    return await _memberService.verifyHpCode(
      hp: hp,
      code: code,
    );
  }


  /// 📌 인증 성공 시 저장
  void setPhoneInfo({
    required String hp,
    required String userName,
  }) {
    this.hp = hp;
    this.userName = userName;
    notifyListeners();
  }

  /* =======================
     이후 회원정보 단계
     ======================= */

  void setUserInfo({
    required String rrn,
    String? zip,
    String? addr1,
    String? addr2,
  }) {
    this.rrn = rrn;
    this.zip = zip;
    this.addr1 = addr1;
    this.addr2 = addr2;
    notifyListeners();
  }

  void setAccountInfo({
    required String userId,
    required String userPw,
    required String accountPassword,
    String? email,
  }) {
    this.userId = userId;
    this.userPw = userPw;
    this.accountPassword = accountPassword;
    this.email = email;
    notifyListeners();
  }

  /// 📌 최종 회원가입 JSON
  Map<String, dynamic> toJson() {
    return {
      "userId": userId,
      "userPw": userPw,
      "userName": userName,
      "hp": hp,
      "rrn": rrn,
      "zip": zip,
      "addr1": addr1,
      "addr2": addr2,
      "accountPassword": accountPassword,
      "email": email,
    };
  }

  void clear() {
    hp = null;
    userName = null;
    rrn = null;
    zip = null;
    addr1 = null;
    addr2 = null;
    userId = null;
    userPw = null;
    accountPassword = null;
    email = null;
  }
}
