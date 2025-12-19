import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../services/news_service.dart';
import '../../../models/news_analysis_result.dart';
import 'news_result_screen.dart';

class NewsAnalysisScreen extends StatefulWidget {
  const NewsAnalysisScreen({super.key});

  @override
  State<NewsAnalysisScreen> createState() => _NewsAnalysisScreenState();
}

class _NewsAnalysisScreenState extends State<NewsAnalysisScreen> {
  final _urlController = TextEditingController();
  final _newsService = NewsService();
  final _imagePicker = ImagePicker();

  bool _isAnalyzing = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  // URL 분석
  Future<void> _analyzeUrl() async {
    final url = _urlController.text.trim();

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL을 입력하세요')),
      );
      return;
    }

    if (!_isValidUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 URL 형식이 아닙니다')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = await _newsService.analyzeUrl(url);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewsResultScreen(result: result),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('분석 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  // 이미지 분석 (카메라)
  Future<void> _analyzeImageFromCamera() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (image != null) {
      await _processImage(File(image.path));
    }
  }

  // 이미지 분석 (갤러리)
  Future<void> _analyzeImageFromGallery() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      await _processImage(File(image.path));
    }
  }

  // 이미지 처리 및 분석
  Future<void> _processImage(File imageFile) async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = await _newsService.analyzeImage(imageFile);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewsResultScreen(result: result),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 분석 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  bool _isValidUrl(String url) {
    return Uri.tryParse(url)?.hasAbsolutePath ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('뉴스 분석'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 타이틀
                const Text(
                  'AI 뉴스 분석',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '뉴스 URL 또는 이미지를 분석하여\n맞춤 금융상품을 추천해드립니다.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 32),

                // URL 입력 섹션
                _buildUrlSection(),

                const SizedBox(height: 32),

                // 구분선
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 32),

                // 이미지 업로드 섹션
                _buildImageSection(),

                const SizedBox(height: 32),

                // 기능 설명
                _buildFeatureCards(),
              ],
            ),
          ),

          // 로딩 오버레이
          if (_isAnalyzing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          '뉴스 분석 중...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'AI가 기사를 분석하고 있습니다',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUrlSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.link,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'URL로 분석',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                hintText: 'https://news.naver.com/...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.web),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _analyzeUrl,
              icon: const Icon(Icons.search),
              label: const Text('분석 시작'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.image,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  '이미지로 분석',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '기사 스크린샷이나 신문 사진을 업로드하세요',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isAnalyzing ? null : _analyzeImageFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('카메라'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isAnalyzing ? null : _analyzeImageFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('갤러리'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '분석 기능',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          icon: Icons.summarize,
          title: '요약',
          description: '기사의 핵심 내용을 4-7문장으로 요약',
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: Icons.key,
          title: '키워드 추출',
          description: 'TF-IDF 알고리즘으로 중요 키워드 추출',
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: Icons.sentiment_satisfied,
          title: '감정 분석',
          description: '긍정/부정/중립 감정 분석 및 점수',
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: Icons.recommend,
          title: '상품 추천',
          description: '기사 내용과 가장 관련 있는 금융상품 추천',
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}