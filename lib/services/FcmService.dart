import 'dart:convert';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tkbank/screens/btc/Bitcoin_prediction_screen.dart';
import '../config/app_config.dart';
import '../firebase_options.dart';
import '../main.dart';
import '../navigator_key.dart';
import '../screens/btc/Bitcoin_fail_page.dart';
import '../screens/btc/Bitcoin_success_page.dart';
import '../screens/camera/vision_test_screen.dart';
import '../screens/game/game_menu_screen.dart';
import '../screens/my_page/my_products_screen.dart';
import '../screens/product/news_analysis_screen.dart';
import '../screens/product/product_main_screen.dart';
import 'bitcoin_service.dart';
import 'fcm_background_handler.dart';
import 'package:tkbank/screens/home/easy_home_screen.dart';

class FcmService { // 푸시 알림 서비스
  static final BitcoinService _bitcoinService = BitcoinService();

  static final FlutterLocalNotificationsPlugin _local =
  FlutterLocalNotificationsPlugin();

  // 🔹 초기화 (main에서 1번 호출)
  static Future<void> init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('알림 권한 상태: ${settings.authorizationStatus}');

    final token = await messaging.getToken();
    print('FCM Token: $token');

    _initLocalNotification();
    _registerForeground();
    _registerBackground();

    await FirebaseMessaging.instance.subscribeToTopic('all');

    final RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _handleBtcResultIfNeeded(initialMessage.data);
    }
  }

  // 🔹 포그라운드
  static void _registerForeground() {
    FirebaseMessaging.onMessage.listen((message) {
      if (message.notification == null) {
        _show(message);
      }
      else {
        _local.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          message.notification!.title,
          message.notification!.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel_v2',
              'High Importance Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          payload: message.data['route'],
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleBtcResultIfNeeded(message.data);
    });
  }

  static void _handleBtcResultIfNeeded(Map<String, dynamic> data) async {
    if (data['type'] == 'ADMIN_NOTIFICATION' && data.containsKey('success')) {
      final bool isSuccess = data['success'] == 'Y';
      final result = await _bitcoinService.fetchResult();

      if (isSuccess) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => BitcoinSuccessPage(
            yesterday: result.yesterday,
            today: result.today,)),
        );
      } else {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => BitcoinFailPage(
            yesterday: result.yesterday,
            today: result.today,)),
        );
      }
    }
  }


  // 🔹 백그라운드
  static void _registerBackground() {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // 🔹 로컬 알림 표시
  static Future<void> _show(RemoteMessage message) async {
    final String payloadData = jsonEncode(message.data);

    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.data['title'] ?? '알림',
      message.data['content'] ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel_v2',
          'High Importance Notifications',
          icon: 'ic_notification',
          color: Color(0xFF582499),
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: payloadData,
    );
  }

  // 🔹 로컬 알림 채널
  static void _initLocalNotification() {
    const init = AndroidInitializationSettings('@mipmap/ic_launcher');
    _local.initialize(const InitializationSettings(android: init),
      onDidReceiveNotificationResponse:(response) { //추가사항
        final String? payload = response.payload;

        if (payload == null || payload.isEmpty) return;

        try {
          // JSON 문자열을 다시 Map<String, dynamic>으로 변환
          final Map<String, dynamic> data = jsonDecode(payload);
          _handleNotificationClick(data);
        } catch (e) {
          print("Payload parse error: $e");
        }
    });

    const channel = AndroidNotificationChannel(
      'high_importance_channel_v2',
      'High Importance Notifications',
      importance: Importance.high,
    );

    _local
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static void _handleNotificationClick(Map<String, dynamic> data) {
    String route = data['route'] ?? '';
    print('route 값 확인 = $route');

    int yesterday = int.tryParse(data['yesterday'] ?? '0') ?? 0;
    int today = int.tryParse(data['today'] ?? '0') ?? 0;

    switch(route) {
        case '/product' :
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const ProductMainScreen(baseUrl: '${AppConfig.baseUrl}/api')),
        ); // 지금 가입하면 혜택있는 상품이 있어요 - 고객님께 적합한 상품을 확인해 보세요.
        break;

      case '/ai' :
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const NewsAnalysisMainScreen(baseUrl: '${AppConfig.baseUrl}/api')),
        ); // 오늘의 금융 알림 - AI가 분석한 최신 금리 동향을 확인해보세요
        break;

      case '/event':
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const GameMenuScreen(baseUrl: '${AppConfig.baseUrl}/api')),
        ); // 포인트를 모아 금리 혜택을 받아보세요 - 게임 이벤트로 포인트를 적립할 수 있어요
        break;

      case '/camera':
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const VisionTestScreen()),
        ); // 오늘의 미션 도착 - 주변 은행 로고를 촬영하고 포인트를 받아보세요
        break;

      case '/btc':
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const BitcoinPredictionScreen()),
        ); // 오늘의 비트코인 방향 예측 - 어제보다 올랐을까요, 내렸을까요? 지금 선택해보세요
        break;

      case '/success':
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => BitcoinSuccessPage(yesterday: yesterday, today: today)),
        );
        break;

      case '/fail':
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => BitcoinFailPage(yesterday: yesterday, today: today)),
        );
        break;

      case '/myProduct':
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => MyProductsScreen()),
        );
        break;

      default:
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const EasyHomeScreen(baseUrl: '${AppConfig.baseUrl}/api')),
        );
    }
  }
}