/*
  날짜 : 2025/12/15
  내용 : 로그인 페이지 추가
  작성자 : 오서정
*/
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:tkbank/providers/auth_provider.dart';
import 'package:tkbank/screens/member/terms_screen.dart';
import 'package:tkbank/services/member_service.dart';
import 'package:tkbank/services/token_storage_service.dart';

class LoginScreen extends StatefulWidget{
  const LoginScreen({super.key});

  @override
  State<StatefulWidget> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>{

  final _idController = TextEditingController();
  final _pwController = TextEditingController();

  final service = MemberService();
  final tokenStorageService = TokenStorageService();

  void _procLogin() async{
    final userId = _idController.text;
    final userPw = _pwController.text;

    if(userId.isEmpty || userPw.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('아이디, 비번 입력하세요.'))
      );
      return;
    }

    try {
      // 서비스 호출
      Map<String, dynamic> jsonData = await service.login(userId, userPw);
      String? accessToken = jsonData['accessToken'];
      log('accessToken : $accessToken');

      if(accessToken != null){
        // 토큰 저장(Provider로 저장)
        context.read<AuthProvider>().login(accessToken);


        // 로그인 화면 닫기
        Navigator.of(context).pop();
      }

    }catch(err){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('에러발생 : $err'))
      );
    }


  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로그인'),),
      body: Center(
        child: Padding(
            padding: EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _idController,
                decoration: InputDecoration(
                labelText: '아이디 입력',
                border: OutlineInputBorder()
              ),),
              const SizedBox(height: 10,),
              TextField(
                controller: _pwController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '비밀번호 입력',
                  border: OutlineInputBorder()
              ),),
              const SizedBox(height: 10,),
              SizedBox(
                width: double.infinity,
                height:50,
                child: ElevatedButton(
                    onPressed: _procLogin,
                    child: const Text('로그인', style: TextStyle(fontSize: 20, color: Colors.black),)
                ),
              ),
              const SizedBox(height: 10,),
              TextButton(
                onPressed: (){
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => TermsScreen()),
                  );
                },
                child: const Text('회원가입', style: TextStyle(color: Colors.black),)
              )


          ],
        ),
        ),
      ),
    );
  }

  
}