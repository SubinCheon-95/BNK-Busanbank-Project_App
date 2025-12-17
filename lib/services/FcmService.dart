import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../firebase_options.dart';
import 'fcm_background_handler.dart';

class FcmService { // 푸시 알림 서비스
  static final FlutterLocalNotificationsPlugin _local =
  FlutterLocalNotificationsPlugin();

  // 🔹 초기화 (main에서 1번 호출)
  static Future<void> init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    _initLocalNotification();
    _registerForeground();
    _registerBackground();

    await FirebaseMessaging.instance.subscribeToTopic('all');
  }

  // 🔹 포그라운드
  static void _registerForeground() {
    FirebaseMessaging.onMessage.listen((message) {
      _show(message);
    });
  }

  // 🔹 백그라운드
  static void _registerBackground() {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // 🔹 로컬 알림 표시
  static Future<void> _show(RemoteMessage message) async {
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
    );
  }

  // 🔹 로컬 알림 채널
  static void _initLocalNotification() {
    const init = AndroidInitializationSettings('@mipmap/ic_launcher');
    _local.initialize(const InitializationSettings(android: init));

    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.high,
    );

    _local
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
}
