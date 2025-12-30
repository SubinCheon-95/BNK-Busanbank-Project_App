import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../firebase_options.dart';

final FlutterLocalNotificationsPlugin _local =
FlutterLocalNotificationsPlugin(); //푸시 알림 핸들러

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final FlutterLocalNotificationsPlugin local =
  FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  await local.initialize(
    const InitializationSettings(android: initSettings),
  );

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel_v2',
    'High Importance Notifications',
    importance: Importance.high,
  );

  await local
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await local.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    message.notification?.title ?? message.data['title'] ?? '알림',
    message.notification?.body ?? message.data['content'] ?? '',
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