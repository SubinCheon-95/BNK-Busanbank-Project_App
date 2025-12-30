// 2025/12/29 - 거래내역 모델 클래스 - 작성자: 진원
class Transaction {
  final int transactionId;
  final String fromAccountNo;
  final String toAccountNo;
  final int amount;
  final int balanceAfter;
  final String transactionType;
  final String transactionDate;
  final String? description;
  final int userId;

  Transaction({
    required this.transactionId,
    required this.fromAccountNo,
    required this.toAccountNo,
    required this.amount,
    required this.balanceAfter,
    required this.transactionType,
    required this.transactionDate,
    this.description,
    required this.userId,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      transactionId: json['transactionId'] ?? 0,
      fromAccountNo: json['fromAccountNo'] ?? '',
      toAccountNo: json['toAccountNo'] ?? '',
      amount: json['amount'] ?? 0,
      balanceAfter: json['balanceAfter'] ?? 0,
      transactionType: json['transactionType'] ?? 'TRANSFER',
      transactionDate: json['transactionDate'] ?? '',
      description: json['description'],
      userId: json['userId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'fromAccountNo': fromAccountNo,
      'toAccountNo': toAccountNo,
      'amount': amount,
      'balanceAfter': balanceAfter,
      'transactionType': transactionType,
      'transactionDate': transactionDate,
      'description': description,
      'userId': userId,
    };
  }

  // 입금/출금 여부 판단 헬퍼 메서드
  bool isDeposit(String myAccountNo) {
    return toAccountNo == myAccountNo;
  }

  bool isWithdrawal(String myAccountNo) {
    return fromAccountNo == myAccountNo;
  }
}
