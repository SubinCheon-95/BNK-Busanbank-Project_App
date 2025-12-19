import 'package:dio/dio.dart';
import 'dart:io';
import '../../models/news_analysis_result.dart';
import '../../config/app_config.dart';
import 'api_service.dart';
import 'ocr_service.dart';

class NewsService {
  final ApiService _api = ApiService();
  final OcrService _ocrService = OcrService();

  // URL 기반 뉴스 분석
  Future<NewsAnalysisResult> analyzeUrl(String url) async {
    try {
      print('🌐 뉴스 URL 분석 시작: $url');

      final response = await _api.post(
        '${AppConfig.apiNewsAnalysis}/url',
        data: {'url': url},
      );

      if (response.statusCode == 200) {
        print('✅ 뉴스 분석 성공');
        return NewsAnalysisResult.fromJson(response.data);
      }

      throw Exception('뉴스 분석 실패: ${response.statusCode}');
    } catch (e) {
      print('❌ analyzeUrl error: $e');
      rethrow;
    }
  }

  // 이미지 기반 뉴스 분석 (OCR)
  Future<NewsAnalysisResult> analyzeImage(File imageFile) async {
    try {
      print('📸 이미지 OCR 분석 시작');

      // 1. OCR로 텍스트 추출
      print('  1️⃣ 텍스트 추출 중...');
      final extractedText = await _ocrService.extractText(imageFile);

      if (extractedText.isEmpty) {
        throw Exception('이미지에서 텍스트를 찾을 수 없습니다');
      }

      print('  ✅ 텍스트 추출 완료 (${extractedText.length}자)');

      // 2. 서버로 분석 요청 (이미지 파일 전송)
      print('  2️⃣ 서버 분석 요청 중...');

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'news_image.jpg',
        ),
      });

      final response = await _api.postMultipart(
        '${AppConfig.apiNewsAnalysis}/image',
        formData,
      );

      if (response.statusCode == 200) {
        print('✅ 이미지 분석 성공');
        return NewsAnalysisResult.fromJson(response.data);
      }

      throw Exception('이미지 분석 실패: ${response.statusCode}');
    } catch (e) {
      print('❌ analyzeImage error: $e');
      rethrow;
    }
  }

  // 리소스 해제
  void dispose() {
    _ocrService.dispose();
  }
}