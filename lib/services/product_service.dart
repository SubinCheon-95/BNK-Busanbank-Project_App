import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/product.dart';
import '../models/product_join_request.dart';
import '../models/category.dart';

class ProductService {
  /// 기존 사용 방식 유지: ProductService(baseUrl)
  ProductService(this.baseUrl);

  /// 예) http://10.0.2.2:8080/busanbank
  final String baseUrl;

  /// 전체 상품 목록 조회: GET /busanbank/api/products
  Future<List<Product>> fetchProducts() async {
    // 최종 URL: http://10.0.2.2:8080/busanbank/api/products
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
    final uri = Uri.parse('$baseUrl/api/products/$productNo');
    print('[DEBUG] fetchProductDetail URL = $uri');

    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('상품 상세 조회 실패: ${res.statusCode} / ${res.body}');
    }

    final Map<String, dynamic> data = jsonDecode(res.body);
    return Product.fromJson(data);
  }

  /// 🔥 Flutter STEP4에서 사용하는 가입 API
  ///
  /// 최종 URL:
  ///   http://10.0.2.2:8080/busanbank/api/join/mock
  ///
  /// (baseUrl = http://10.0.2.2:8080/busanbank 이고
  ///  뒤에 /api/join/mock 을 붙이는 구조)
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
      throw Exception('상품 가입 실패: ${res.statusCode} / ${res.statusCode} / ${res.body}');
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

  /// ✅ 카테고리별 상품 조회
  Future<List<Product>> fetchProductsByCategory(int categoryId) async {
    final uri = Uri.parse('$baseUrl/products/by-category/$categoryId');
    print('[DEBUG] fetchProductsByCategory URL = $uri');

    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('카테고리별 상품 조회 실패: ${res.statusCode}');
    }

    final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
    return data.map((e) => Product.fromJson(e)).toList();
  }


}
