class Validators {
  /// 아이디 (영문 소문자 시작, 영문+숫자 5~20자)
  static bool isValidUserId(String userId) {
    return RegExp(r'^[a-z]+[a-z0-9]{4,19}$').hasMatch(userId);
  }

  /// 비밀번호 (영문+숫자+특수문자 포함 5~16자)
  static bool isValidPassword(String password) {
    return RegExp(
      r'^(?=.*[a-zA-Z])(?=.*[0-9])(?=.*[$`~!@$!%*#^?&()\-_=+]).{5,16}$',
    ).hasMatch(password);
  }

  /// 이름 (한글 2~10자)
  static bool isValidName(String name) {
    return RegExp(r'^[가-힣]{2,10}$').hasMatch(name);
  }

  /// 이메일
  static bool isValidEmail(String email) {
    return RegExp(
      r'^[0-9a-zA-Z]([-_.]?[0-9a-zA-Z])*@[0-9a-zA-Z]([-_.]?[0-9a-zA-Z])*\.[a-zA-Z]{2,3}$',
    ).hasMatch(email);
  }

  /// 휴대폰 번호 (010-1234-5678)
  static bool isValidHp(String hp) {
    return RegExp(r'^01(?:0|1|[6-9])-\d{4}-\d{4}$').hasMatch(hp);
  }

  /// 계좌 비밀번호 (숫자 4자리)
  static bool isValidAccountPassword(String pw) {
    return RegExp(r'^\d{4}$').hasMatch(pw);
  }

  /// 주민등록번호 (기존 JS 알고리즘 그대로)
  static bool isValidJumin(String front, String back) {
    if (!RegExp(r'^\d{6}$').hasMatch(front)) return false;
    if (!RegExp(r'^\d{7}$').hasMatch(back)) return false;

    final nums = (front + back).split('').map(int.parse).toList();
    final multipliers = [2, 3, 4, 5, 6, 7, 8, 9, 2, 3, 4, 5];

    int sum = 0;
    for (int i = 0; i < 12; i++) {
      sum += nums[i] * multipliers[i];
    }

    final check = (11 - (sum % 11)) % 10;
    return check == nums[12];
  }
}
