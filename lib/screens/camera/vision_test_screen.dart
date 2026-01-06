import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:tkbank/services/camera_point_service.dart';

import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';

class VisionTestScreen extends StatefulWidget { //카메라, 갤러리 이미지를 이용해 일치시 포인트 획득 - 작성자: 윤종인
  const VisionTestScreen({super.key});

  @override
  State<VisionTestScreen> createState() => _VisionTestScreenState();
}

class _VisionTestScreenState extends State<VisionTestScreen> with SingleTickerProviderStateMixin {
  late CameraPointService cameraPointService;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool isPointRequested = false;
  bool isLoading = false;
  XFile? image;
  String result = "";

  @override
  void initState() {
    super.initState();
    cameraPointService = CameraPointService(baseUrl: '${AppConfig.baseUrl}/api');
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '로고 인증 이벤트',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          children: [
            // 헤더 그라데이션 영역
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue[700]!,
                    Colors.blue[500]!,
                  ],
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'BNK 금융그룹 로고를 촬영하고\n포인트를 받으세요!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 이미지 프리뷰 카드
                  if (image != null)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Card(
                        elevation: 8,
                        shadowColor: Colors.blue.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              Image.file(
                                File(image!.path),
                                width: double.infinity,
                                height: 300,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.greenAccent,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '이미지 선택됨',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.grey[100],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '이미지를 선택해주세요',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // 버튼 영역
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.camera_alt,
                          label: '카메라 촬영',
                          color: Colors.blue[600]!,
                          onPressed: () async {
                            final picker = ImagePicker();
                            final picked = await picker.pickImage(
                              source: ImageSource.camera,
                            );

                            if (picked != null) {
                              setState(() {
                                image = picked;
                                result = "";
                                isPointRequested = false;
                              });
                              _animationController.forward(from: 0.0);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.photo_library,
                          label: '갤러리',
                          color: Colors.purple[600]!,
                          onPressed: () async {
                            final picker = ImagePicker();
                            final picked = await picker.pickImage(
                              source: ImageSource.gallery,
                            );

                            if (picked != null) {
                              setState(() {
                                image = picked;
                                result = "";
                                isPointRequested = false;
                              });
                              _animationController.forward(from: 0.0);
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 인증 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: image == null || isLoading
                          ? null
                          : () async {
                        setState(() {
                          isLoading = true;
                        });
                        await textDetection(imagePath: image!.path);
                        setState(() {
                          isLoading = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        elevation: image == null ? 0 : 4,
                        shadowColor: Colors.green.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                          : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified, size: 24),
                          SizedBox(width: 8),
                          Text(
                            '로고 인증하기',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 결과 표시
                  if (result.isNotEmpty)
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: result.contains('🎉')
                          ? Colors.green[50]
                          : Colors.red[50],
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: result.contains('🎉')
                                    ? Colors.green[100]
                                    : Colors.red[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                result.contains('🎉')
                                    ? Icons.celebration
                                    : Icons.error_outline,
                                color: result.contains('🎉')
                                    ? Colors.green[700]
                                    : Colors.red[700],
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                result,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: result.contains('🎉')
                                      ? Colors.green[900]
                                      : Colors.red[900],
                                ),
                              ),
                            ),
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 3,
        shadowColor: color.withOpacity(0.4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 이미지 base64 인코딩
  Future<String> encodeImageToBase64(String imagePath) async {
    final file = File(imagePath);
    final Uint8List bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  /// 텍스트 추출
  Future<void> textDetection({required String imagePath}) async {
    try {
      log('textDetection 진입');

      final base64Image = await encodeImageToBase64(imagePath);
      log('base64 길이: ${base64Image.length}');

      final response = await http.post(
        Uri.parse(
          'https://vision.googleapis.com/v1/images:annotate'
              '?key=AIzaSyBldHAhTkWn9e1dEFQaxprGsdJXRHULdh4',
        ),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonEncode({
          "requests": [
            {
              "image": {"content": base64Image},
              "features": [
                {"type": "LOGO_DETECTION"},
                {"type": "WEB_DETECTION"},
                {"type": "TEXT_DETECTION"}
              ]
            }
          ]
        }),
      );

      final decoded = jsonDecode(response.body);

      final List logoAnnotations =
          decoded['responses']?[0]?['logoAnnotations'] ?? [];

      final List webEntities =
          decoded['responses']?[0]?['webDetection']?['webEntities'] ?? [];

      final List textAnnotations =
          decoded['responses']?[0]?['textAnnotations'] ?? [];

      final Set<String> keywords = {
        ...logoAnnotations
            .map((e) => e['description'].toString().toLowerCase()),
        ...webEntities
            .map((e) => e['description'].toString().toLowerCase()),
        ...textAnnotations
            .map((e) => e['description'].toString().toLowerCase()),
      };

      print('KEYWORDS: $keywords');

      const targetKeywords = ['bnk', '부산은행'];

      bool hasTarget = targetKeywords.any(
            (target) => keywords.any((k) => k.contains(target)),
      );

      if (hasTarget && !isPointRequested) {
        isPointRequested = true;
        await requestPoint();
      } else if (!hasTarget) {
        setState(() {
          result = '대상 이미지가 아닙니다';
        });
      }
    } catch (e, s) {
      log('OCR EXCEPTION', error: e, stackTrace: s);
      setState(() {
        result = '에러가 발생했습니다: $e';
      });
    }
  }

  Future<void> requestPoint() async {
    final authProvider = context.read<AuthProvider>();
    final userNo = authProvider.userNo;

    if (userNo == null) {
      throw Exception('로그인이 필요합니다');
    }

    final Map<String, dynamic> data =
    await cameraPointService.checkImage(userNo);

    final bool success = data['success'] == true;
    final String message = data['message'] ?? '';

    setState(() {
      result = success
          ? '🎉 포인트 ${data['point']}P 지급 완료!'
          : '❌ $message';
    });
  }
}