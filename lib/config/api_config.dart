import 'dart:io';

class ApiConfig {
  static const host = String.fromEnvironment(
    'API_HOST',
    defaultValue: '10.0.2.2', // 에뮬 기본
  );

  static String get baseUrl => 'http://$host:8080/busanbank';
  static String get wsBase  => 'ws://$host:8080/busanbank';
}

