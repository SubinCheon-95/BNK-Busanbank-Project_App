import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:permission_handler/permission_handler.dart';  // 2025-12-17 - 위치 권한 - 작성자: 진원
import '../../providers/auth_provider.dart';
import '../../services/flutter_api_service.dart';

// 2025-12-17 - 카카오맵 WebView 화면 (체크인 기능 포함) - 작성자: 진원
class BranchMapWebViewScreen extends StatefulWidget {
  final String baseUrl;

  const BranchMapWebViewScreen({super.key, required this.baseUrl});

  @override
  State<BranchMapWebViewScreen> createState() => _BranchMapWebViewScreenState();
}

class _BranchMapWebViewScreenState extends State<BranchMapWebViewScreen> {
  late final WebViewController controller;
  late final FlutterApiService _apiService;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _apiService = FlutterApiService(baseUrl: widget.baseUrl);
    _requestLocationPermission();  // 2025-12-17 - 위치 권한 요청 - 작성자: 진원

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(true)  // 2025-12-17 - 지도 줌 활성화 - 작성자: 진원
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
            });
          },
          onPageFinished: (String url) async {
            // 2025-12-17 - HTML 로드 완료 후 영업점 데이터 전달 - 작성자: 진원
            await _loadBranchesFromBackend();
            setState(() {
              isLoading = false;
            });
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _handleCheckin(message.message);
        },
      );

    _loadLocalHtml();
  }

  Future<void> _loadLocalHtml() async {
    final htmlContent = await rootBundle.loadString('assets/branch_map.html');
    controller.loadHtmlString(htmlContent);
  }

  // 2025-12-17 - 백엔드에서 영업점 데이터 가져와서 JavaScript로 전달 - 작성자: 진원
  Future<void> _loadBranchesFromBackend() async {
    try {
      final branches = await _apiService.getBranches();

      // JavaScript 배열 형식으로 변환
      final branchesJson = branches.map((branch) {
        return {
          'branchId': branch.branchId,
          'branchName': branch.branchName,
          'latitude': branch.latitude,
          'longitude': branch.longitude,
        };
      }).toList();

      // JavaScript로 영업점 데이터 전달
      final jsCode = 'loadBranchesFromFlutter(${jsonEncode(branchesJson)});';
      await controller.runJavaScript(jsCode);
      debugPrint('영업점 데이터 전달 완료: ${branches.length}개');
    } catch (e) {
      debugPrint('영업점 데이터 로드 실패: $e');
    }
  }

  // 2025-12-17 - 위치 권한 요청 - 작성자: 진원
  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      debugPrint('위치 권한 허용됨');
    } else if (status.isDenied) {
      debugPrint('위치 권한 거부됨');
    } else if (status.isPermanentlyDenied) {
      debugPrint('위치 권한 영구 거부됨 - 설정에서 변경 필요');
      openAppSettings();
    }
  }

  Future<void> _handleCheckin(String message) async {
    try {
      // 체크인 데이터 파싱
      final data = jsonDecode(message);
      final branchId = data['branchId'] as int;
      final branchName = data['branchName'] as String;
      final latitude = (data['latitude'] as num).toDouble();
      final longitude = (data['longitude'] as num).toDouble();

      // 로그인 확인
      final authProvider = context.read<AuthProvider>();
      final userNo = authProvider.userNo;

      if (userNo == null) {
        _sendResultToWebView(false, '로그인이 필요합니다', 0);
        return;
      }

      // 백엔드 API 호출
      final result = await _apiService.checkin(
        userId: userNo,
        branchId: branchId,
        latitude: latitude,
        longitude: longitude,
      );

      // 결과 전달
      if (result['success'] == true) {
        final points = result['earnedPoints'] ?? 100;
        _sendResultToWebView(true, '$branchName 체크인 완료!', points);
      } else {
        _sendResultToWebView(false, result['message'] ?? '체크인 실패', 0);
      }
    } catch (e) {
      debugPrint('체크인 오류: $e');
      _sendResultToWebView(false, '체크인 처리 중 오류가 발생했습니다', 0);
    }
  }

  void _sendResultToWebView(bool success, String message, int points) {
    controller.runJavaScript(
      'onCheckinResult($success, "$message", $points);',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('영업점 지도'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
