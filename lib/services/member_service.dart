/*
  날짜 : 2025/12/15
  내용 : 회원 관련 기능 서비스 추가
  작성자 : 오서정
*/
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:tkbank/models/term.dart';
import 'package:tkbank/models/users.dart';
import 'package:tkbank/providers/register_provider.dart';


class MemberService{

  final String baseUrl = "http://10.0.2.2:8080/busanbank";

  Future<Map<String, dynamic>> login(String userId, String userPw) async {

    try {
      final response = await http.post(
          Uri.parse('$baseUrl/api/member/login'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "userId": userId,
            "userPw": userPw
          })
      );

      if(response.statusCode == 200){
         return jsonDecode(response.body);
      }else{
        throw Exception(response.statusCode);
      }

    }catch(err){
      throw Exception('예외발생 : $err');
    }
  }

  Future<List<Term>> fetchTerms() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/member/terms'),
      );

      print('statusCode = ${response.statusCode}');
      print('body = ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print('decoded runtimeType = ${decoded.runtimeType}');

        final List list = decoded;
        return list.map((e) => Term.fromJson(e)).toList();
      } else {
        throw Exception('약관 조회 실패: ${response.statusCode}');
      }
    } catch (err) {
      print('fetchTerms error = $err');
      throw Exception('약관 조회 예외 발생: $err');
    }
  }

  Future<void> register(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/member/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (res.statusCode != 200) {
      throw Exception('회원가입 실패');
    }
  }


  /// 1️⃣ 인증번호 발송
  Future<String> sendHpCode(String hp) async {
    final res = await http.post(
      Uri.parse('$baseUrl/member/hp/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'hp': hp,
        'mode': 'app',
      }),
    );

    if (res.statusCode == 200) {
      return utf8.decode(res.bodyBytes); // ✅ "인증 코드 발송 완료"
    } else {
      throw Exception(utf8.decode(res.bodyBytes)); // ✅ 서버 메시지 그대로
    }
  }

  /// 2️⃣ 인증번호 검증
  Future<bool> verifyHpCode({
    required String hp,
    required String code,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/member/hp/code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'hp': hp,
        'code': code,
        'mode': 'app',
      }),
    );

    final data = jsonDecode(res.body);
    return data['isMatched'] == true;
  }

  /// 🔹 중복 검사 (userId / email / hp)
  Future<bool> isDuplicated({
    required String type,
    required String value,
  }) async {
    final res = await http.get(
      Uri.parse('$baseUrl/member/$type/$value'),
    );

    if (res.statusCode != 200) {
      throw Exception('중복 검사 실패');
    }

    final data = jsonDecode(res.body);
    return data['count'] > 0;
  }


}

