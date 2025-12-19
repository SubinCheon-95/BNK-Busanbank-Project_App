import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tkbank/config/api_config.dart';

import '../../models/faq_models.dart';

class FaqApiService {
  String get base => ApiConfig.baseUrl;

  Future<List<FaqCategory>> fetchCategories() async {
    final uri = Uri.parse('$base/api/cs/faq/categories');
    final res = await http.get(uri).timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw Exception('카테고리 조회 실패: ${res.statusCode}');
    }

    final data = jsonDecode(res.body) as List<dynamic>;
    return data.map((e) => FaqCategory.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PageResponse<FaqItem>> fetchFaqList({
    String? cate,        // null or '' = 전체
    String? keyword,     // null or '' = 검색 없음
    String searchType = 'qa', // question/answer/qa
    required int page,   // 1부터
    required int size,   // 페이지 사이즈
  }) async {
    final offset = (page - 1) * size;

    final params = <String, String>{
      'offset': offset.toString(),
      'size': size.toString(),
    };

    if (cate != null && cate.trim().isNotEmpty) {
      params['cate'] = cate.trim();
    }
    if (keyword != null && keyword.trim().isNotEmpty) {
      params['keyword'] = keyword.trim();
      params['searchType'] = searchType;
    }

    final uri = Uri.parse('$base/api/cs/faq').replace(queryParameters: params);

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('FAQ 조회 실패: ${res.statusCode}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return PageResponse<FaqItem>.fromJson(json, (m) => FaqItem.fromJson(m));
  }
}
