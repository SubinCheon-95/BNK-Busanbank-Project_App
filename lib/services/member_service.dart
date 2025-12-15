/*
  날짜 : 2025/12/15
  내용 : 회원 관련 기능 서비스 추가
  작성자 : 오서정
*/
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tkbank/models/term.dart';
import 'package:tkbank/models/users.dart';


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

  Future<Map<String, dynamic>> register(Users user) async {

     try {
       final response = await http.post(
           Uri.parse('$baseUrl/api/member/register'),
           headers: {"Content-Type": "application/json"},
           body: jsonEncode(user.toJson())
       );

       if(response.statusCode == 200){
         // savedUser 반환
         return jsonDecode(response.body);
       }else{
         throw Exception('statusCode : ${response.statusCode}');
       }
     }catch(err){
       throw Exception('에러발생 : $err');
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


}