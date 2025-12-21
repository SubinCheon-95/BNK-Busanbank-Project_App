class SimpleLoginResult {
  final String accessToken;
  final String refreshToken;
  final int userNo;
  final String userId;
  final String userName;
  final String role;

  SimpleLoginResult({
    required this.accessToken,
    required this.refreshToken,
    required this.userNo,
    required this.userId,
    required this.userName,
    required this.role,
  });

  factory SimpleLoginResult.fromJson(Map<String, dynamic> json) {
    return SimpleLoginResult(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      userNo: json['userNo'],
      userId: json['userId'],
      userName: json['userName'] ?? '',
      role: json['role'] ?? 'USER',
    );
  }
}
