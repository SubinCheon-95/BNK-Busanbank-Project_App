import 'package:flutter/material.dart';
import 'screens/product/product_main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// 📌 에뮬레이터에서 스프링부트 서버 접속용
  /// - 브라우저: http://localhost:8080/busanbank/api/products
  /// - 에뮬레이터: http://10.0.2.2:8080/busanbank/api/products
  static const String baseUrl = 'http://10.0.2.2:8080/busanbank/api';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TK 딸깍은행',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6A1B9A),
      ),
      home: const ProductMainScreen(baseUrl: baseUrl),
    );
  }
}


