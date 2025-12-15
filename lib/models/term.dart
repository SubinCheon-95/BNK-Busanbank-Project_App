/*
  날짜 : 2025/12/15
  내용 : term 모델 추가
  작성자 : 오서정
*/
class Term{

  final int termNo;
  final String termType;
  final String termTitle;
  final String termContent;

  Term({
    required this.termNo,
    required this.termType,
    required this.termTitle,
    required this.termContent,
  });

  factory Term.fromJson(Map<String, dynamic> json) {
    return Term(
      termNo: json['termNo'],
      termType: json['termType'],
      termTitle: json['termTitle'],
      termContent: json['termContent'],
    );
  }

  Map<String, dynamic> toJson(){
    return {
      "termNo": termNo,
      "termType": termType,
      "termTitle": termTitle,
      "termContent": termContent,
    };
  }

}