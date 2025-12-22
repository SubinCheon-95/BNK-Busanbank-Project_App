import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/product.dart';
import '../models/product_join_request.dart';
import '../models/category.dart';

class ProductService {
  /// 기존 사용 방식 유지: ProductService(baseUrl)
  ProductService(this.baseUrl);

  /// 예) http://10.0.2.2:8080/busanbank/api
  final String baseUrl;

  /// 전체 상품 목록 조회: GET /busanbank/api/products
  Future<List<Product>> fetchProducts() async {
    final uri = Uri.parse('$baseUrl/products');
    print('[DEBUG] fetchProducts URL = $uri');

    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('상품 목록 조회 실패: ${res.statusCode} / ${res.body}');
    }

    final List<dynamic> data = jsonDecode(res.body);
    return data
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// (필요 시) 상품 상세 조회: GET /busanbank/api/products/{productNo}
  Future<Product> fetchProductDetail(int productNo) async {
    final uri = Uri.parse('$baseUrl/products/$productNo');
    print('[DEBUG] fetchProductDetail URL = $uri');

    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('상품 상세 조회 실패: ${res.statusCode} / ${res.body}');
    }

    final Map<String, dynamic> data = jsonDecode(res.body);
    return Product.fromJson(data);
  }

  /// 🔥 Flutter STEP4에서 사용하는 가입 API
  Future<void> joinProduct(ProductJoinRequest request) async {
    final uri = Uri.parse('$baseUrl/flutter/join/mock');

    print('[DEBUG] joinProduct URL = $uri');
    print('[DEBUG] joinProduct body = ${jsonEncode(request.toJson())}');

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(request.toJson()),
    );

    print('[DEBUG] joinProduct status = ${res.statusCode}');
    print('[DEBUG] joinProduct response = ${res.body}');

    if (res.statusCode != 200) {
      throw Exception('상품 가입 실패: ${res.statusCode} / ${res.body}');
    }
  }

  /// ✅ 카테고리 목록 조회
  Future<List<Category>> fetchCategories() async {
    final uri = Uri.parse('$baseUrl/categories');
    print('[DEBUG] fetchCategories URL = $uri');

    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('카테고리 조회 실패: ${res.statusCode}');
    }

    final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
    return data.map((e) => Category.fromJson(e)).toList();
  }

  /// ✅ 카테고리별 상품 조회 (categoryCode → categoryId 변환!)
  Future<List<Product>> fetchProductsByCategory(String categoryCode) async {
    try {
      print('📦 카테고리별 상품 조회: $categoryCode');

      // ✅ 1. categoryCode를 categoryId로 변환
      final categoryId = _getCategoryId(categoryCode);

      if (categoryId == null) {
        print('⚠️ 알 수 없는 카테고리: $categoryCode');
        return [];
      }

      // ✅ 2. Backend API 호출 (숫자로!)
      final uri = Uri.parse('$baseUrl/flutter/products/by-category/$categoryId');
      print('📦 요청 URL: $uri');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      print('📦 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(utf8.decode(response.bodyBytes));
        final products = jsonList.map((json) => Product.fromJson(json)).toList();

        print('✅ 상품 조회 성공: ${products.length}개');
        return products;
      } else {
        print('❌ 응답 본문: ${response.body}');
        throw Exception('상품 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 상품 조회 에러: $e');
      throw Exception('상품 조회 실패: $e');
    }
  }

  /// ✅ categoryCode → categoryId 변환 (핵심!)
  int? _getCategoryId(String categoryCode) {
    // 카테고리 코드 → ID 매핑
    final Map<String, int> categoryMap = {
      'freedepwith': 3,    // 입출금자유
      'lumpsum': 5,        // 목돈만들기
      'lumprolling': 6,    // 목돈굴리기
      'housing': 7,        // 주택마련
      'smartfinance': 8,   // 스마트금융전용
      //'future': 6,         // 미래테크는 뉴스AI로 연결임
      'three': 9,          // 자산전문예금
    };

    return categoryMap[categoryCode];
  }
}