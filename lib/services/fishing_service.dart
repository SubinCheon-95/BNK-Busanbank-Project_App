// 2025/12/20 - ESG 낚시 게임 서비스 - 작성자: 진원

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../models/trash.dart';

class FishingService {
  // 랜덤 쓰레기 가져오기
  Future<Trash> getRandomTrash() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/flutter/fishing/random-trash'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return Trash.fromJson(data);
      } else {
        throw Exception('쓰레기 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('쓰레기 조회 실패: $e');
    }
  }

  // 낚시 결과 제출 및 포인트 적립
  Future<Map<String, dynamic>> submitFishingResult({
    required String userId,
    required String trashType,
    required int points,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/flutter/fishing/submit'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'trashType': trashType,
          'points': points,
          'catchTime': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('낚시 결과 제출 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('낚시 결과 제출 실패: $e');
    }
  }

  // 오늘의 낚시 통계 조회
  Future<Map<String, dynamic>> getTodayStats(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/flutter/fishing/stats/$userId'),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('통계 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('통계 조회 실패: $e');
    }
  }

  // 쓰레기 목록 가져오기 (로컬 데이터)
  List<Trash> getTrashList() {
    return [
      Trash(
        id: '1',
        name: '플라스틱 병',
        type: 'plastic',
        points: 10,
        emoji: '🍾',
        description: '플라스틱 병을 수거했어요!',
      ),
      Trash(
        id: '2',
        name: '캔',
        type: 'can',
        points: 15,
        emoji: '🥫',
        description: '금속 캔을 수거했어요!',
      ),
      Trash(
        id: '3',
        name: '비닐봉지',
        type: 'bag',
        points: 20,
        emoji: '🛍️',
        description: '비닐봉지를 수거했어요!',
      ),
      Trash(
        id: '4',
        name: '유리병',
        type: 'bottle',
        points: 25,
        emoji: '🍶',
        description: '유리병을 수거했어요!',
      ),
      Trash(
        id: '5',
        name: '폐타이어',
        type: 'tire',
        points: 50,
        emoji: '🛞',
        description: '대형 쓰레기 폐타이어를 수거했어요!',
      ),
      Trash(
        id: '6',
        name: '어망',
        type: 'net',
        points: 100,
        emoji: '🎣',
        description: '희귀 쓰레기 어망을 수거했어요!',
      ),
    ];
  }
}
