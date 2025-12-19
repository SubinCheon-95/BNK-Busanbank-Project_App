import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/flutter_api_service.dart';
import '../../models/news_analysis_result.dart';
import 'news_result_screen.dart';

class NewsAnalysisMainScreen extends StatefulWidget {
  final String baseUrl;

  const NewsAnalysisMainScreen({
    super.key,
    required this.baseUrl,
  });

  @override
  State<NewsAnalysisMainScreen> createState() => _NewsAnalysisMainScreenState();
}

class _NewsAnalysisMainScreenState extends State<NewsAnalysisMainScreen> {
  final TextEditingController _urlController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  late FlutterApiService _apiService;

  File? _selectedImage;
  bool _analyzing = false;

  @override
  void initState() {
    super.initState();
    _apiService = FlutterApiService(baseUrl: widget.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  /// URL 기반 분석
  Future<void> _analyzeUrl() async {
    final url = _urlController.text.trim();

    if (url.isEmpty) {
      _showError('URL을 입력해주세요.');
      return;
    }

    if (!url.startsWith('http')) {
      _showError('올바른 URL을 입력해주세요. (http:// 또는 https://)');
      return;
    }

    setState(() => _analyzing = true);

    try {
      final result = await _apiService.analyzeNewsUrl(url);

      setState(() => _analyzing = false);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NewsResultScreen(
            baseUrl: widget.baseUrl,
            result: result,
          ),
        ),
      );
    } catch (e) {
      setState(() => _analyzing = false);
      _showError('분석 실패: $e');
    }
  }

  /// 이미지 선택
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showError('이미지 선택 실패: $e');
    }
  }

  /// 이미지 기반 분석
  Future<void> _analyzeImage() async {
    if (_selectedImage == null) {
      _showError('이미지를 선택해주세요.');
      return;
    }

    setState(() => _analyzing = true);

    try {
      final result = await _apiService.analyzeNewsImage(_selectedImage!);

      setState(() => _analyzing = false);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NewsResultScreen(
            baseUrl: widget.baseUrl,
            result: result,
          ),
        ),
      );
    } catch (e) {
      setState(() => _analyzing = false);
      _showError('분석 실패: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 뉴스 분석'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🎨 헤더 (웹 버전 그대로!)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '기사/콘텐츠 분석 (AI)',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'URL을 입력하고 "AI 분석" 버튼을 누르면',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '기사 요약 / 키워드 / 감성 / 추천 상품을 제공합니다',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // 📝 URL 입력 섹션
                  Card(
                    elevation: 8,
                    shadowColor: Colors.blue.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blue[400]!, Colors.blue[600]!],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.link,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                'URL로 분석하기',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _urlController,
                            decoration: InputDecoration(
                              hintText: '뉴스 기사 URL을 입력하세요',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                              ),
                              prefixIcon: const Icon(Icons.web, color: Colors.blue),
                              contentPadding: const EdgeInsets.all(20),
                            ),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton.icon(
                              onPressed: _analyzing ? null : _analyzeUrl,
                              icon: _analyzing
                                  ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : const Icon(Icons.analytics, size: 28),
                              label: Text(
                                _analyzing ? '분석 중...' : 'AI 분석',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 구분선
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300], thickness: 2)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          '또는',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300], thickness: 2)),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // 📷 이미지 업로드 섹션
                  Card(
                    elevation: 8,
                    shadowColor: Colors.purple.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.purple[400]!, Colors.purple[600]!],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.image,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                '이미지로 분석하기',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // 이미지 선택 버튼
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _pickImage(ImageSource.camera),
                                  icon: const Icon(Icons.camera_alt, size: 24),
                                  label: const Text(
                                    '카메라',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.all(20),
                                    side: BorderSide(
                                      color: Colors.purple[300]!,
                                      width: 2,
                                    ),
                                    foregroundColor: Colors.purple,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _pickImage(ImageSource.gallery),
                                  icon: const Icon(Icons.photo_library, size: 24),
                                  label: const Text(
                                    '갤러리',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.all(20),
                                    side: BorderSide(
                                      color: Colors.purple[300]!,
                                      width: 2,
                                    ),
                                    foregroundColor: Colors.purple,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (_selectedImage != null) ...[
                            const SizedBox(height: 24),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                _selectedImage!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton.icon(
                                onPressed: _analyzing ? null : _analyzeImage,
                                icon: _analyzing
                                    ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                    : const Icon(Icons.analytics, size: 28),
                                label: Text(
                                  _analyzing ? '분석 중...' : 'AI 분석',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}