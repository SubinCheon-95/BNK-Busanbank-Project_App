import 'package:flutter/material.dart';
import 'dart:io';
import '../../models/news_analysis_result.dart';
import '../../services/news_service.dart';

class NewsProvider with ChangeNotifier {
  final NewsService _newsService = NewsService();

  NewsAnalysisResult? _currentResult;
  List<NewsAnalysisResult> _history = [];

  bool _isAnalyzing = false;
  String? _errorMessage;

  // Getters
  NewsAnalysisResult? get currentResult => _currentResult;
  List<NewsAnalysisResult> get history => _history;
  bool get isAnalyzing => _isAnalyzing;
  String? get errorMessage => _errorMessage;

  // URL 분석
  Future<void> analyzeUrl(String url) async {
    _isAnalyzing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentResult = await _newsService.analyzeUrl(url);
      _addToHistory(_currentResult!);

      _isAnalyzing = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'URL 분석 실패: $e';
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  // 이미지 분석
  Future<void> analyzeImage(File imageFile) async {
    _isAnalyzing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentResult = await _newsService.analyzeImage(imageFile);
      _addToHistory(_currentResult!);

      _isAnalyzing = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = '이미지 분석 실패: $e';
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  // 히스토리 추가
  void _addToHistory(NewsAnalysisResult result) {
    _history.insert(0, result);  // 최신이 앞으로

    // 최대 10개까지만 유지
    if (_history.length > 10) {
      _history = _history.take(10).toList();
    }
  }

  // 현재 결과 초기화
  void clearCurrentResult() {
    _currentResult = null;
    notifyListeners();
  }

  // 히스토리 초기화
  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  // 에러 메시지 초기화
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _newsService.dispose();
    super.dispose();
  }
}