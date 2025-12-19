// 2025/12/19 - 뉴스 분석 API 엔드포인트 추가 - 작성자: 진원
class AppConfig {

  static const String baseUrl = "http://10.0.2.2:8080/busanbank";

  // 뉴스 분석 API 엔드포인트
  static const String apiNewsAnalysis = "$baseUrl/api/news";

}