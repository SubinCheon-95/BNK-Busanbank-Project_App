// 2025/12/19 - API 서비스 클래스 생성 - 작성자: 진원
import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio;

  ApiService() : _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
  ));

  // POST 요청
  Future<Response> post(String url, {dynamic data}) async {
    try {
      return await _dio.post(url, data: data);
    } catch (e) {
      print('❌ API POST error: $e');
      rethrow;
    }
  }

  // Multipart POST 요청 (파일 업로드)
  Future<Response> postMultipart(String url, FormData formData) async {
    try {
      return await _dio.post(
        url,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
    } catch (e) {
      print('❌ API Multipart POST error: $e');
      rethrow;
    }
  }

  // GET 요청
  Future<Response> get(String url) async {
    try {
      return await _dio.get(url);
    } catch (e) {
      print('❌ API GET error: $e');
      rethrow;
    }
  }
}
