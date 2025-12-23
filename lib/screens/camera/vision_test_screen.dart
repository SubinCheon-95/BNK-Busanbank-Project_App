import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:tkbank/services/camera_point_service.dart';

import '../../providers/auth_provider.dart';

class VisionTestScreen extends StatefulWidget { //카메라, 갤러리 이미지를 이용해 일치시 포인트 획득 - 작성자: 윤종인
  final String baseUrl = 'http://10.0.2.2:8080/busanbank/api';
  const VisionTestScreen({super.key});

  @override
  State<VisionTestScreen> createState() => _VisionTestScreenState();
}

class _VisionTestScreenState extends State<VisionTestScreen> {
  late CameraPointService cameraPointService;

  bool isPointRequested = false;
  XFile? image;
  String result = "";

  @override
  void initState() {
    super.initState();
    cameraPointService = CameraPointService(baseUrl: widget.baseUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR 테스트 (Google Vision)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (image != null)
              Image.file(File(image!.path), height: 250),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('카메라 촬영'),
              onPressed: () async {
                final picker = ImagePicker();
                final picked = await picker.pickImage(source: ImageSource.camera);

                if(picked != null) {
                  setState(() {
                    image = picked;
                    result = "";
                    isPointRequested = false;
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () async {
                final picker = ImagePicker();
                final picked =
                await picker.pickImage(source: ImageSource.gallery);

                if (picked != null) {
                  setState(() {
                    image = picked;
                    result = "";
                    isPointRequested = false;
                  });
                }
              },
              child: const Text('이미지 선택'),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: image == null
                  ? null
                  : () async {
                await textDetection(imagePath: image!.path);
              },
              child: const Text('텍스트 추출'),
            ),

            const SizedBox(height: 24),

            if (result.isNotEmpty)
              Text(
                result,
                style: const TextStyle(fontSize: 16),
              ),
          ],
        ),
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
                {"type": "LOGO_DETECTION"}, // {"type": "LABEL_DETECTION"},
                {"type": "WEB_DETECTION"},
                {"type": "TEXT_DETECTION"}
              ]
            }
          ]
        }),
      );

      //전체 json 확인용
      //debugPrint('responseBody입니다: ${response.body}');

      //기본 세팅 @@@@@@@@@@@@@@@@
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


      //기본 세팅 @@@@@@@@@@@@@@@@
      const targetKeywords = [
        'bnk',
        '부산은행'
      ];

      bool hasTarget = targetKeywords.any(
            (target) => keywords.any((k) => k.contains(target)),
      );


      if (hasTarget && !isPointRequested) {
        isPointRequested = true;

        await requestPoint();
      } else if (!hasTarget) {
        setState(() {
          result = '❌ 대상 이미지 아님';
        });
      }


    } catch (e, s) {
      log('OCR EXCEPTION', error: e, stackTrace: s);
      setState(() {
        result = '에러: $e';
      });
    }
  }

  Future<void> requestPoint() async {
    final authProvider = context.read<AuthProvider>();
    final userNo = authProvider.userNo;

    if (userNo == null) {
      throw Exception('로그인이 필요합니다');
    }

    final Map<String, dynamic> data = await cameraPointService.checkImage(userNo);

    final bool success = data['success'] == true;
    final String message = data['message'] ?? '';

    setState(() {
      result = success
          ? '🎉 포인트 ${data['point']} 지급 완료'
          : '❌ $message';
    });
  }
}